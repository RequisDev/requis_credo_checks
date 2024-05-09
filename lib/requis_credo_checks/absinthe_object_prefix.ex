defmodule RequisCredoChecks.AbsintheObjectPrefix do
  use Credo.Check,
    base_priority: :high,
    category: :refactor,
    param_defaults: [
      exclude_modules: []
    ],
    explanations: [
      params: [
        exclude_modules: """
        The modules that are blacklisted.

        Each module is represented by a list of atoms. A list of atoms can contain the
        whole list for a module name or a part of a module name.

        i.e. to whitelist `RequisCredoChecks.AbsintheObjectPrefix`
        the following 3 options will work:

        1. [:RequisCredoChecks, :AbsintheObjectPrefix]
        2. [:RequisCredoChecks]
        3. [:AbsintheObjectPrefix]
        """
      ]
    ]

  @moduledoc """
  Use a noun before the verb when naming objects.

  Mutations represent an action and can start with an action word that
  best describes what the mutation does for example `createUser`.

  This naming convention prefers to write names the other way around,
  for example `userCreate` over `createUser`.

  This is useful for schemas where you want to order the mutations
  alphabetically.

  For example:

  ```elixir
  defmodule Account do
    @moduledoc false
    use Absinthe.Schema.Notation

    ...

    object :account_mutations do
      field :account_create, :account_create_payload do
        ...
      end
    end
  end
  ```

  This naming convention is enforced by using the last alias of your module name.
  If your module is named `Example.Session`, all objects in that module must start
  with `session`.
  """
  @explanation [check: @moduledoc]

  @doc false
  @impl Credo.Check
  def run(source_file, params \\ []) do
    exclude_modules =
      params
      |> Params.get(:exclude_modules, __MODULE__)
      |> List.wrap()
      |> Enum.map(&List.wrap/1)

    issue_meta = IssueMeta.for(source_file, params)

    source_file
    |> Credo.Code.prewalk(&traverse(&1, &2, %{exclude_modules: exclude_modules}))
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
         %{exclude_modules: exclude_modules}
       ) do
    if Enum.any?(exclude_modules, &sublist?(module_aliases, &1)) do
      {ast, issues}
    else
      prefix = module_aliases |> List.last() |> Atom.to_string() |> Macro.underscore()

      regex = Regex.compile!("^#{prefix}")

      lines =
        contents
        |> Enum.map(fn
          {:object, meta, [name, _]} ->
            if !Regex.match?(regex, Atom.to_string(name)) do
              meta[:line]
            end

          {:input_object, meta, [name, _]} ->
            if !Regex.match?(regex, Atom.to_string(name)) do
              meta[:line]
            end

          _ ->
            nil
        end)
        |> Enum.reject(&is_nil/1)

      {ast, issues ++ lines}
    end
  end

  # Non-failing function head
  defp traverse(ast, issues, _) do
    {ast, issues}
  end

  defp issue_for(line, issue_meta) do
    format_issue(issue_meta,
      message: "object name has an invalid prefix.",
      line_no: line
    )
  end

  defp sublist?([], _), do: false
  defp sublist?([_ | t] = list, prefix), do: List.starts_with?(list, prefix) or sublist?(t, prefix)
end
