# Naval Fate.

# Usage:
#   naval_fate ship new <name>...
#   naval_fate ship <name> move <x> <y> [--speed=<kn>]
#   naval_fate ship shoot <x> <y>
#   naval_fate mine (set|remove) <x> <y> [--moored|--drifting]
#   naval_fate -h | --help
#   naval_fate --version

# Options:
#   -h --help     Show this screen.
#   --version     Show version.
#   --speed=<kn>  Speed in knots [default: 10].
#   --moored      Moored (anchored) mine.
#   --drifting    Drifting mine.


defmodule Docopt do
  @moduledoc """
  Documentation for Docopt.
  """

  require Docopt.Options

  def parse_docstring(docstring) do
    Docopt.Options.parse_options(docstring)
  end
end


defmodule Docopt.Options do
  @moduledoc """
  Options parsing module.
  """

  require Docopt.Utils

  def parse_options(docstring) do
    docstring
    |> Docopt.Utils.parse_section("options")
    |> options_strings()
    |> Enum.map(fn(s) -> option(s) end)
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
  # [:short, :long, :argument :default]
  defp option(string) do
    pattern = ~r/\[default: (.*)\]/iu
    [parameters | description] = String.split(string, "  ", trim: true)
    options =
      parameters
      |> String.replace(~r/[,=]/, " ")
      |> String.split()
      |> Enum.map(fn(s) -> parse_option_parameters(s) end)
      |> Enum.uniq_by(fn({x, _}) -> x end)

    if Keyword.has_key?(options, :argument) do
      description = Enum.join(description, " ")

      case Regex.run(pattern, description, capture: :all_but_first) do
        [default] -> [default: default] ++ options
        [] -> options
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
end


defmodule Docopt.Utils do
  @moduledoc """
  Common utility functions.
  """

  def parse_section(docstring, name) do
    pattern = ~r/^(?:[^\n]*)(?:#{name}:)([^\n]*\n?(?:[ \t].*?(?:\n|$))*)/imu

    case Regex.scan(pattern, docstring, capture: :all_but_first) do
      [[match] | []] -> match
      [_ | _] -> {:error, :multiple_matches}
      [] -> {:error, :no_match}
    end
  end
end
