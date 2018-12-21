defmodule Docopt.Tokenizer do
  @doc """
  Parse a list of tokens returning a matching tree
  """
  def parse(tokens, options) do
    [tree: tree, stack: [], options: _] = Enum.reduce(
      tokens, [tree: [], stack: [], options: options], &parse_tokens/2)

    case tree do
      # Usage tree
      [required: tree] -> {:required, tree}
      [xor: tree] -> {:required, [xor: tree]}
      # Argument tree
      tree ->
        literals = fn(n) ->
            case n, do: ({:argument, a} -> {:literal, a}; _ -> n;) end

        Enum.map(tree, literals) |> Enum.reverse()
    end
  end

  # Reduce function constructing the match tree
  defp parse_tokens(token, accumulator) do
    [tree: tree, stack: stack, options: options] = accumulator

    case parse_token(token, options) do
      :required -> [tree: [:required], stack: [tree | stack], options: options]
      :optional -> [tree: [:optional], stack: [tree | stack], options: options]
      {:close, type} -> close_group(type, accumulator)
      :ellipses ->
        [head | tree] = tree
        [tree: [{:ellipses, [head]} | tree], stack: stack, options: options]
      {:long, option} -> [tree: [option | tree], stack: stack, options: options]
      {:shorts, opts} -> [tree: opts ++ tree, stack: stack, options: options]
      {:literal, lit} -> maybe_ambiguous_option({:literal, lit}, accumulator)
      {:argument, arg} -> maybe_ambiguous_option({:argument, arg}, accumulator)
      symbol when symbol in [:options, :separator, :input, :xor] ->
        [tree: [symbol | tree], stack: stack, options: options]
    end
  end

  # Parse a single token returning an atom or a tuple {:atom, _}
  defp parse_token(token, options) do
    cond do
      token == "(" -> :required
      token == "[" -> :optional
      token == ")" -> {:close, :required}
      token == "]" -> {:close, :optional}
      token == "|" -> :xor
      token == "..." -> :ellipses
      token == "options" -> :options
      token == "--" -> :separator
      token == "-" -> :input
      String.starts_with?(token, "--") -> {:long, parse_long(token)}
      String.starts_with?(token, "-") -> {:shorts, parse_shorts(token, options)}
      String.match?(token, ~r/^[A-Z]+$|^<.*>$/) -> {:argument, token}
      true -> {:literal, token}
    end
  end

  # Parse a single long option
  defp parse_long(token) do
    option = ~r/(--[^= ]+)=(<[^<>]*>|\S+)|(--[^= ]+)/
      |> Regex.run(token, capture: :all_but_first)
      |> Enum.filter(& byte_size(&1) > 0)

    case option do
      [option] -> {:long, option}
      [option, argument] -> {:long, option, argument}
    end
  end

  # Parse one or more short options grouped together
  defp parse_shorts(token, options) when is_bitstring(token) do
    [_dash | charlist] = String.split(token, "", trim: true)
    parse_shorts(charlist, options)
  end

  defp parse_shorts([char | chars], options) do
    if has_argument?("-" <> char, options) and chars != [] do
      [{:short, "-" <> char, List.to_string(chars)}]
    else
      [{:short, "-" <> char} | parse_shorts(chars, options)]
    end
  end

  defp parse_shorts([], _), do: []

  # Check if the given argument/literal is the argument of the previous option
  defp maybe_ambiguous_option({type, arg}, accumulator)
      when type in [:literal, :argument] do
    [tree: tree, stack: stack, options: opts] = accumulator

    with {atom, option} when atom in [:long, :short] <- List.first(tree),
         true <- has_argument?(option, opts)
      do
        [tree: [{atom, option, arg} | tl(tree)], stack: stack, options: opts]
      else
        _ -> [tree: [{type, arg} | tree], stack: stack, options: opts]
    end
  end

  # A required or optional group has been closed
  defp close_group(type, accumulator) do
    [tree: tree, stack: stack, options: opts] = accumulator
    {^type, patterns} = List.pop_at(tree, -1)
    [tree | stack] = stack
    pattern = type |> group_xors(patterns) |> group_options(patterns)

    [tree: [pattern | tree], stack: stack, options: opts]
  end

  # [1, :xor, 2, 3, :xor, 4] -> {:xor, [[1], [2, 3], [4]]}
  defp group_xors(type, tree) do
    chunk_fun = fn(element, accumulator) ->
      case element do
        :xor -> {:cont, {type, Enum.reverse(accumulator)}, []}
        _ -> {:cont, [element | accumulator]}
      end
    end

    after_fun = fn(accumulator) ->
      case accumulator do
        [] -> {:cont, []}
        accumulator -> {:cont, {type, Enum.reverse(accumulator)}, []}
      end
    end

    if Enum.find(tree, fn e -> e == :xor end) do
      {:xor, Enum.chunk_while(tree, [], chunk_fun, after_fun)}
    else
      {type, tree}
    end
  end

  # [{:long, "--foo"}, {:short, "-b"}] -> {:options, [{:long, "--foo"}, {:short, "-b"}]}
  defp group_options(type, tree) do
    chunk_fun = fn(element, accumulator) ->
      case element do
        :xor -> {:cont, {type, Enum.reverse(accumulator)}, []}
        _ -> {:cont, [element | accumulator]}
      end
    end

    after_fun = fn(accumulator) ->
      case accumulator do
        [] -> {:cont, []}
        accumulator -> {:cont, {type, Enum.reverse(accumulator)}, []}
      end
    end

    if Enum.find(tree, fn e -> e == :xor end) do
      {:xor, tree |> Enum.chunk_while([], chunk_fun, after_fun)}
    else
      {type, tree}
    end
  end

  # True if the given option requires an argument
  defp has_argument?(option, options) do
    Enum.find(options, [], fn(list) -> List.keyfind(list, option, 1) end)
      |> List.keymember?(:argument, 0)
  end
end
