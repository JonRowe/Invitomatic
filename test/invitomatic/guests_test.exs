defmodule Invitomatic.GuestsTest do
  use Invitomatic.DataCase, async: true

  alias Invitomatic.Accounts
  alias Invitomatic.Accounts.Login, as: Guest
  alias Invitomatic.Guests

  import Invitomatic.AccountsFixtures

  @invalid_attrs %{"email" => "none"}

  describe "list/0" do
    test "it returns logins for now" do
      login_one = guest_fixture()
      login_two = guest_fixture()

      assert guests = Guests.list()
      assert Enum.member?(guests, login_one)
      assert Enum.member?(guests, login_two)
    end

    test "it returns an empty list when none present" do
      assert [] == Guests.list()
    end
  end

  describe "change/2" do
    test "change/1 returns a guest changeset" do
      guest = guest_fixture()
      assert %Ecto.Changeset{} = Guests.change(guest)
    end
  end

  describe "create/1" do
    test "create/1 with valid data creates a guest" do
      assert {:ok, %Guest{} = _guest} = Guests.create(valid_login_attributes())
    end

    test "create/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Guests.create(@invalid_attrs)
    end
  end

  describe "delete/1" do
    test "delete/1 deletes the guest" do
      guest = guest_fixture()
      assert {:ok, %Guest{}} = Guests.delete(guest)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_login!(guest.id) end
    end
  end

  describe "update/2" do
    test "update/2 with valid data updates the guest" do
      guest = guest_fixture()
      update_attrs = %{}

      assert {:ok, %Guest{} = _guest} = Guests.update(guest, update_attrs)
    end

    test "update/2 with invalid data returns error changeset" do
      guest = guest_fixture()
      assert {:error, %Ecto.Changeset{}} = Guests.update(guest, @invalid_attrs)
      assert guest == Accounts.get_login!(guest.id)
    end
  end
end
