defmodule Docopt do
  @moduledoc """
  Documentation for Docopt.
  """

  require Docopt.Tree
  require Docopt.Options
  require Docopt.Tokenizer

  defmacro parse_arguments(arguments) do
    quote do
      [options: options, tree: tree] = Docopt.parse_docstring(@docopt)

      Docopt.match_arguments(unquote(arguments), tree, options)
    end
  end

  def parse_docstring(docstring) do
    options = docstring
      |> parse_section("options")
      |> Docopt.Options.parse_section()
    tree = docstring
      |> parse_section("usage")
      |> parse_usage_section(options)

    [options: Docopt.Options.update(options, tree), tree: tree]
  end

  def match_arguments(arguments, tree, options) do
    arguments = arguments
      |> String.split()
      |> Docopt.Tokenizer.parse(options)

    case Docopt.Tree.match(tree, arguments, options) do
      [arguments: [], options: opts] ->
        opts |> List.flatten() |> Docopt.Options.match(options)
      [arguments: _, options: _] -> :nomatch
      :nomatch -> :nomatch
    end
  end

  defp parse_section(docstring, name) do
    pattern = ~r/^(?:[^\n]*)(?:#{name}:)([^\n]*\n?(?:[ \t].*?(?:\n|$))*)/imu

    case Regex.scan(pattern, docstring, capture: :all_but_first) do
      [] -> ""
      [[match] | []] -> match
      matches -> Enum.reduce(matches, "", fn([str], acc) -> acc <> str end)
    end
  end

  defp parse_usage_section(section, options) do
    section |> formal_usage() |> Docopt.Tokenizer.parse(options)
  end

  # Formalize the Usage section as: ( usage-pattern | usage-pattern )
  # and return it in a list of token strings.
  defp formal_usage(section) do
    [name | section] = String.split(section)

    formal = section
      |> Enum.map(fn(s) -> if s == name, do: " | ", else: s end)
      |> Enum.join(" ")

    "( #{formal} )"
    |> String.replace(~r/(\[|\(|\]|\)|\||\.\.\.)/, " \\1 ")
    |> String.replace(~r/ +/, " ")
    |> String.split()
  end
end
