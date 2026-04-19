defmodule EBoss.Workspaces.Workspace.OwnerSnapshot do
  @moduledoc false

  alias EBoss.Accounts
  alias EBoss.Organizations

  def fetch(:user, owner_id) do
    case Accounts.get_user(owner_id, authorize?: false) do
      {:ok, %{username: username, owner_slug: owner_slug, id: id}} ->
        {:ok,
         %{
           type: :user,
           id: id,
           slug: owner_slug,
           display_name: username
         }}

      {:error, _error} ->
        {:error, :not_found}
    end
  end

  def fetch(:organization, owner_id) do
    case Organizations.get_organization(owner_id, authorize?: false) do
      {:ok, %{id: id, owner_slug: owner_slug, name: name}} ->
        {:ok,
         %{
           type: :organization,
           id: id,
           slug: owner_slug,
           display_name: name
         }}

      {:error, _error} ->
        {:error, :not_found}
    end
  end

  def fetch(_owner_type, _owner_id), do: {:error, :not_found}

  def attributes(owner_type, owner_id) do
    case fetch(owner_type, owner_id) do
      {:ok, %{slug: owner_slug, display_name: display_name}} ->
        {:ok, %{owner_slug: owner_slug, owner_display_name: display_name}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def owner_summary(%{
        owner_type: owner_type,
        owner_id: owner_id,
        owner_slug: owner_slug,
        owner_display_name: owner_display_name
      })
      when is_binary(owner_slug) and is_binary(owner_display_name) do
    %{
      type: owner_type,
      id: owner_id,
      slug: owner_slug,
      display_name: owner_display_name
    }
  end

  def owner_summary(_record), do: nil

  def full_path(%{owner_slug: owner_slug, slug: slug})
      when is_binary(owner_slug) and is_binary(slug) do
    "#{owner_slug}/#{slug}"
  end

  def full_path(%{slug: slug}) when is_binary(slug), do: "unknown/#{slug}"
  def full_path(_record), do: "unknown"
end
