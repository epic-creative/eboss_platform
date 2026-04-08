defmodule EBossFolio.RevisionEvent do
  use Ash.Resource,
    otp_app: :eboss_folio,
    domain: EBossFolio,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  require Ash.Query

  postgres do
    table("folio_revision_events")
    repo(EBoss.Repo)
  end

  actions do
    read :read do
      primary?(true)
    end

    read :list do
      argument(:workspace_id, :uuid, allow_nil?: false)
      argument(:resource_type, :atom, allow_nil?: true)
      argument(:resource_id, :uuid, allow_nil?: true)
      argument(:correlation_id, :uuid, allow_nil?: true)

      pagination(offset?: true, countable: true, required?: false)

      prepare(fn query, _context ->
        workspace_id_value = Ash.Query.get_argument(query, :workspace_id)
        resource_type_value = Ash.Query.get_argument(query, :resource_type)
        resource_id_value = Ash.Query.get_argument(query, :resource_id)
        correlation_id_value = Ash.Query.get_argument(query, :correlation_id)

        query
        |> Ash.Query.filter(workspace_id == ^workspace_id_value)
        |> maybe_filter_resource_type(resource_type_value)
        |> maybe_filter_resource_id(resource_id_value)
        |> maybe_filter_correlation_id(correlation_id_value)
        |> Ash.Query.sort(occurred_at: :desc)
      end)
    end

    create :record do
      accept([
        :workspace_id,
        :resource_type,
        :resource_id,
        :action,
        :actor_type,
        :actor_id,
        :source,
        :occurred_at,
        :before,
        :after,
        :diff,
        :correlation_id,
        :reason
      ])
    end
  end

  policies do
    policy action_type(:read) do
      authorize_if(expr(workspace.owner_type == :user and workspace.owner_id == ^actor(:id)))
      authorize_if(relates_to_actor_via([:workspace, :organization, :owner]))
    end

    policy action_type(:create) do
      forbid_if(always())
    end
  end

  attributes do
    uuid_primary_key(:id)

    attribute :resource_type, :atom do
      allow_nil?(false)
      public?(true)
      constraints(one_of: [:task, :project, :area, :horizon, :context, :contact, :delegation])
    end

    attribute :resource_id, :uuid do
      allow_nil?(false)
      public?(true)
    end

    attribute :action, :atom do
      allow_nil?(false)
      public?(true)

      constraints(
        one_of: [
          :create,
          :update,
          :delete,
          :transition,
          :attach,
          :detach,
          :expand,
          :import,
          :policy_apply
        ]
      )
    end

    attribute :actor_type, :atom do
      allow_nil?(false)
      public?(true)
      constraints(one_of: [:user, :telegram_bot, :api_key, :cli, :agent, :system])
    end

    attribute :actor_id, :uuid do
      allow_nil?(true)
      public?(true)
    end

    attribute :source, :atom do
      allow_nil?(false)
      public?(true)

      constraints(
        one_of: [:internal, :liveview, :rest_api, :telegram, :cli, :policy_engine, :migration]
      )
    end

    attribute :occurred_at, :utc_datetime_usec do
      allow_nil?(false)
      public?(true)
      default(&DateTime.utc_now/0)
    end

    attribute :before, :map do
      allow_nil?(true)
      public?(true)
    end

    attribute :after, :map do
      allow_nil?(true)
      public?(true)
    end

    attribute :diff, :map do
      allow_nil?(true)
      public?(true)
    end

    attribute :correlation_id, :uuid do
      allow_nil?(true)
      public?(true)
    end

    attribute :reason, :string do
      allow_nil?(true)
      public?(true)
    end

    create_timestamp(:inserted_at)
  end

  relationships do
    belongs_to :workspace, EBoss.Workspaces.Workspace do
      allow_nil?(false)
      public?(true)
    end

    belongs_to :actor, EBoss.Accounts.User do
      source_attribute(:actor_id)
      allow_nil?(true)
      public?(true)
      attribute_writable?(false)
      define_attribute?(false)
    end
  end

  defp maybe_filter_resource_type(query, nil), do: query

  defp maybe_filter_resource_type(query, value),
    do: Ash.Query.filter(query, resource_type == ^value)

  defp maybe_filter_resource_id(query, nil), do: query
  defp maybe_filter_resource_id(query, value), do: Ash.Query.filter(query, resource_id == ^value)

  defp maybe_filter_correlation_id(query, nil), do: query

  defp maybe_filter_correlation_id(query, value) do
    Ash.Query.filter(query, correlation_id == ^value)
  end
end
