defmodule EBossChat.Changes.DeriveSessionTitle do
  use Ash.Resource.Change

  alias Ash.Changeset

  @fallback_title "New chat"
  @max_title_length 80

  @impl true
  def change(changeset, _opts, _context) do
    title =
      changeset
      |> Changeset.get_attribute(:title)
      |> normalize()

    if title != "" do
      changeset
    else
      title_seed =
        changeset
        |> Changeset.get_argument(:title_seed)
        |> normalize()

      derived_title =
        if title_seed == "" do
          @fallback_title
        else
          title_seed
          |> String.replace(~r/\s+/, " ")
          |> String.slice(0, @max_title_length)
        end

      Changeset.change_attribute(changeset, :title, derived_title)
    end
  end

  defp normalize(nil), do: ""
  defp normalize(value), do: value |> to_string() |> String.trim()
end
