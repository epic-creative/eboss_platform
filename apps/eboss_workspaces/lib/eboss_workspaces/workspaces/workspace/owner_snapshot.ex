defmodule EBoss.Workspaces.Workspace.OwnerSnapshot do
  @moduledoc false

  alias EBoss.Accounts
  alias EBoss.Organizations

  def fetch(:user, owner_id) do
    case Accounts.get_user(owner_id, authorize?: false) do
      {:ok, %{username: username, id: id}} ->
        {:ok,
         %{
           type: :user,
           id: id,
           handle: username,
           display_name: username
         }}

      {:error, _error} ->
        {:error, :not_found}
    end
  end

  def fetch(:organization, owner_id) do
    case Organizations.get_organization(owner_id, authorize?: false) do
      {:ok, %{id: id, slug: slug, name: name}} ->
        {:ok,
         %{
           type: :organization,
           id: id,
           handle: slug,
           display_name: name
         }}

      {:error, _error} ->
        {:error, :not_found}
    end
  end

  def fetch(_owner_type, _owner_id), do: {:error, :not_found}

  def attributes(owner_type, owner_id) do
    case fetch(owner_type, owner_id) do
      {:ok, %{handle: handle, display_name: display_name}} ->
        {:ok, %{owner_handle: handle, owner_display_name: display_name}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def owner_summary(%{
        owner_type: owner_type,
        owner_id: owner_id,
        owner_handle: owner_handle,
        owner_display_name: owner_display_name
      })
      when is_binary(owner_handle) and is_binary(owner_display_name) do
    %{
      type: owner_type,
      id: owner_id,
      handle: owner_handle,
      display_name: owner_display_name
    }
  end

  def owner_summary(_record), do: nil

  def full_path(%{owner_type: :user, owner_handle: owner_handle, slug: slug})
      when is_binary(owner_handle) and is_binary(slug) do
    "@#{owner_handle}/#{slug}"
  end

  def full_path(%{owner_type: :organization, owner_handle: owner_handle, slug: slug})
      when is_binary(owner_handle) and is_binary(slug) do
    "#{owner_handle}/#{slug}"
  end

  def full_path(%{slug: slug}) when is_binary(slug), do: "unknown/#{slug}"
  def full_path(_record), do: "unknown"
end
