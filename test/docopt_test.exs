defmodule DocoptTest do
  require Jason
  use ExUnit.Case

  doctest Docopt

  @docstring_regex ~r/(?:^""")(.*?)(?:""")/ms
  @arguments_regex ~r/(?:\$ prog[ ]{0,1})(.*)/
  @results_regex ~r/(\{(.*?)\}|("user-error"))/s

  test "Docopt Test Cases" do
    {:ok, data} = File.read("test/testcases.docopt")

    test_cases =
      data
      |> String.split(~r/^r/m, trim: true)
      |> Enum.map(&parse_test_case/1)

    for [docstring: docstring, tests: tests] <- test_cases do
      [options: options, tree: tree] = Docopt.parse_docstring(docstring)

      IO.puts("Docstring")
      IO.inspect(docstring)

      IO.puts("Tree")
      IO.inspect(tree)

      for {arguments, result} <- tests do
        IO.puts("Arguments")
        IO.inspect(arguments)

        case Docopt.match_arguments(arguments, tree, options) do
          :nomatch -> assert result == "user-error"
          output -> assert output == result
        end
      end
    end
  end

  defp parse_test_case(string) do
    [docstring] = Regex.run(@docstring_regex, string, capture: :all_but_first)
    arguments = @arguments_regex
      |> Regex.scan(string, capture: :all_but_first)
      |> List.flatten()
    results = @results_regex
      |> Regex.scan(string, capture: :first)
      |> Enum.map(fn(r) -> Jason.decode!(r) end)

    [docstring: docstring, tests: Enum.zip(arguments, results)]
  end
end
