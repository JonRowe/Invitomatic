defmodule Invitomatic.InvitesTest do
  use Invitomatic.DataCase, async: true

  alias Invitomatic.Invites
  alias Invitomatic.Invites.Guest
  alias Invitomatic.Invites.Invite

  import Invitomatic.InvitesFixtures

  @invalid_attrs %{name: ""}

  describe "change/2" do
    test "change/1 returns a invite changeset" do
      invite = invite_fixture()
      assert %Ecto.Changeset{} = Invites.change(invite)
    end
  end

  describe "change_guest/2" do
    test "change_guest/1 returns a guest changeset" do
      guest = guest_fixture()
      assert %Ecto.Changeset{} = Invites.change_guest(guest)
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

  describe "delete_guest/2" do
    test "deletes the guest when the guest is on the invite" do
      %{guests: [guest]} = invite = invite_fixture()
      assert {:ok, %Guest{}} = Invites.delete_guest(invite, guest.id)
      assert nil == Invites.get_guest(invite, guest.id)
    end

    test "will not delete the guest when the guest is on a different invite" do
      invite = invite_fixture()
      guest = guest_fixture()
      assert {:error, changeset} = Invites.delete_guest(invite, guest.id)
      assert %{invite: ["did not match"]} == errors_on(changeset)
    end
  end

  describe "deliver_invite/2" do
    test "it sets invite send_at" do
      assert {:ok, invite} = Invites.deliver_invite(invite_fixture(%{send_at: nil}), & &1)
      assert NaiveDateTime.compare(invite.sent_at, NaiveDateTime.add(NaiveDateTime.utc_now(), -1, :minute)) == :gt
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

    test "guests are ordered by insert order" do
      one_minute_from_now = DateTime.add(DateTime.utc_now(), 60)
      fixture = invite_fixture()
      add_guest_to_invite_fixture(fixture, %{inserted_at: one_minute_from_now})

      assert [guest_one, guest_two] = Invites.get(fixture.id).guests
      assert guest_one.inserted_at < guest_two.inserted_at
    end
  end

  describe "get_for/1" do
    test "it returns the invite with guests and logins preloaded for a login" do
      %{logins: [login]} = fixture = invite_fixture()
      assert invite = Invites.get_for(login)
      assert invite.name == fixture.name
      assert [login] == invite.logins
      assert [%_{}] = invite.guests
    end

    test "it returns the invite with guests and logins preloaded for a guest" do
      %{guests: [guest]} = fixture = invite_fixture()
      assert invite = Invites.get_for(guest)
      assert invite.name == fixture.name
      assert [%_{}] = invite.logins
      assert [guest] == invite.guests
    end
  end

  describe "get_guest/2" do
    test "returns the guest when on the invite" do
      %{guests: [%Guest{id: id}]} = invite = invite_fixture()
      assert %Guest{id: ^id} = Invites.get_guest(invite, id)
    end

    test "returns when on a different invite" do
      invite = invite_fixture()
      guest = guest_fixture()
      assert nil == Invites.get_guest(invite, guest.id)
    end
  end

  describe "list/0" do
    test "returns invites with guests and invites" do
      %{guests: [%{name: name_one}, %{name: name_two}]} =
        invite_fixture(%{guests: [valid_guest_attributes(), valid_guest_attributes()]})

      %{guests: [%{name: name_three}]} = invite_fixture(%{guests: [valid_guest_attributes()]})

      assert [
               %Invite{guests: [%Guest{name: ^name_one}, %Guest{name: ^name_two}]},
               %Invite{guests: [%Guest{name: ^name_three}]}
             ] = Invites.list()
    end
  end

  describe "management_update/2" do
    test "with valid data updates the invite" do
      invite = invite_fixture()
      update_attrs = %{name: "Nu Name"}

      assert {:ok, %Invite{} = updated_invite} = Invites.management_update(invite, update_attrs)
      assert updated_invite.name != invite.name
      assert updated_invite.name == "Nu Name"
    end

    test "it can lock an invite" do
      invite = invite_fixture()

      refute invite.locked
      assert {:ok, %Invite{} = updated_invite} = Invites.management_update(invite, %{locked: true})
      assert updated_invite.locked
    end

    test "with valid data updates the invite even if locked" do
      invite = invite_fixture(%{locked: true})
      update_attrs = %{name: "Nu Name"}

      assert {:ok, %Invite{} = updated_invite} = Invites.management_update(invite, update_attrs)
      assert updated_invite.name != invite.name
      assert updated_invite.name == "Nu Name"
    end

    test "with invalid data returns error changeset" do
      invite = invite_fixture()
      assert {:error, %Ecto.Changeset{}} = Invites.management_update(invite, @invalid_attrs)
      assert invite == Invites.get(invite.id)
    end
  end

  describe "update_guest/2" do
    setup do: %{guest: guest_fixture()}

    test "with valid data updates the guests rsvp", %{guest: guest} do
      assert {:ok, %Guest{} = updated_guest} = Invites.update_guest(guest, %{rsvp: "yes"})
      assert updated_guest.rsvp == :yes
    end

    test "with invalid data returns error changeset", %{guest: guest} do
      assert {:error, %Ecto.Changeset{}} = Invites.update_guest(guest, %{rsvp: :not_valid})
    end

    test "with a locked invite returns an error changeset" do
      %{guests: [guest], locked: true} = invite_fixture(%{locked: true})
      assert {:error, %Ecto.Changeset{}} = Invites.update_guest(guest, %{rsvp: "yes"})
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

    test "it can lock an invite" do
      invite = invite_fixture()

      refute invite.locked
      assert {:ok, %Invite{} = updated_invite} = Invites.update(invite, %{locked: true})
      assert updated_invite.locked
    end

    test "with invalid data returns error changeset" do
      invite = invite_fixture()
      assert {:error, %Ecto.Changeset{}} = Invites.update(invite, @invalid_attrs)
      assert invite == Invites.get(invite.id)
    end
  end
end
