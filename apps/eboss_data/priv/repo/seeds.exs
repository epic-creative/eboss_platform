# Script for populating the database with deterministic local demo data.
#
# Run this from the umbrella root so all domain apps are available:
#
#     mix run apps/eboss_data/priv/repo/seeds.exs
#     mix seed
#
# Optional:
#
#     EBOSS_SEED_PASSWORD=supersecret123 mix seed

unless Code.ensure_loaded?(EBoss.Accounts) and Code.ensure_loaded?(EBoss.Workspaces) and
         Code.ensure_loaded?(EBoss.Folio) do
  Mix.raise("""
  Run seeds from the umbrella root so all domain apps are available.

      cd /Users/mhostetler/Source/EBoss/eboss_platform
      mix seed
  """)
end

defmodule EBoss.Seeds do
  @moduledoc false

  require Ash.Query

  alias EBoss.Accounts
  alias EBoss.Accounts.User
  alias EBoss.Folio
  alias EBoss.Organizations
  alias EBoss.Organizations.{Membership, Organization}
  alias EBoss.Workspaces
  alias EBoss.Workspaces.{Workspace, WorkspaceMembership}
  alias EBossFolio.{Area, Contact, Context, Delegation, Horizon, Project, Task}

  @default_password "supersecret123"
  @seed_reason "seed demo data"

  def run do
    password = System.get_env("EBOSS_SEED_PASSWORD") || @default_password
    correlation_id = Ecto.UUID.generate()

    Mix.shell().info("Seeding EBoss demo data...")

    admin =
      ensure_user!(%{
        email: "admin@local.eboss.ai",
        username: "operator",
        password: password,
        password_confirmation: password,
        role: :admin
      })

    mike =
      ensure_user!(%{
        email: "mike@local.eboss.ai",
        username: "mike",
        password: password,
        password_confirmation: password,
        role: :user
      })

    alex =
      ensure_user!(%{
        email: "alex@local.eboss.ai",
        username: "alex",
        password: password,
        password_confirmation: password,
        role: :user
      })

    org =
      ensure_organization!(mike, %{
        name: "EBoss Labs",
        description: "The umbrella organization for the platform, staging, and client work.",
        settings: %{"timezone" => "America/Chicago", "seeded" => true}
      })

    ensure_org_membership!(mike, org, admin, :admin)
    ensure_org_membership!(mike, org, alex, :member)

    personal_workspace =
      ensure_workspace!(mike, %{
        name: "Personal HQ",
        description: "Mike's public sandbox for local auth, API, and Folio experiments.",
        owner_type: :user,
        owner_id: mike.id,
        visibility: :public,
        settings: %{"seeded" => true, "theme" => "field-notes"}
      })

    team_workspace =
      ensure_workspace!(mike, %{
        name: "Platform Command",
        description: "Private organization workspace for the EBoss core team.",
        owner_type: :organization,
        owner_id: org.id,
        visibility: :private,
        settings: %{"seeded" => true, "release_channel" => "beta"}
      })

    ensure_workspace_membership!(mike, personal_workspace, alex, :admin)

    seed_personal_folio!(mike, personal_workspace, correlation_id)
    seed_team_folio!(mike, team_workspace, correlation_id)

    Mix.shell().info("")
    Mix.shell().info("Seed complete.")
    Mix.shell().info("Demo users:")
    Mix.shell().info("  admin@local.eboss.ai / #{password} (username: operator)")
    Mix.shell().info("  mike@local.eboss.ai / #{password}")
    Mix.shell().info("  alex@local.eboss.ai / #{password}")
    Mix.shell().info("")
    Mix.shell().info("Seeded workspaces:")
    Mix.shell().info("  #{workspace_path(personal_workspace)}")
    Mix.shell().info("  #{workspace_path(team_workspace)}")
    Mix.shell().info("")

    Mix.shell().info(
      "Reruns are idempotent for the seeded graph. Existing users keep their current passwords."
    )
  end

  defp ensure_user!(attrs) do
    email = attrs.email
    username = String.downcase(attrs.username)
    role = attrs.role

    user =
      case lookup_one(User, [email: email], EBoss.Accounts) do
        nil ->
          Accounts.register_with_password!(
            Map.take(attrs, [:email, :username, :password, :password_confirmation]),
            authorize?: false
          )

        existing_user ->
          existing_user
          |> maybe_update_user_identity!(email, username)
      end

    maybe_update_user_role!(user, role)
  end

  defp maybe_update_user_identity!(user, email, username) do
    attrs =
      %{}
      |> maybe_put(:email, to_string(user.email), email)
      |> maybe_put(:username, user.username, username)

    if map_size(attrs) == 0 do
      user
    else
      Accounts.admin_update_user!(user, attrs, authorize?: false)
    end
  end

  defp maybe_update_user_role!(user, role) when user.role == role, do: user

  defp maybe_update_user_role!(user, role) do
    user
    |> Ash.Changeset.for_update(:update, %{role: role})
    |> Ash.update!(domain: EBoss.Accounts, authorize?: false)
  end

  defp ensure_organization!(owner, attrs) do
    slug = Slug.slugify(attrs.name)

    case lookup_one(Organization, [slug: slug], EBoss.Organizations) do
      nil ->
        Organizations.create_organization!(attrs, actor: owner)

      organization ->
        maybe_update_record!(organization, Map.put(attrs, :owner_id, owner.id), fn changes ->
          Organizations.admin_update_organization!(organization, changes, authorize?: false)
        end)
    end
  end

  defp ensure_org_membership!(actor, organization, user, role) do
    case lookup_one(
           Membership,
           [organization_id: organization.id, user_id: user.id],
           EBoss.Organizations
         ) do
      nil ->
        Membership
        |> Ash.Changeset.for_create(
          :create,
          %{organization_id: organization.id, user_id: user.id, role: role},
          actor: actor
        )
        |> Ash.create!(domain: EBoss.Organizations)

      membership when membership.role == role ->
        membership

      membership ->
        membership
        |> Ash.Changeset.for_update(:update_role, %{role: role}, actor: actor)
        |> Ash.update!(domain: EBoss.Organizations)
    end
  end

  defp ensure_workspace!(actor, attrs) do
    slug = Slug.slugify(attrs.name)
    settings = Map.get(attrs, :settings, %{})

    case lookup_one(
           Workspace,
           [owner_type: attrs.owner_type, owner_id: attrs.owner_id, slug: slug],
           EBoss.Workspaces
         ) do
      nil ->
        workspace =
          Workspaces.create_workspace!(
            Map.take(attrs, [:name, :description, :owner_type, :owner_id, :visibility]),
            actor: actor
          )

        maybe_update_workspace!(
          workspace,
          %{description: attrs.description, settings: settings},
          actor
        )

      workspace ->
        maybe_update_workspace!(
          workspace,
          %{description: attrs.description, settings: settings},
          actor
        )
    end
  end

  defp ensure_workspace_membership!(actor, workspace, user, role) do
    case lookup_one(
           WorkspaceMembership,
           [workspace_id: workspace.id, user_id: user.id],
           EBoss.Workspaces
         ) do
      nil ->
        Workspaces.create_workspace_membership!(
          %{workspace_id: workspace.id, user_id: user.id, role: role},
          actor: actor
        )

      membership when membership.role == role ->
        membership

      membership ->
        membership
        |> Ash.Changeset.for_update(:update, %{role: role}, actor: actor)
        |> Ash.update!(domain: EBoss.Workspaces)
    end
  end

  defp seed_personal_folio!(actor, workspace, correlation_id) do
    opts = folio_opts(actor, correlation_id)

    area =
      ensure_folio_record!(
        Area,
        [workspace_id: workspace.id, name: "Platform Stewardship"],
        fn nil ->
          Folio.create_area!(
            %{
              workspace_id: workspace.id,
              name: "Platform Stewardship",
              description: "Keep the product stable, readable, and pleasant to evolve.",
              review_interval_days: 7
            },
            opts
          )
        end,
        fn existing ->
          maybe_update_record!(
            existing,
            %{
              description: "Keep the product stable, readable, and pleasant to evolve.",
              review_interval_days: 7
            },
            fn changes -> Folio.update_area!(existing, changes, opts) end
          )
        end
      )

    context =
      ensure_folio_record!(
        Context,
        [workspace_id: workspace.id, name: "Deep Work"],
        fn nil ->
          Folio.create_context!(
            %{
              workspace_id: workspace.id,
              name: "Deep Work",
              description: "Long-form architecture, docs, and implementation sessions."
            },
            opts
          )
        end,
        fn existing ->
          maybe_update_record!(
            existing,
            %{description: "Long-form architecture, docs, and implementation sessions."},
            fn changes -> Folio.update_context!(existing, changes, opts) end
          )
        end
      )

    horizon =
      ensure_folio_record!(
        Horizon,
        [workspace_id: workspace.id, name: "Q2 2026 Outcomes"],
        fn nil ->
          Folio.create_horizon!(
            %{
              workspace_id: workspace.id,
              name: "Q2 2026 Outcomes",
              level: 2,
              description: "Quarterly outcomes for tightening product foundations."
            },
            opts
          )
        end,
        fn existing ->
          maybe_update_record!(
            existing,
            %{level: 2, description: "Quarterly outcomes for tightening product foundations."},
            fn changes -> Folio.update_horizon!(existing, changes, opts) end
          )
        end
      )

    contact =
      ensure_folio_record!(
        Contact,
        [workspace_id: workspace.id, email: "jordan@example.com"],
        fn nil ->
          Folio.create_contact!(
            %{
              workspace_id: workspace.id,
              name: "Jordan Example",
              email: "jordan@example.com",
              capability_notes: "Reviews API ergonomics and external integration design."
            },
            opts
          )
        end,
        fn existing ->
          maybe_update_record!(
            existing,
            %{
              name: "Jordan Example",
              capability_notes: "Reviews API ergonomics and external integration design."
            },
            fn changes -> Folio.update_contact!(existing, changes, opts) end
          )
        end
      )

    project =
      ensure_folio_record!(
        Project,
        [workspace_id: workspace.id, title: "Ship workspace API tracer bullet"],
        fn nil ->
          Folio.create_project!(
            %{
              workspace_id: workspace.id,
              title: "Ship workspace API tracer bullet",
              description: "Prove auth, routing, OpenAPI, and external HTTP tests end to end.",
              notes: "Use this project as the seed scenario for API integration work.",
              priority_position: 10,
              area_id: area.id,
              horizon_id: horizon.id,
              context_id: context.id
            },
            opts
          )
        end,
        fn existing ->
          maybe_update_record!(
            existing,
            %{
              description: "Prove auth, routing, OpenAPI, and external HTTP tests end to end.",
              notes: "Use this project as the seed scenario for API integration work.",
              area_id: area.id,
              horizon_id: horizon.id,
              context_id: context.id
            },
            fn changes -> Folio.update_project_details!(existing, changes, opts) end
          )
        end
      )

    ensure_folio_record!(
      Task,
      [workspace_id: workspace.id, title: "Document owner-handle workspace routes"],
      fn nil ->
        Folio.create_task!(
          %{
            workspace_id: workspace.id,
            title: "Document owner-handle workspace routes",
            description: "Write curl examples for user and org workspace endpoints.",
            status: :next_action,
            estimated_minutes: 45,
            complexity_score: 2.0,
            priority_position: 10,
            notes: "Keep examples aligned with /api/v1 and the OpenAPI contract.",
            project_id: project.id,
            area_id: area.id,
            horizon_id: horizon.id,
            context_id: context.id
          },
          opts
        )
      end,
      fn existing ->
        maybe_update_record!(
          existing,
          %{
            description: "Write curl examples for user and org workspace endpoints.",
            estimated_minutes: 45,
            complexity_score: 2.0,
            notes: "Keep examples aligned with /api/v1 and the OpenAPI contract.",
            project_id: project.id,
            area_id: area.id,
            horizon_id: horizon.id,
            context_id: context.id
          },
          fn changes -> Folio.update_task_details!(existing, changes, opts) end
        )
      end
    )

    waiting_task =
      ensure_folio_record!(
        Task,
        [workspace_id: workspace.id, title: "Confirm API examples with Jordan"],
        fn nil ->
          Folio.create_task!(
            %{
              workspace_id: workspace.id,
              title: "Confirm API examples with Jordan",
              description: "Get an external read on naming and error semantics.",
              status: :waiting_for,
              estimated_minutes: 20,
              complexity_score: 1.0,
              priority_position: 20,
              notes: "Waiting on review feedback before polishing the public examples.",
              project_id: project.id,
              area_id: area.id,
              horizon_id: horizon.id,
              context_id: context.id
            },
            opts
          )
        end,
        fn existing ->
          maybe_update_record!(
            existing,
            %{
              description: "Get an external read on naming and error semantics.",
              estimated_minutes: 20,
              complexity_score: 1.0,
              notes: "Waiting on review feedback before polishing the public examples.",
              project_id: project.id,
              area_id: area.id,
              horizon_id: horizon.id,
              context_id: context.id
            },
            fn changes -> Folio.update_task_details!(existing, changes, opts) end
          )
        end
      )

    ensure_folio_delegation!(workspace, waiting_task, contact, opts)
  end

  defp seed_team_folio!(actor, workspace, correlation_id) do
    opts = folio_opts(actor, correlation_id)

    area =
      ensure_folio_record!(
        Area,
        [workspace_id: workspace.id, name: "Platform Delivery"],
        fn nil ->
          Folio.create_area!(
            %{
              workspace_id: workspace.id,
              name: "Platform Delivery",
              description: "Keep the shared product surface moving toward beta.",
              review_interval_days: 14
            },
            opts
          )
        end,
        fn existing ->
          maybe_update_record!(
            existing,
            %{
              description: "Keep the shared product surface moving toward beta.",
              review_interval_days: 14
            },
            fn changes -> Folio.update_area!(existing, changes, opts) end
          )
        end
      )

    context =
      ensure_folio_record!(
        Context,
        [workspace_id: workspace.id, name: "Planning"],
        fn nil ->
          Folio.create_context!(
            %{
              workspace_id: workspace.id,
              name: "Planning",
              description: "Roadmapping, release readiness, and team coordination."
            },
            opts
          )
        end,
        fn existing ->
          maybe_update_record!(
            existing,
            %{description: "Roadmapping, release readiness, and team coordination."},
            fn changes -> Folio.update_context!(existing, changes, opts) end
          )
        end
      )

    horizon =
      ensure_folio_record!(
        Horizon,
        [workspace_id: workspace.id, name: "2026 Beta Launch"],
        fn nil ->
          Folio.create_horizon!(
            %{
              workspace_id: workspace.id,
              name: "2026 Beta Launch",
              level: 3,
              description: "Yearly launch horizon for the first public beta."
            },
            opts
          )
        end,
        fn existing ->
          maybe_update_record!(
            existing,
            %{level: 3, description: "Yearly launch horizon for the first public beta."},
            fn changes -> Folio.update_horizon!(existing, changes, opts) end
          )
        end
      )

    project =
      ensure_folio_record!(
        Project,
        [workspace_id: workspace.id, title: "Launch custom authentication UX"],
        fn nil ->
          Folio.create_project!(
            %{
              workspace_id: workspace.id,
              title: "Launch custom authentication UX",
              description:
                "Replace starter auth views with product-grade LiveView + LiveVue pages.",
              status: :active,
              notes: "The dashboard should become the first authenticated shell.",
              priority_position: 5,
              area_id: area.id,
              horizon_id: horizon.id,
              context_id: context.id
            },
            opts
          )
        end,
        fn existing ->
          maybe_update_record!(
            existing,
            %{
              description:
                "Replace starter auth views with product-grade LiveView + LiveVue pages.",
              notes: "The dashboard should become the first authenticated shell.",
              area_id: area.id,
              horizon_id: horizon.id,
              context_id: context.id
            },
            fn changes -> Folio.update_project_details!(existing, changes, opts) end
          )
        end
      )

    ensure_folio_record!(
      Task,
      [workspace_id: workspace.id, title: "Polish dashboard launchpad copy"],
      fn nil ->
        Folio.create_task!(
          %{
            workspace_id: workspace.id,
            title: "Polish dashboard launchpad copy",
            description:
              "Tighten the authenticated landing page before exposing more app modules.",
            status: :next_action,
            estimated_minutes: 30,
            complexity_score: 1.0,
            priority_position: 5,
            notes: "Keep the tone sharp and product-facing.",
            project_id: project.id,
            area_id: area.id,
            horizon_id: horizon.id,
            context_id: context.id
          },
          opts
        )
      end,
      fn existing ->
        maybe_update_record!(
          existing,
          %{
            description:
              "Tighten the authenticated landing page before exposing more app modules.",
            estimated_minutes: 30,
            complexity_score: 1.0,
            notes: "Keep the tone sharp and product-facing.",
            project_id: project.id,
            area_id: area.id,
            horizon_id: horizon.id,
            context_id: context.id
          },
          fn changes -> Folio.update_task_details!(existing, changes, opts) end
        )
      end
    )
  end

  defp ensure_folio_delegation!(workspace, task, contact, opts) do
    ensure_folio_record!(
      Delegation,
      [workspace_id: workspace.id, task_id: task.id, contact_id: contact.id, status: :active],
      fn nil ->
        Folio.delegate_task!(
          %{
            workspace_id: workspace.id,
            task_id: task.id,
            contact_id: contact.id,
            delegated_summary: "Review the public API examples for clarity and omissions.",
            quality_expectations:
              "Call out confusing route naming, missing examples, and weak error copy.",
            deadline_expectations_at: DateTime.add(DateTime.utc_now(), 3 * 24 * 60 * 60, :second),
            follow_up_at: DateTime.add(DateTime.utc_now(), 2 * 24 * 60 * 60, :second)
          },
          opts
        )
      end,
      fn existing -> existing end
    )
  end

  defp ensure_folio_record!(resource, filter, create_fun, update_fun) do
    case lookup_one(resource, filter, EBossFolio) do
      nil -> create_fun.(nil)
      existing -> update_fun.(existing)
    end
  end

  defp lookup_one(resource, filter, domain) do
    resource
    |> Ash.Query.for_read(:read, %{})
    |> Ash.Query.build(filter: filter)
    |> Ash.read_one!(domain: domain, authorize?: false)
  end

  defp maybe_put(attrs, _key, current_value, new_value) when current_value == new_value, do: attrs
  defp maybe_put(attrs, key, _current_value, new_value), do: Map.put(attrs, key, new_value)

  defp folio_opts(actor, correlation_id) do
    [
      actor: actor,
      context: %{
        private: %{
          folio_audit: %{
            source: :internal,
            correlation_id: correlation_id,
            reason: @seed_reason
          }
        }
      }
    ]
  end

  defp workspace_path(%{owner_type: :user, owner_handle: owner_handle, slug: slug}) do
    "@#{owner_handle}/#{slug}"
  end

  defp workspace_path(%{owner_type: :organization, owner_handle: owner_handle, slug: slug}) do
    "#{owner_handle}/#{slug}"
  end

  defp maybe_update_workspace!(workspace, attrs, actor) do
    maybe_update_record!(workspace, attrs, fn changes ->
      Workspaces.update_workspace!(workspace, changes, actor: actor)
    end)
  end

  defp maybe_update_record!(record, attrs, updater) do
    update_attrs = changed_attrs(record, attrs)

    if map_size(update_attrs) == 0 do
      record
    else
      updater.(update_attrs)
    end
  end

  defp changed_attrs(record, attrs) do
    Enum.reduce(attrs, %{}, fn {key, value}, acc ->
      if comparable_value(Map.get(record, key)) == comparable_value(value) do
        acc
      else
        Map.put(acc, key, value)
      end
    end)
  end

  defp comparable_value(%Ash.CiString{} = value), do: to_string(value)
  defp comparable_value(value), do: value
end

EBoss.Seeds.run()
