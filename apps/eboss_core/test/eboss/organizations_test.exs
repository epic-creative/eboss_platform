defmodule EBoss.OrganizationsTest do
  use EBoss.DataCase, async: false

  import Ash.Expr
  import Swoosh.TestAssertions
  require Ash.Query

  setup :set_swoosh_global

  test "organizations generate unique slugs and memberships can be managed by the owner" do
    owner = register_user()
    member = register_user()

    first_org = create_organization(owner, %{name: "Acme Labs"})
    second_org = create_organization(owner, %{name: "Acme Labs"})

    assert first_org.slug == "acme-labs"
    assert second_org.slug == "acme-labs-1"

    membership =
      EBoss.Organizations.Membership
      |> Ash.Changeset.for_create(
        :create,
        %{
          user_id: member.id,
          organization_id: first_org.id,
          role: :member
        },
        actor: owner
      )
      |> Ash.create!()

    updated_membership =
      membership
      |> Ash.Changeset.for_update(:update_role, %{role: :admin}, actor: owner)
      |> Ash.update!()

    assert updated_membership.role == :admin
  end

  test "organization ownership syncs a protected owner membership" do
    original_owner = register_user()
    new_owner = register_user()

    organization = create_organization(original_owner, %{name: "Owner Sync Org"})

    owner_membership = membership_for!(organization.id, original_owner.id)
    assert owner_membership.role == :owner

    assert {:error, create_error} =
             EBoss.Organizations.Membership
             |> Ash.Changeset.for_create(
               :create,
               %{
                 user_id: new_owner.id,
                 organization_id: organization.id,
                 role: :owner
               },
               actor: original_owner
             )
             |> Ash.create()

    assert Exception.message(create_error) =~ "owner role is system-managed"

    transferred_org =
      organization
      |> Ash.Changeset.for_update(
        :transfer_ownership,
        %{new_owner_id: new_owner.id},
        actor: original_owner
      )
      |> Ash.update!()

    assert transferred_org.owner_id == new_owner.id
    current_owner_membership = membership_for!(organization.id, new_owner.id)
    former_owner_membership = membership_for!(organization.id, original_owner.id)

    assert current_owner_membership.role == :owner
    assert former_owner_membership.role == :member

    assert {:error, destroy_error} =
             current_owner_membership
             |> Ash.Changeset.for_destroy(:destroy, %{}, actor: new_owner)
             |> Ash.destroy()

    assert Exception.message(destroy_error) =~ "owner membership is system-managed"

    assert :ok =
             owner_membership
             |> Ash.Changeset.for_destroy(:destroy, %{}, actor: new_owner)
             |> Ash.destroy()
  end

  test "invitations can be created, resent, deduplicated, and accepted" do
    owner = register_user()
    invitee = register_user(%{email: "invitee@example.com"})
    organization = create_organization(owner, %{name: "Invite Org"})
    flush_emails()

    invitation =
      EBoss.Organizations.Invitation
      |> Ash.Changeset.for_create(
        :create,
        %{
          email: invitee.email,
          role: :member,
          organization_id: organization.id,
          invited_by_id: owner.id
        },
        actor: owner
      )
      |> Ash.create!()

    assert invitation.token
    assert invitation.expires_at

    assert {:error, error} =
             EBoss.Organizations.Invitation
             |> Ash.Changeset.for_create(
               :create,
               %{
                 email: invitee.email,
                 role: :member,
                 organization_id: organization.id,
                 invited_by_id: owner.id
               },
               actor: owner
             )
             |> Ash.create()

    assert Exception.message(error) =~ "pending invitation"

    resent_invitation =
      invitation
      |> Ash.Changeset.for_update(:resend, %{}, actor: owner)
      |> Ash.update!()

    refute resent_invitation.token == invitation.token

    accepted_invitation =
      resent_invitation
      |> Ash.Changeset.for_update(:accept, %{
        token: resent_invitation.token,
        accepting_user_id: invitee.id
      })
      |> Ash.update!(authorize?: false)

    assert accepted_invitation.accepted_at

    memberships =
      EBoss.Organizations.Membership
      |> Ash.Query.filter(expr(user_id == ^invitee.id and organization_id == ^organization.id))
      |> Ash.read!(authorize?: false)

    assert length(memberships) == 1
    assert hd(memberships).role == :member
  end

  test "accepting an invitation rolls back when membership creation fails" do
    owner = register_user()
    invitee = register_user(%{email: "rollback-invitee@example.com"})
    organization = create_organization(owner, %{name: "Rollback Invite Org"})
    flush_emails()

    invitation =
      EBoss.Organizations.Invitation
      |> Ash.Changeset.for_create(
        :create,
        %{
          email: invitee.email,
          role: :member,
          organization_id: organization.id,
          invited_by_id: owner.id
        },
        actor: owner
      )
      |> Ash.create!()

    {1, nil} =
      from(i in "invitations",
        where: field(i, :id) == type(^invitation.id, Ecto.UUID)
      )
      |> Repo.update_all(set: [role: "owner"])

    assert {:error, error} =
             invitation
             |> Ash.Changeset.for_update(:accept, %{
               token: invitation.token,
               accepting_user_id: invitee.id
             })
             |> Ash.update(authorize?: false)

    assert Exception.message(error) =~ "owner role is system-managed"

    reloaded_invitation =
      Ash.get!(EBoss.Organizations.Invitation, invitation.id, authorize?: false)

    assert is_nil(reloaded_invitation.accepted_at)

    memberships =
      EBoss.Organizations.Membership
      |> Ash.Query.filter(expr(user_id == ^invitee.id and organization_id == ^organization.id))
      |> Ash.read!(authorize?: false)

    assert memberships == []
  end

  defp register_user(overrides \\ %{}) do
    params =
      Map.merge(
        %{
          email: "user#{System.unique_integer([:positive])}@example.com",
          username: "user#{System.unique_integer([:positive])}",
          password: "supersecret123",
          password_confirmation: "supersecret123"
        },
        overrides
      )

    EBoss.Accounts.User
    |> Ash.Changeset.for_create(:register_with_password, params)
    |> Ash.Changeset.set_context(%{private: %{ash_authentication?: true}})
    |> Ash.create!(authorize?: false)
  end

  defp create_organization(actor, attrs) do
    EBoss.Organizations.Organization
    |> Ash.Changeset.for_create(:create, attrs, actor: actor)
    |> Ash.create!()
  end

  defp flush_emails do
    receive do
      {:email, _email} -> flush_emails()
    after
      0 -> :ok
    end
  end

  defp membership_for!(organization_id, user_id) do
    EBoss.Organizations.Membership
    |> Ash.Query.filter(expr(organization_id == ^organization_id and user_id == ^user_id))
    |> Ash.read_one!(authorize?: false)
  end
end
