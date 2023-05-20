defmodule InvitomaticWeb.Components.Content do
  use Phoenix.Component
  use InvitomaticWeb, :verified_routes

  alias Invitomatic.Content.Section

  require Logger

  def render(%{content: %Section{text: raw}} = bindings) do
    case EarmarkParser.as_ast(raw) do
      {:ok, ast, deprecations} ->
        maybe_log_message("deprecations", deprecations, &Logger.warn/1)
        render_ast(ast, bindings)

      {:error, ast, errors} ->
        maybe_log_message("errors", errors, &Logger.error/1)
        render_ast(ast, bindings)
    end
  end

  defp logger_message(type, list),
    do: fn -> "There were #{type} encountered during content render: #{Enum.map(list, &"\n#{inspect(&1)}")}" end

  defp build([]), do: ""
  defp build([text_node]) when is_binary(text_node), do: text_node
  defp build({tag, attrs, content, _meta}), do: build({tag, attrs, content})
  defp build({tag, attrs, content}), do: build_tag(tag, build_attrs(attrs), build(content))

  def build_tag(name, "", content), do: "<#{name}>#{content}</#{name}>"
  def build_tag(name, attrs, content), do: "<#{name} #{attrs}>#{content}</#{name}>"

  defp build_attrs(attrs) do
    attrs
    |> Enum.map(fn {name, value} -> Enum.join([name, escape(value)], "=") end)
    |> Enum.join(" ")
  end

  defp escape(value), do: "\"#{value}\""

  defp maybe_log_message(_type, [], _function), do: :ok
  defp maybe_log_message(type, contents, function), do: function.(logger_message(type, contents))

  defp render_ast(ast, bindings) do
    source = Enum.join(Enum.map(ast, &build(&1)), "\n")

    {result, _binding} =
      Code.eval_quoted(
        EEx.compile_string(
          source,
          engine: Phoenix.LiveView.TagEngine,
          line: 1,
          trim: Application.get_env(:phoenix, :trim_on_html_eex_engine, true),
          caller: __MODULE__,
          source: source,
          tag_handler: Phoenix.LiveView.HTMLEngine
        ),
        assigns: Map.delete(bindings, :content)
      )

    result
  end
end
