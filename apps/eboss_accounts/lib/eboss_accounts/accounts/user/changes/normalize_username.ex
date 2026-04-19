defmodule EBoss.Accounts.User.Changes.NormalizeUsername do
  use Ash.Resource.Change

  def init(opts), do: {:ok, opts}

  def change(changeset, _opts, _context) do
    case Ash.Changeset.get_argument(changeset, :username) do
      nil ->
        case Ash.Changeset.get_attribute(changeset, :username) do
          nil -> changeset
          username -> validate_and_normalize(changeset, username)
        end

      username ->
        validate_and_normalize(changeset, username)
    end
  end

  defp validate_and_normalize(changeset, username) do
    normalized = String.downcase(username)

    cond do
      String.length(normalized) < 3 ->
        Ash.Changeset.add_error(changeset,
          field: :username,
          message: "Username must be at least 3 characters long"
        )

      String.length(normalized) > 39 ->
        Ash.Changeset.add_error(changeset,
          field: :username,
          message: "Username must be at most 39 characters long"
        )

      !Regex.match?(~r/^[a-z0-9][a-z0-9-]*[a-z0-9]$/, normalized) &&
          String.length(normalized) > 1 ->
        Ash.Changeset.add_error(changeset,
          field: :username,
          message:
            "Username must start and end with a letter or number, and can only contain lowercase letters, numbers, and hyphens"
        )

      String.length(normalized) == 1 && !Regex.match?(~r/^[a-z0-9]$/, normalized) ->
        Ash.Changeset.add_error(changeset,
          field: :username,
          message: "Single character usernames must be a letter or number"
        )

      normalized in EBoss.Slugs.reserved_slugs() ->
        Ash.Changeset.add_error(changeset,
          field: :username,
          message: "Username '#{normalized}' is reserved and cannot be used"
        )

      String.contains?(normalized, "--") ->
        Ash.Changeset.add_error(changeset,
          field: :username,
          message: "Username cannot contain consecutive hyphens"
        )

      true ->
        Ash.Changeset.change_attribute(changeset, :username, normalized)
    end
  end
end
