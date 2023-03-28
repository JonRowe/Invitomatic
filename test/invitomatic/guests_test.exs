defmodule Invitomatic.GuestsTest do
  use Invitomatic.DataCase, async: true

  alias Invitomatic.Accounts
  alias Invitomatic.Accounts.Login, as: Guest
  alias Invitomatic.Guests

  import Invitomatic.InvitesFixtures

  describe "delete/1" do
    test "delete/1 deletes the guest" do
      guest = guest_fixture()
      assert {:ok, %Guest{}} = Guests.delete(guest)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_login!(guest.id) end
    end
  end
end
