defmodule EBoss.AuthLinks do
  @moduledoc """
  Builds absolute URLs for account authentication flows from core-app config.
  """

  def confirm_url(token), do: build("/confirm/#{token}")
  def reset_url(token), do: build("/reset/#{token}")
  def magic_link_url(token), do: build("/magic_link/#{token}")

  defp build(path) do
    base =
      :eboss_core
      |> Application.get_env(:public_url, "http://localhost:4000")
      |> String.trim_trailing("/")

    base <> path
  end
end
