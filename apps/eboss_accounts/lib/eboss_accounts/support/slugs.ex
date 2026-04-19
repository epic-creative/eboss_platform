defmodule EBoss.Slugs do
  @moduledoc """
  Utilities for validating and reserving user and organization slugs.
  """

  @reserved_slugs ~w(
    login signup sign-in register forgot-password reset confirm logout magic-link auth
    admin dashboard settings
    api dev rpc ash-typescript swaggerui open-api open_api mailbox storybook live-vue live_vue
    privacy terms features pricing faq about contact docs help support
    users orgs workspace workspaces
    assets static css js images uploads public
  )

  def reserved_slugs, do: @reserved_slugs

  def validate_slug(slug) when is_binary(slug) do
    cond do
      String.length(slug) < 3 or String.length(slug) > 39 ->
        {:error, "must be between 3 and 39 characters"}

      slug in @reserved_slugs ->
        {:error, "#{slug} is a reserved slug"}

      not Regex.match?(~r/^[a-z0-9-]+$/, slug) ->
        {:error, "must contain only lowercase letters, numbers, and hyphens"}

      String.starts_with?(slug, "-") or String.ends_with?(slug, "-") ->
        {:error, "cannot start or end with a hyphen"}

      String.contains?(slug, "--") ->
        {:error, "cannot contain consecutive hyphens"}

      true ->
        :ok
    end
  end

  def validate_slug(_), do: {:error, "must be a string"}
end
