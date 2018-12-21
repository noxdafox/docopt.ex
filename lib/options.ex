defmodule Docopt.Options do
  @moduledoc """
  Options parsing module.
  """

  @doc """
  Parse the options section returning the list of declared options.
  """
  def parse_section(section) do
    if String.length(section) > 0 do
      section |> options_strings() |> Enum.map(fn(s) -> option(s) end)
    else
      []
    end
  end

  @doc """
  Traverse the match tree updating the list of options.
  """
  def update(options, {:required, tree}) do
    update_options(options, tree)
  end

  @doc """
  Match the arguments with the options adding missing ones with their defaults.
  """
  def match(arguments, options) do
    Enum.reduce(options, %{}, fn(option, accumulator) ->
      option |> match_option(arguments) |> Map.merge(accumulator)
    end)
  end

  # Traverse the given tree updating the list of options
  defp update_options(options, [{atom, sub_tree} | tree])
      when atom in [:required, :optional, :xor, :ellipses] do
    options |> update_options(sub_tree) |> update_options(tree)
  end

  defp update_options(options, [leaf | tree]) when is_tuple(leaf) do
    options |> maybe_update_options(leaf) |> update_options(tree)
  end

  defp update_options(options, [sub_tree | tree]) when is_list(sub_tree) do
    options |> update_options(sub_tree) |> update_options(tree)
  end

  defp update_options(options, [atom | tree]) when is_atom(atom) do
    update_options(options, tree)
  end

  defp update_options(options, []) do
    options
  end

  # Update the options list if the given option is not already present
  defp maybe_update_options(options, {atom, option}) do
    if Enum.find(options, false, fn o -> List.keymember?(o, option, 1) end) do
      options
    else
      [[{atom, option}]] ++ options
    end
  end

  defp maybe_update_options(options, {atom, option, argument}) do
    if Enum.find(options, false, fn o -> List.keymember?(o, option, 1) end) do
      options
    else
      [[{atom, option}, {:argument, argument}]] ++ options
    end
  end

  # Return the argument if found, the default value otherwise
  defp match_option([argument: argument], arguments) do
    case Enum.filter(arguments, fn(a) -> elem(a, 0) == argument end) do
      [] -> %{argument => nil}
      [{argument, value}] -> %{argument => value}
      arguments -> %{argument => Enum.map(arguments, fn(a) -> elem(a, 1) end)}
    end
  end

  defp match_option([literal: literal], arguments) do
    case List.keyfind(arguments, literal, 0) do
      {literal, true} -> %{literal => true}
      nil -> %{literal => false}
    end
  end

  defp match_option(option, arguments) do
    long = option_key(option, :long)
    short = option_key(option, :short)

    argument =
      case Enum.filter(arguments, fn(a) -> elem(a, 0) == long end) do
        [] ->
          case Enum.filter(arguments, fn(a) -> elem(a, 0) == short end) do
            [] -> nil
            [{_, value}] -> value
            arguments -> Enum.map(arguments, fn(a) -> elem(a, 1) end)
          end
        [{_, value}] -> value
        arguments -> Enum.map(arguments, fn(a) -> elem(a, 1) end)
      end

    opt = if long != nil, do: long, else: short

    case argument do
      nil ->
        if List.keymember?(option, :argument, 0) do
          %{opt => option_key(option, :default)}
        else
          %{opt => false}
        end
      argument -> %{opt => argument}
    end
  end

  # Splits the Options section in a list of option strings
  defp options_strings(options) do
    pattern = ~r/\n[ \t]*(-\S+?)/u
    [_ | split] = String.split("\n" <> options, pattern, include_captures: true)

    split
    |> Enum.take_every(2)
    |> Enum.zip(Enum.take_every(tl(split), 2))
    |> Enum.map(fn({s, l}) -> s <> l end)
    |> Enum.map(fn(s) -> String.trim(s) end)
  end

  # Parse the option string into a keyword list
  # [:short, :long, :argument, :default]
  defp option(string) do
    pattern = ~r/\[default: (.*)\]/iu
    [parameters | description] = String.split(string, "  ", trim: true)
    options = parameters
      |> String.replace(~r/[,=]/, " ")
      |> String.split()
      |> Enum.map(fn(s) -> parse_option_parameters(s) end)
      |> Enum.uniq_by(fn({x, _}) -> x end)

    if Keyword.has_key?(options, :argument) do
      description = Enum.join(description, " ")

      case Regex.run(pattern, description, capture: :all_but_first) do
        [default] -> [default: default] ++ options
        nil -> options
      end
    else
      options
    end
  end

  defp parse_option_parameters(string) do
    cond do
      String.starts_with?(string, "--") -> {:long, string}
      String.starts_with?(string, "-") -> {:short, string}
      true -> {:argument, string}
    end
  end

  defp option_key(option, key) do
    case List.keyfind(option, key, 0) do
      {_, value} -> value
      nil -> nil
    end
  end
end
