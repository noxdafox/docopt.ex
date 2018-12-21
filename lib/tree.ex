defmodule Docopt.Tree do
  @doc """
  Match the given tree with the list of arguments.
  """
  def match(tree, arguments, options) when is_list(tree) do
    case match_list(tree, arguments, options) do
      [arguments: [_ | _], options: []] -> :nomatch
      match_result -> match_result
    end
  end

  def match({:required, tree}, arguments, options) do
    case match(tree, arguments, options) do
      [arguments: args, options: opts] ->
        if length(opts) >= branch_length(tree) do
          [arguments: args, options: opts]
        else
          :nomatch
        end
      :nomatch -> :nomatch
    end
  end

  def match({:xor, tree}, arguments, options) do
    case match(tree, arguments, options) do
      [arguments: args, options: [opts]] -> [arguments: args, options: opts]
      _ -> :nomatch
    end
  end

  def match({:ellipses, tree}, arguments, options) do
    case match(tree, arguments, options) do
      [arguments: args, options: opts] when opts != [] ->
        case match({:ellipses, tree}, args, options) do
          [arguments: a, options: o] -> [arguments: a, options: opts ++ o]
          :nomatch -> [arguments: args, options: opts]
        end
      _ -> :nomatch
    end
  end

  def match(:options, arguments, options) do
    case match(:option, arguments, options) do
      [arguments: args, options: opts] ->
        case match(:options, args, options) do
          [arguments: a, options: o] -> [arguments: a, options: [o | [opts]]]
          :nomatch -> [arguments: args, options: [opts]]
        end
      _ -> :nomatch
    end
  end

  def match({:argument, leaf}, [{:literal, arg} | args], _) do
    [arguments: args, options: {leaf, arg}]
  end

  def match({:literal, leaf}, [{:literal, arg} | args], _) do
    if arg == leaf, do: [arguments: args, options: {leaf, true}], else: :nomatch
  end

  def match({:long, leaf, _}, [{:long, arg, val} | args], _) do
    if leaf =~ ~r/^#{arg}/ do
      [arguments: args, options: {leaf, val}]
    else
      :nomatch
    end
  end

  def match(:option, [{:long, arg, val} | args], options) do
    case find_option(options, :long, arg, :argument) do
      {:long, opt} -> [arguments: args, options: {opt, val}]
      nil -> :nomatch
    end
  end

  def match({:long, leaf, _}, [{:long, arg}, {:literal, val} | args], _) do
    if leaf =~ ~r/^#{arg}/ do
      [arguments: args, options: {leaf, val}]
    else
      :nomatch
    end
  end

  def match(:option, [{:long, arg}, {:literal, val} | args], options) do
    with nil <- find_option(options, :long, arg, :argument),
         {:long, opt} <- find_option(options, :long, arg)
      do
        [arguments: args, options: {opt, true}]
      else
        {:long, opt} -> [arguments: args, options: {opt, val}]
        nil -> :nomatch
    end
  end

  def match({:long, leaf}, [{:long, arg} | args], _) do
    if leaf =~ ~r/^#{arg}/ do
      [arguments: args, options: {leaf, true}]
    else
      :nomatch
    end
  end

  def match(:option, [{:long, arg} | args], options) do
    case find_option(options, :long, arg) do
      {:long, opt} -> [arguments: args, options: {opt, true}]
      nil -> :nomatch
    end
  end

  def match({:short, leaf, _}, [{:short, arg, val} | args], _) do
    if leaf =~ ~r/^#{arg}/ do
      [arguments: args, options: {leaf, val}]
    else
      :nomatch
    end
  end

  def match(:option, [{:short, arg, val} | args], options) do
    case find_option(options, :short, arg, :argument) do
      {_, opt} -> [arguments: args, options: {opt, val}]
      nil -> :nomatch
    end
  end

  def match({:short, leaf, _}, [{:short, arg}, {:literal, val} | args], _) do
    if arg == leaf, do: [arguments: args, options: {leaf, val}], else: :nomatch
  end

  def match(:option, [{:short, arg}, {:literal, val} | args], options) do
    with nil <- find_option(options, :short, arg, :argument),
         {_, opt} <- find_option(options, :short, arg)
      do
        [arguments: args, options: {opt, true}]
      else
        {_, opt} -> [arguments: args, options: {opt, val}]
        nil -> :nomatch
    end
  end

  def match({:short, leaf}, [{:short, arg} | args], _) do
    if arg == leaf, do: [arguments: args, options: {leaf, true}], else: :nomatch
  end

  def match(:option, [{:short, arg} | args], options) do
    case find_option(options, :short, arg) do
      {_, opt} -> [arguments: args, options: {opt, true}]
      nil -> :nomatch
    end
  end

  def match({:optional, tree}, arguments, options), do: match(tree, arguments, options)
  def match(_, _, _), do: :nomatch

  defp find_option(options, type, option) do
    find = fn(o) ->
      with {_, opt} <- List.keyfind(o, type, 0),
           true <- opt =~ ~r/^#{option}/,
           false <- List.keymember?(o, :argument, 0)
        do
          true
        else
          _ -> false
      end
    end

    case Enum.filter(options, find) do
      [] -> nil
      [opt] -> List.keyfind(opt, :long, 0, List.keyfind(opt, :short, 0))
      [_ | _] -> nil
    end
  end

  defp find_option(options, type, option, :argument) do
    find = fn(o) ->
      with {_, opt} <- List.keyfind(o, type, 0),
           true <- opt =~ ~r/^#{option}/,
           true <- List.keymember?(o, :argument, 0)
        do
          true
        else
          _ -> false
      end
    end

    case Enum.filter(options, find) do
      [] -> nil
      [opt] -> List.keyfind(opt, :long, 0, List.keyfind(opt, :short, 0))
      [_ | _] -> nil
    end
  end

  # Reduce a list of tree nodes returning the matching options
  defp match_list(nodes, arguments, options) do
    Enum.reduce(nodes, [arguments: arguments, options: []],
      fn(node, [arguments: arguments, options: opts]) ->
        case match(node, arguments, options) do
          [arguments: a, options: o] -> [arguments: a, options: [o | opts]]
          :nomatch -> [arguments: arguments, options: opts]
        end
      end)
  end

  # Length of a tree branch excluding optional clauses
  defp branch_length(tree) do
    tree
    |> Enum.filter(fn(e) -> case e do
                              {:optional, _} -> false
                              :ellipses -> false
                              _ -> true
                            end
                   end)
    |> length()
  end
end
