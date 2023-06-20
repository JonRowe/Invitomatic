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
        slug: "some-#{System.unique_integer()}",
        text: "some text",
        title: "something",
        type: :rsvp
      })
      |> Invitomatic.Content.create_section()

    section
  end

  def extract_content(fun) do
    {:ok, captured_email} = fun.()
    captured_email.text_body
  end
end
