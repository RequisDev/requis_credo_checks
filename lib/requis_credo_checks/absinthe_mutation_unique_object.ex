defmodule RequisCredoChecks.AbsintheMutationUniqueObject do
  use Credo.Check,
    base_priority: :high,
    category: :refactor

  alias RequisCredoChecks.AbsintheHelpers

  @moduledoc """
  Use a unique payload type for each mutation and add the mutation’s output
  as a field to that payload type.

  Always create a custom object type for each of your mutations and then
  add any output you want as a field of that custom object type. This will
  allow you to add multiple outputs over time and metadata fields.

  Even if you only want to return a single thing from your mutation, resist
  the temptation to return that one type directly. It is hard to predict
  the future, and if you choose to return only a single type now you remove
  the future possibility to add other return types or metadata to the
  mutation. Preemptively removing design space is not something you want to
  do when designing a versionless GraphQL API.

  For example:

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

  @check_options [:mutation_suffix, :field_suffix]

  @doc false
  @impl Credo.Check
  def run(source_file, params \\ []) do
    {options, params} = Keyword.split(params, @check_options)

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
      |> traverse_ast(object_suffix, field_suffix)
      |> Enum.reject(&is_nil/1)

    {ast, issues ++ lines}
  end

  # Non-failing function head
  defp traverse(ast, issues, _, _) do
    {ast, issues}
  end

  defp traverse_ast(contents, object_suffix, field_suffix) do
    case AbsintheHelpers.find_mutations_ast(contents, object_suffix) do
      nil ->
        []

      {:object, _meta, [_object_name, [{:do, {:__block__, _, mutation_contents}}]]} ->
        traverse_field_ast(mutation_contents, field_suffix)

      {:object, _meta, [_object_name, [{:do, mutation_content}]]} ->
        traverse_field_ast([mutation_content], field_suffix)
    end
  end

  defp traverse_field_ast(mutation_contents, field_suffix) do
    Enum.map(mutation_contents, fn
      {:field, meta, [field_name, field_type, _]} when is_atom(field_type) ->
        field_name = Atom.to_string(field_name)
        field_type = Atom.to_string(field_type)

        if field_type !== field_name <> field_suffix do
          meta[:line]
        end

      {:field, meta, _} ->
        meta[:line]

      _ ->
        nil
    end)
  end

  defp issue_for(line, issue_meta) do
    format_issue(issue_meta,
      message: "mutation must return a unique object.",
      line_no: line
    )
  end
end
