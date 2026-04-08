defmodule EBoss.Accounts do
  use Ash.Domain, otp_app: :eboss_accounts

  resources do
    resource(EBoss.Accounts.Token)
    resource(EBoss.Accounts.User)
    resource(EBoss.Accounts.ApiKey)
  end
end
