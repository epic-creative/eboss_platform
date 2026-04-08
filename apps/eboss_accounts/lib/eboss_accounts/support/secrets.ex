defmodule EBoss.Secrets do
  use AshAuthentication.Secret

  def secret_for(
        [:authentication, :tokens, :signing_secret],
        EBoss.Accounts.User,
        _opts,
        _context
      ) do
    case Application.fetch_env(:eboss_accounts, :token_signing_secret) do
      {:ok, secret} ->
        {:ok, secret}

      :error ->
        raise """
        Token signing secret not configured.
        Set config :eboss_accounts, :token_signing_secret in runtime configuration.
        """
    end
  end
end
