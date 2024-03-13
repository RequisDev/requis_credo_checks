defmodule RequisCredoChecks.AbsintheObjectPrefixMatchesModuleTest do
  use Credo.Test.Case, async: true

  alias RequisCredoChecks.AbsintheObjectPrefixMatchesModule

  test "rejects object names that are not prefixed by module" do
    """
    defmodule TestModule.BadMock do
      @moduledoc false
      use Absinthe.Schema.Notation

      object :another_payload do
        field :age, :integer
      end

      object :some_echo_payload do
        field :name, :string
        field :message, :string
      end

      input_object :some_echo_input do
        field :message, non_null(:string)
      end

      input_object :test_input do
        field :message, non_null(:string)
      end

      object :some_mutations do
        field :some_echo, :some_echo_payload do
          arg :input, non_null(:some_echo_input)

          resolve fn args, _ -> {:ok, %{message: args.input.message}} end
        end

        field :test, :string do
          arg :input, non_null(:test_input)

          resolve fn args, _ -> {:ok, args.input.message} end
        end
      end

      object :some_queries do
        field :another, :another_payload do
          resolve fn _, _ -> {:ok, %{age: 1}} end
        end
      end
    end
    """
    |> to_source_file()
    |> AbsintheObjectPrefixMatchesModule.run([])
    |> assert_issues()
  end

  test "allows objects prefixed by module" do
    """
    defmodule TestModule.Mock do
      @moduledoc false
      use Absinthe.Schema.Notation

      object :mock_payload do
        field :age, :integer
      end

      object :mock_echo_payload do
        field :name, :string
        field :message, :string
      end

      input_object :mock_echo_input do
        field :message, non_null(:string)
      end

      input_object :mock_input do
        field :message, non_null(:string)
      end

      object :mock_mutations do
        field :mock_echo, :mock_echo_payload do
          arg :input, non_null(:mock_echo_input)

          resolve fn args, _ -> {:ok, %{message: args.input.message}} end
        end

        field :mock, :string do
          arg :input, non_null(:mock_input)

          resolve fn args, _ -> {:ok, args.input.message} end
        end
      end

      object :mock_queries do
        field :mock, :mock_payload do
          resolve fn _, _ -> {:ok, %{age: 1}} end
        end
      end
    end
    """
    |> to_source_file()
    |> AbsintheObjectPrefixMatchesModule.run([])
    |> refute_issues()
  end
end
