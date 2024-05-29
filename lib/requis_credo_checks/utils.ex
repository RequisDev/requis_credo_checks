defmodule RequisCredoChecks.Utils do
  @moduledoc false

  @doc false
  @spec sublist?(list(), list()) :: true | false
  def sublist?([], _), do: false
  def sublist?([_ | t] = list, prefix), do: List.starts_with?(list, prefix) or sublist?(t, prefix)

  @doc false
  @spec find_object_ast(term, String.t()) :: nil | term
  def find_object_ast(contents, suffix) do
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
