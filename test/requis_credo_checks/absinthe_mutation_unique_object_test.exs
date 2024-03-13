defmodule RequisCredoChecks.AbsintheMutationUniqueObjectTest do
  use Credo.Test.Case, async: true

  alias RequisCredoChecks.AbsintheMutationUniqueObject

  test "rejects mutations that do not have a unique payload object" do
    """
    defmodule TestModule.BadMock do
      @moduledoc false
      use Absinthe.Schema.Notation

      object :example_mutations do
        field :ping, :string do
          resolve fn args, _ -> {:ok, "pong"} end
        end

        field :hello_world, :string do
          resolve fn args, _ -> {:ok, "Hello world!"} end
        end
      end

      object :example_queries do
      end
    end
    """
    |> to_source_file()
    |> AbsintheMutationUniqueObject.run([])
    |> assert_issues()
  end

  test "allows mutations that have a unique payload object" do
    """
    defmodule TestModule.BadMock do
      @moduledoc false
      use Absinthe.Schema.Notation

      object :ping_payload do
        field :text, :string
      end

      object :example_mutations do
        field :ping, :ping_payload do
          resolve fn args, _ -> {:ok, %{text: "pong"}} end
        end
      end

      object :example_queries do
      end
    end
    """
    |> to_source_file()
    |> AbsintheMutationUniqueObject.run([])
    |> refute_issues()
  end

  test "allows custom mutation and field suffix" do
    """
    defmodule TestModule.BadMock do
      @moduledoc false
      use Absinthe.Schema.Notation

      object :ping_payload do
        field :text, :string
      end

      object :example_mutations_test do
        field :ping, :ping_response do
          resolve fn args, _ -> {:ok, %{text: "pong"}} end
        end
      end

      object :example_queries do
      end
    end
    """
    |> to_source_file()
    |> AbsintheMutationUniqueObject.run([mutation_suffix: "_mutations_test", field_suffix: "_response"])
    |> refute_issues()
  end
end
