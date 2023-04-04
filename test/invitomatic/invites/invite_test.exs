defmodule Invitomatic.Invites.InviteTest do
  use Invitomatic.DataCase, async: true

  import Invitomatic.AccountsFixtures
  import Invitomatic.InvitesFixtures

  alias Invitomatic.Invites.Invite

  describe "changeset/2" do
    test "you can have one primary login for an invite" do
      invite = %{
        name: "An Invite",
        guests: [valid_guest_attributes(), valid_guest_attributes()],
        logins: []
      }

      invite_with_one_primary_login = %{
        invite
        | logins: [%{email: unique_email(), primary: true}, %{email: unique_email(), primary: false}]
      }

      invite_with_two_primary_logins = %{
        invite
        | logins: [%{email: unique_email(), primary: true}, %{email: unique_email(), primary: true}]
      }

      assert {:ok, _} = Repo.insert(Invite.changeset(%Invite{}, invite_with_one_primary_login))
      assert {:error, changeset} = Repo.insert(Invite.changeset(%Invite{}, invite_with_two_primary_logins))
      assert %{logins: [_, %{invite_id: _}]} = errors_on(changeset)
    end
  end
end
