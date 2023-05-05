defmodule Invitomatic.ContentTest do
  use Invitomatic.DataCase, async: true

  alias Invitomatic.Content
  alias Invitomatic.Content.Section

  import Invitomatic.ContentFixtures

  @invalid_attrs %{text: nil}

  describe "change_section/1" do
    test " returns a section changeset" do
      section = content_fixture()
      assert %Ecto.Changeset{} = Content.change_section(section)
    end
  end

  describe "create_section/1" do
    test "with valid data creates a section" do
      valid_attrs = %{text: "some text", type: "rsvp"}

      assert {:ok, %Section{} = section} = Content.create_section(valid_attrs)
      assert section.text == "some text"
    end

    test "with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Content.create_section(@invalid_attrs)
    end
  end

  describe "delete_section/1" do
    test " deletes the section" do
      section = content_fixture()
      assert {:ok, %Section{}} = Content.delete_section(section)
      assert_raise Ecto.NoResultsError, fn -> Content.get_section!(section.id) end
    end
  end

  describe "get/1" do
    test "returns the sections with given type" do
      section_one = content_fixture(type: :invitation)
      assert Content.get(:invitation) == [section_one]

      section_two = content_fixture(type: :invitation)
      assert Content.get(:invitation) == [section_one, section_two]
    end

    test "returns blank if the section does not exist" do
      assert Content.get(:invitation) == [%Section{text: ""}]
    end
  end

  describe "get_section!/1" do
    test "returns the section with given id" do
      section = content_fixture()
      assert Content.get_section!(section.id) == section
    end
  end

  describe "list/0" do
    test "returns all content section" do
      section = content_fixture()
      assert Content.list() == [section]
    end
  end

  describe "update_section/2" do
    test "with valid data updates the section" do
      section = content_fixture()
      update_attrs = %{text: "some updated text"}

      assert {:ok, %Section{} = section} = Content.update_section(section, update_attrs)
      assert section.text == "some updated text"
    end

    test "with invalid data returns error changeset" do
      section = content_fixture()
      assert {:error, %Ecto.Changeset{}} = Content.update_section(section, @invalid_attrs)
      assert section == Content.get_section!(section.id)
    end
  end
end
