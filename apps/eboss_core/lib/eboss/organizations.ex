defmodule EBoss.Organizations do
  use Ash.Domain, otp_app: :eboss_core

  resources do
    resource EBoss.Organizations.Organization
    resource EBoss.Organizations.Membership
    resource EBoss.Organizations.Invitation
  end
end
