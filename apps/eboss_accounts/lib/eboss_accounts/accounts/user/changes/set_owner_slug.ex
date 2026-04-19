defmodule EBoss.Accounts.User.Changes.SetOwnerSlug do
  use Ash.Resource.Change

  @impl true
  def change(changeset, _opts, _context) do
    case Ash.Changeset.get_attribute(changeset, :username) do
      username when is_binary(username) ->
        Ash.Changeset.force_change_attribute(changeset, :owner_slug, username)

      _ ->
        changeset
    end
  end
end
