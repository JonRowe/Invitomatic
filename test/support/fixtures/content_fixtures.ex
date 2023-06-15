defmodule Invitomatic.ContentFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Invitomatic.Content` context.
  """

  @doc """
  Generate a section.
  """
  def content_fixture(attrs \\ %{}) do
    {:ok, section} =
      attrs
      |> Enum.into(%{
        text: "some text",
        title: "something",
        type: :rsvp
      })
      |> Invitomatic.Content.create_section()

    section
  end
end
