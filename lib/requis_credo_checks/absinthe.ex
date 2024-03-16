defmodule RequisCredoChecks.AbsintheHelpers do
  @moduledoc false

  @doc false
  @spec find_mutations_ast(term, String.t()) :: nil | term
  def find_mutations_ast(contents, suffix) do
    suffix = String.reverse(suffix)

    Enum.find(contents, fn
      {:object, _meta, [object_name | _]} when is_atom(object_name) ->
        object_name
        |> Atom.to_string()
        |> String.reverse()
        |> String.starts_with?(suffix)

      _ ->
        false
    end)
  end
end
