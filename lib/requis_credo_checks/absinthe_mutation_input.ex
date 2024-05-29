defmodule RequisCredoChecks.AbsintheMutationInput do
  use Credo.Check,
    base_priority: :high,
    category: :refactor,
    param_defaults: [
      exclude_mutations: [],
      mutation_suffix: "_mutations"
    ],
    explanations: [
      params: [
        exclude_mutations: """
        The mutations to skip.

        Each entry must be a tuple of `{module, mutations}`.

        The `module` argument must be a list of atoms. A list of atoms can contain the whole
        list for a module name or a part of a module name.

        i.e. to whitelist `RequisCredoChecks.AbsintheObjectPrefix`
        the following 3 options will work:

        1. [:RequisCredoChecks, :AbsintheObjectPrefix]
        2. [:RequisCredoChecks]
        3. [:AbsintheObjectPrefix]

        The `mutations` argument must be a list of atoms where each atom is the module name.
        """,
        mutation_suffix: "The suffix of the root mutation object name."
      ]
    ]

  alias RequisCredoChecks.Utils

  @moduledoc """
  Use a single, required, unique, input object type as an argument for
  easier mutation execution on the client.

  Mutations should only ever have one input argument. That argument
  should be named input and should have a non-null unique input
  object type.

  The reason is that the first style is much easier to use client-side.
  The client is only required to send one variable per mutation instead
  of one for every argument on the mutation.

  You should nest the input object as much as possible. In GraphQL
  schema design nesting is a virtue. For no cost besides a few extra
  keystrokes, nesting allows you to fully embrace GraphQL’s power to
  be your version-less API. Nesting gives you room on your object
  types to explore new schema designs as time goes on. You can easily
  deprecate sections of the API and add new names in a conflict free
  space instead of fighting to find a new name on a cluttered
  collision-rich object type.

  For account:

  ```elixir
  defmodule Account do
    @moduledoc false
    use Absinthe.Schema.Notation

    input_object :user_create_input do
      field :timezone, non_null(:string)
    end

    input_object :account_create_input do
      field :email, non_null(:string)
      field :user, non_null(:user_create_input)
    end

    object :account do
      field :email, :string
    end

    object :account_create_payload do
      field :account, :account
    end

    object :account_mutations do
      field :account_create, :account_create_payload do
        arg :input, non_null(:account_create_input)

        resolve fn %{input: input}, _resolution ->
          with {:ok, account} <- Accounts.create_account(input) do
            {:ok, %{account: account}}
          end
        end
      end
    end
  end
  ```
  """
  @explanation [check: @moduledoc]

  @doc false
  @impl Credo.Check
  def run(source_file, params \\ []) do
    object_suffix = Params.get(params, :mutation_suffix, __MODULE__)
    exclude_mutations = Params.get(params, :exclude_mutations, __MODULE__)

    issue_meta = IssueMeta.for(source_file, params)

    context = %{
      object_suffix: object_suffix,
      exclude_mutations: exclude_mutations
    }

    source_file
    |> Credo.Code.prewalk(&traverse(&1, &2, context))
    |> Enum.map(&issue_for(&1, issue_meta))
  end

  defp traverse(
         {
           :defmodule,
           _,
           [
             {:__aliases__, _, module_aliases},
             [
               do: {:__block__, [], contents}
             ]
           ]
         } = ast,
         issues,
         %{
           object_suffix: object_suffix,
           exclude_mutations: exclude_mutations
         }
       ) do
    exclude_mutations =
      if value =
           Enum.find(exclude_mutations, fn {module, _} ->
             Utils.sublist?(module_aliases, module)
           end) do
        elem(value, 1)
      else
        []
      end

    lines =
      contents
      |> traverse_ast(object_suffix, exclude_mutations)
      |> Enum.reject(&is_nil/1)
      |> recurse_combinations()

    {ast, issues ++ lines}
  end

  # Non-failing function head
  defp traverse(ast, issues, _) do
    {ast, issues}
  end

  defp traverse_ast(contents, object_suffix, exclude_mutations) do
    case Utils.find_object_ast(contents, object_suffix) do
      nil ->
        []

      {:object, _meta, [_object_name, [{:do, {:__block__, _, mutation_contents}}]]} ->
        traverse_mutation_ast(mutation_contents, exclude_mutations)

      {:object, _meta, [_object_name, [{:do, mutation_content}]]} ->
        traverse_mutation_ast([mutation_content], exclude_mutations)
    end
  end

  defp traverse_mutation_ast(mutation_contents, exclude_mutations) do
    Enum.map(mutation_contents, fn
      {:field, meta, [field_name, _field_type, [{:do, {:__block__, _, contents}}]]} ->
        if Enum.member?(exclude_mutations, field_name) === false do
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
        end

      _ ->
        nil
    end)
  end

  defp recurse_combinations(combos, lines \\ [])

  defp recurse_combinations([], lines), do: lines

  defp recurse_combinations([{_line, [{:arg, :input, :non_null}]} | tail], lines) do
    recurse_combinations(tail, lines)
  end

  defp recurse_combinations([{line, _} | tail], lines) do
    recurse_combinations(tail, [line | lines])
  end

  defp issue_for(line, issue_meta) do
    format_issue(issue_meta,
      message: "mutation must have only one non-null input object named 'input'.",
      line_no: line
    )
  end
end
