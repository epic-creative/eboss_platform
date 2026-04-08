defmodule EBoss.Logs do
  use Ash.Domain, otp_app: :eboss_core

  resources do
    resource EBoss.Logs.Log
  end

  def log(attrs, opts \\ []) do
    opts =
      opts
      |> Keyword.put_new(:authorize?, false)
      |> Keyword.put_new(:domain, __MODULE__)

    EBoss.Logs.Log
    |> Ash.Changeset.for_create(:create, build_attrs(attrs))
    |> Ash.create(opts)
  end

  def log_async(attrs, opts \\ []) do
    Task.Supervisor.start_child(EBoss.Logs.TaskSupervisor, fn ->
      log(attrs, opts)
    end)
  end

  def list_logs(filters \\ %{}, opts \\ []) do
    limit = Keyword.get(opts, :limit)
    actor = Keyword.get(opts, :actor)

    query =
      EBoss.Logs.Log
      |> Ash.Query.for_read(:by_filters, filters)
      |> then(fn query ->
        if limit, do: Ash.Query.limit(query, limit), else: query
      end)

    Ash.read(query, actor: actor)
  end

  def subscribe do
    Phoenix.PubSub.subscribe(EBoss.PubSub, "logs")
  end

  def build_attrs(attrs) when is_map(attrs) do
    attrs = Map.new(attrs, fn {k, v} -> {to_string(k), v} end)

    user_id = extract_user_id(attrs)
    organization_id = extract_organization_id(attrs)
    target_user_id = extract_target_user_id(attrs)
    user_type = determine_user_type(attrs, user_id)

    %{
      action: attrs["action"],
      user_type: user_type,
      metadata: Map.get(attrs, "metadata", %{}),
      user_id: user_id,
      org_id: organization_id,
      target_user_id: target_user_id
    }
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp extract_user_id(attrs) do
    cond do
      attrs["user_id"] ->
        attrs["user_id"]

      attrs["user"] && is_map(attrs["user"]) ->
        Map.get(attrs["user"], :id)

      true ->
        nil
    end
  end

  defp extract_organization_id(attrs) do
    cond do
      attrs["org_id"] ->
        attrs["org_id"]

      attrs["organization"] && is_map(attrs["organization"]) ->
        Map.get(attrs["organization"], :id)

      attrs["org"] && is_map(attrs["org"]) ->
        Map.get(attrs["org"], :id)

      true ->
        nil
    end
  end

  defp extract_target_user_id(attrs) do
    cond do
      attrs["target_user_id"] ->
        attrs["target_user_id"]

      attrs["target_user"] && is_map(attrs["target_user"]) ->
        Map.get(attrs["target_user"], :id)

      true ->
        nil
    end
  end

  defp determine_user_type(_attrs, nil), do: "system"

  defp determine_user_type(attrs, _user_id) do
    case attrs["user"] do
      %{role: :admin} -> "admin"
      _ -> "user"
    end
  end
end
