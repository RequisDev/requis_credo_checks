defmodule RequisCredoChecks.AbsintheObjectNamePrefix do
  use Credo.Check,
    base_priority: :high,
    category: :readability

  @issue_message "names must be prefixed by the module name"
  @moduledoc """
  Prefix your object names with the module's suffix name

  This can increase readability by
  a.) Organizing similar objects into one module
  b.) Grouping similar objects together by the same prefix which makes your graphql api easier to navigate.
  """
  @explanation [check: @moduledoc]

  @doc false
  @impl Credo.Check
  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    source_file
    |> Credo.Code.prewalk(&traverse/2)
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
    issues
  ) do
    prefix = module_aliases |> List.last() |> Atom.to_string() |> Macro.underscore()
    regex = Regex.compile!("^#{prefix}_")

    lines =
      contents
      |> Enum.map(fn
        {:object, meta, [name, _]} ->
          if !Regex.match?(regex, Atom.to_string(name)) do
            {:object, meta[:line]}
          end

        {:input_object, meta, [name, _]} ->
          if !Regex.match?(regex, Atom.to_string(name)) do
            {:input_object, meta[:line]}
          end

        _ -> nil
      end)
      |> Enum.reject(&is_nil/1)
      |> recurse_combinations()

    {ast, issues ++ lines}
  end

  # Non-failing function head
  defp traverse(ast, issues) do
    {ast, issues}
  end

  defp recurse_combinations(combos, lines \\ [])

  defp recurse_combinations([], lines) do
    lines
  end

  defp recurse_combinations([{:object, line} | tail], lines) do
    recurse_combinations(tail, [line | lines])
  end

  defp recurse_combinations([{:input_object, line} | tail], lines) do
    recurse_combinations(tail, [line | lines])
  end

  defp issue_for(line, issue_meta) do
    format_issue(issue_meta,
      message: @issue_message,
      line_no: line
    )
  end
end
