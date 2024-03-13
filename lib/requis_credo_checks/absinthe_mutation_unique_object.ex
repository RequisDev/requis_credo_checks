defmodule RequisCredoChecks.AbsintheMutationUniqueObject do
  use Credo.Check,
    base_priority: :high,
    category: :refactor

  @moduledoc """
  Always create a custom object type for each of your mutations and then add any output
  you want as a field of that custom object type. This will allow you to add multiple
  outputs over time and metadata fields like clientMutationId or userErrors.

  Even if you only want to return a single thing from your mutation, resist the
  temptation to return that one type directly. It is hard to predict the future,
  and if you choose to return only a single type now you remove the future possibility
  to add other return types or metadata to the mutation. Preemptively removing design
  space is not something you want to do when designing a versionless GraphQL API.

  Instead of this:

  ```elixir
  object :example_mutations do
    field :ping, :string do
      resolve fn args, _ -> {:ok, "pong"} end
    end
  end
  ```

  You should do this:

  ```elixir
  object :example_mutations do
    field :ping, :ping_payload do
      resolve fn args, _ -> {:ok, %{text: "pong"}} end
    end
  end
  ```
  """
  @explanation [check: @moduledoc]

  @check_params [:mutation_suffix, :field_suffix]

  @doc false
  @impl Credo.Check
  def run(source_file, params \\ []) do
    {options, params} = Keyword.split(params, @check_params)

    object_suffix = Keyword.get(options, :mutation_suffix, "_mutations")
    field_suffix = Keyword.get(options, :field_suffix, "_payload")

    issue_meta = IssueMeta.for(source_file, params)

    source_file
    |> Credo.Code.prewalk(&traverse(&1, &2, object_suffix, field_suffix))
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
    object_suffix,
    field_suffix
  ) do
    lines =
      contents
      |> traverse_mutations_fields_ast(object_suffix, field_suffix)
      |> Enum.reject(&is_nil/1)

    {ast, issues ++ lines}
  end

  # Non-failing function head
  defp traverse(ast, issues, _, _) do
    {ast, issues}
  end

  defp traverse_mutations_fields_ast(contents, object_suffix, field_suffix) do
    case find_mutations_ast(contents, object_suffix) do
      nil ->
        []

      {:object, _meta, [_object_name, [{:do, {:__block__, _, mutation_fields_ast}}]]} ->
        traverse_fields_ast(mutation_fields_ast, field_suffix)

      {:object, _meta, [_object_name, [{:do, mutation_field_ast}]]} ->
        traverse_fields_ast([mutation_field_ast], field_suffix)

    end
  end

  defp traverse_fields_ast(mutation_fields_ast, field_suffix) do
    Enum.map(mutation_fields_ast, fn
      {:field, meta, [field_name, field_type, _]} ->
        field_name = Atom.to_string(field_name)
        field_type = Atom.to_string(field_type)

        if field_type !== (field_name <> field_suffix) do
          meta[:line]
        end
    end)
  end

  defp find_mutations_ast(contents, suffix) do
    Enum.find(contents, fn
      {:object, _meta, [object_name | _]} when is_atom(object_name) ->
        Atom.to_string(object_name) =~ suffix

      _ -> false
    end)
  end

  defp issue_for(line, issue_meta) do
    format_issue(issue_meta,
      message: "mutation must return a unique object.",
      line_no: line
    )
  end
end
