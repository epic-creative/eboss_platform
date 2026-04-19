defmodule EBoss.OwnerSlugs do
  use Ash.Domain, otp_app: :eboss_accounts

  resources do
    resource(EBoss.OwnerSlugs.OwnerSlug)
  end

  alias EBoss.OwnerSlugs.OwnerSlug

  defdelegate reserve_owner_slug(slug, owner_type, owner_id, opts \\ []), to: OwnerSlug
  defdelegate reserve_owner_slug!(slug, owner_type, owner_id, opts \\ []), to: OwnerSlug
  defdelegate resolve_owner_by_slug(slug, opts \\ []), to: OwnerSlug, as: :get_owner_slug_by_slug

  defdelegate resolve_owner_by_slug!(slug, opts \\ []),
    to: OwnerSlug,
    as: :get_owner_slug_by_slug!

  defdelegate get_owner_slug_by_owner(owner_type, owner_id, opts \\ []), to: OwnerSlug
  defdelegate get_owner_slug_by_owner!(owner_type, owner_id, opts \\ []), to: OwnerSlug
end
