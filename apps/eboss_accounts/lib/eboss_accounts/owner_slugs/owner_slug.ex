defmodule EBoss.OwnerSlugs.OwnerSlug do
  use Ash.Resource,
    otp_app: :eboss_accounts,
    domain: EBoss.OwnerSlugs,
    data_layer: AshPostgres.DataLayer

  require Ash.Query

  postgres do
    table("owner_slugs")
    repo(EBoss.Repo)
  end

  code_interface do
    define(:reserve_owner_slug, action: :reserve, args: [:slug, :owner_type, :owner_id])

    define(:get_owner_slug_by_slug,
      action: :by_slug,
      args: [:slug],
      get?: true,
      not_found_error?: false
    )

    define(:get_owner_slug_by_owner,
      action: :by_owner,
      args: [:owner_type, :owner_id],
      get?: true,
      not_found_error?: false
    )
  end

  actions do
    defaults([:read])

    create :reserve do
      accept([])

      argument :slug, :string do
        allow_nil?(false)
      end

      argument :owner_type, :atom do
        allow_nil?(false)
        constraints(one_of: [:user, :organization])
      end

      argument :owner_id, :uuid do
        allow_nil?(false)
      end

      change(set_attribute(:slug, arg(:slug)))
      change(set_attribute(:owner_type, arg(:owner_type)))
      change(set_attribute(:owner_id, arg(:owner_id)))
      validate(EBoss.OwnerSlugs.OwnerSlug.Validations.ValidateSlug)
    end

    read :by_slug do
      argument :slug, :string do
        allow_nil?(false)
      end

      prepare(fn query, _context ->
        slug =
          query
          |> Ash.Query.get_argument(:slug)
          |> normalize_slug()

        Ash.Query.filter(query, expr(slug == ^slug))
      end)
    end

    read :by_owner do
      argument :owner_type, :atom do
        allow_nil?(false)
        constraints(one_of: [:user, :organization])
      end

      argument :owner_id, :uuid do
        allow_nil?(false)
      end

      filter(expr(owner_type == ^arg(:owner_type) and owner_id == ^arg(:owner_id)))
    end
  end

  attributes do
    uuid_primary_key(:id)

    attribute :slug, :string do
      allow_nil?(false)
      public?(true)
    end

    attribute :owner_type, :atom do
      allow_nil?(false)
      public?(true)
      constraints(one_of: [:user, :organization])
    end

    attribute :owner_id, :uuid do
      allow_nil?(false)
      public?(true)
    end

    timestamps()
  end

  identities do
    identity(:unique_slug, [:slug])
    identity(:unique_owner, [:owner_type, :owner_id])
  end

  defp normalize_slug(slug) when is_binary(slug), do: String.downcase(slug)
  defp normalize_slug(_slug), do: ""
end
