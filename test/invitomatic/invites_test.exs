defmodule Invitomatic.InvitesTest do
  use Invitomatic.DataCase

  alias Invitomatic.Invites
  alias Invitomatic.Invites.Invite

  import Invitomatic.InvitesFixtures

  @invalid_attrs %{name: ""}

  describe "change/2" do
    test "change/1 returns a invite changeset" do
      invite = invite_fixture()
      assert %Ecto.Changeset{} = Invites.change(invite)
    end
  end

  describe "create/1" do
    test "with valid data creates an invite with a login" do
      valid_attrs = %{
        name: "Foo McName and Bar McName",
        guests: [
          %{name: name_one = unique_name(), age: :adult},
          %{name: name_two = unique_name(), age: :child}
        ],
        logins: [%{email: email = Invitomatic.AccountsFixtures.unique_email()}]
      }

      assert {:ok, %Invite{guests: [guest_one, guest_two], logins: [login]} = invite} = Invites.create(valid_attrs)

      assert invite.name == "Foo McName and Bar McName"
      assert login.email == email
      assert login.primary == true
      assert guest_one.name == name_one
      assert guest_one.age == :adult
      assert guest_two.name == name_two
      assert guest_two.age == :child
    end

    test "with invalid data returns an error" do
      assert {:error, %Ecto.Changeset{}} = Invites.create(@invalid_attrs)
    end
  end

  describe "get/1" do
    test "it returns the invite with guests and logins preloaded" do
      fixture = invite_fixture()
      assert invite = Invites.get(fixture.id)
      assert invite.name == fixture.name
      assert [%_{}] = invite.logins
      assert [%_{}] = invite.guests
    end
  end

  describe "list_guests/0" do
    test "returns all guests grouped by invite" do
      # TODO: actual guests
      guest = guest_fixture()
      assert Invites.list_guests() == [guest]
    end
  end

  describe "update/2" do
    test "with valid data updates the invite" do
      invite = invite_fixture()
      update_attrs = %{name: "Nu Name"}

      assert {:ok, %Invite{} = updated_invite} = Invites.update(invite, update_attrs)
      assert updated_invite.name != invite.name
      assert updated_invite.name == "Nu Name"
    end

    test "with invalid data returns error changeset" do
      invite = invite_fixture()
      assert {:error, %Ecto.Changeset{}} = Invites.update(invite, @invalid_attrs)
      assert invite == Invites.get(invite.id)
    end
  end
end
