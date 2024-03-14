defmodule RequisCredoChecks.AbsintheMutationInput do
  use Credo.Check,
    base_priority: :high,
    category: :refactor

  @moduledoc """
  Use a single, required, unique, input object type as an argument for
  easier mutation execution on the client.

  Mutations should only ever have one input argument. That argument
  should be named input and should have a non-null unique input
  object type.

  The reason is that the first style is much easier to use client-side.
  The client is only required to send one variable with per mutation
  instead of one for every argument on the mutation.

  You should do nest the input object as much as possible. In GraphQL
  schema design nesting is a virtue. For no cost besides a few extra
  keystrokes, nesting allows you to fully embrace GraphQL’s power to
  be your version-less API. Nesting gives you room on your object
  types to explore new schema designs as time goes on. You can easily
  deprecate sections of the API and add new names in a conflict free
  space instead of fighting to find a new name on a cluttered
  collision-rich object type.
  """
  @explanation [check: @moduledoc]

  @check_options [:mutation_suffix]

  @doc false
  @impl Credo.Check
  def run(source_file, params \\ []) do
    {options, params} = Keyword.split(params, @check_options)

    object_suffix = Keyword.get(options, :mutation_suffix, "_mutations")

    issue_meta = IssueMeta.for(source_file, params)

    source_file
    |> Credo.Code.prewalk(&traverse(&1, &2, object_suffix))
    |> Enum.map(&issue_for(&1, issue_meta))
  end

  defp traverse(
    {
      :defmodule,
      _,
      [
        {:__aliases__, _, _module_aliases},
        [
          do: {:__block__, [], contents}
        ]
      ]
    } = ast,
    issues,
    object_suffix
  ) do
    lines =
      contents
      |> traverse_ast(object_suffix)
      |> Enum.reject(&is_nil/1)
      |> recurse_combinations()

    {ast, issues ++ lines}
  end

   # Non-failing function head
   defp traverse(ast, issues, _) do
    {ast, issues}
  end

  defp recurse_combinations(combos, lines \\ [])

  defp recurse_combinations([], lines) do
    lines
  end

  defp recurse_combinations([{_line, [{:arg, :input, :non_null}]} | tail], lines) do
    recurse_combinations(tail, lines)
  end

  defp recurse_combinations([{line, _} | tail], lines) do
    recurse_combinations(tail, [line | lines])
  end

  defp traverse_ast(contents, object_suffix) do
    case find_mutations_ast(contents, object_suffix) do
      nil ->
        []

      {:object, _meta, [_object_name, [{:do, {:__block__, _, mutation_contents}}]]} ->
        traverse_field_ast(mutation_contents)

      {:object, _meta, [_object_name, [{:do, mutation_content}]]} ->
        traverse_field_ast([mutation_content])

    end
  end

  defp traverse_field_ast(mutation_contents) do
    Enum.map(mutation_contents, fn
      {:field, meta, [_field_name, _field_type, [{:do, {:__block__, _, contents}}]]} ->
        args =
          contents
          |> Enum.reduce([], fn
            {:arg, _meta, [arg_name, {:non_null, _, _}]}, acc ->
              [{:arg, arg_name, :non_null} | acc]

            {:arg, _meta, [arg_name, _]}, acc ->
              [{:arg, arg_name, nil} | acc]

            _, acc ->
              acc

          end)
          |> :lists.reverse()

        {meta[:line], args}

      _ ->
        nil

    end)
  end

  defp find_mutations_ast(contents, suffix) do
    suffix = String.reverse(suffix)

    Enum.find(contents, fn
      {:object, _meta, [object_name | _]} when is_atom(object_name) ->
        object_name
        |> Atom.to_string()
        |> String.reverse()
        |> String.starts_with?(suffix)

      _ -> false
    end)
  end

  defp issue_for(line, issue_meta) do
    format_issue(issue_meta,
      message: "mutation must have only one non-null input object named 'input'.",
      line_no: line
    )
  end
end
