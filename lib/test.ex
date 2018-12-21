defmodule Asd do
  def parse_tokens(tokens) do
    parse_tokens(tokens, [])
  end

  def parse_tokens([], tree) do
    [tokens: [], tree: tree]
  end

  def parse_tokens([head | tokens], tree) do
    case parse_token(head) do
      :required -> [tokens: tokens, tree: sub_tree] = parse_tokens(tokens, [])
                   parse_tokens(tokens, [{:required, sub_tree} | tree])
      :optional -> [tokens: tokens, tree: sub_tree] = parse_tokens(tokens, [])
                   parse_tokens(tokens, [{:optional, sub_tree} | tree])
      :xor -> parse_tokens(tokens, [:xor | tree])
      :ellipses -> parse_tokens(tokens, [:ellipses | tree])
      :options -> parse_tokens(tokens, [:options | tree])
      {:long, option} -> parse_tokens(tokens, [{:long, option} | tree])
      {:shorts, options} -> parse_tokens(tokens, [options | tree])
      {:argument, token} -> parse_tokens(tokens, [{:argument, token} | tree])
      :close -> [tokens: tokens, tree: tree]
    end
  end

  defp parse_token(token) do
    cond do
      token == "(" -> :required
      token == "[" -> :optional
      token == ")" or token == "]" -> :close
      token == "|" -> :xor
      token == "..." -> :ellipses
      token == "options" -> :options
      String.starts_with?(token, "--") -> {:long, parse_long_option(token)}
      String.starts_with?(token, "-") -> {:shorts, parse_short_options(token)}
      String.match?(token, ~r/[A-Z]+|<.*>/) -> {:argument, token}
      true -> token
    end
  end

  defp parse_long_option(token) do
    ~r/(--[^= ]+)=(<[^<>]*>|\S+)|(--[^= ]+)/
    |> Regex.run(token, capture: :all_but_first)
    |> Enum.filter(& byte_size(&1) > 0)
  end

  defp parse_short_options(token) do
    [options | argument] = ~r/^(?:-)([^-= A-Z]+) {0,1}([A-Z]+)*/
    |> Regex.run(token, capture: :all_but_first)
    |> Enum.filter(& byte_size(&1) > 0)

    shorts = options
      |> String.split("", trim: true)
      |> Enum.map(fn(c) -> {:short, "-" <> c} end)
      |> Enum.reverse()

    case argument do
      [] -> shorts
      [arg] -> [{:short, option} | tail] = shorts
               [{:short, [option, arg]} | tail]
    end
  end
end
