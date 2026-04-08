defmodule EBoss.Accounts.User.Validations.ValidateSlug do
  use Ash.Resource.Validation

  @impl true
  def validate(changeset, _opts, _context) do
    username = Ash.Changeset.get_attribute(changeset, :username)

    username =
      if username do
        username
      else
        case Ash.Changeset.fetch_argument(changeset, :username) do
          {:ok, arg_username} when is_binary(arg_username) -> String.downcase(arg_username)
          _ -> nil
        end
      end

    if username && username in EBoss.Slugs.reserved_slugs() do
      {:error, field: :username, message: "#{username} is a reserved slug"}
    else
      :ok
    end
  end
end
