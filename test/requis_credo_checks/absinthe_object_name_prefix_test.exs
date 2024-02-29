defmodule RequisCredoChecks.AbsintheObjectNamePrefixTest do
  use Credo.Test.Case, async: true

  alias RequisCredoChecks.AbsintheObjectNamePrefix

  test "rejects object names that are not prefixed by module" do
    """
    defmodule CredoSampleModule.BadMockName do
      @moduledoc false
      use Absinthe.Schema.Notation

      object :another_name_payload do
        field :age, :integer
      end

      object :some_name_echo_payload do
        field :name, :string
        field :message, :string
      end

      input_object :some_name_echo_input do
        field :message, non_null(:string)
      end

      input_object :test_input do
        field :message, non_null(:string)
      end

      object :some_name_mutations do
        field :some_name_echo, :some_name_echo_payload do
          arg :input, non_null(:some_name_echo_input)

          resolve fn args, _ -> {:ok, %{message: args.input.message}} end
        end

        field :test, :string do
          arg :input, non_null(:test_input)

          resolve fn args, _ -> {:ok, args.input.message} end
        end
      end

      object :some_name_queries do
        field :another_name, :another_name_payload do
          resolve fn _, _ -> {:ok, %{age: 1}} end
        end
      end
    end
    """
    |> to_source_file()
    |> AbsintheObjectNamePrefix.run([])
    |> assert_issues()
  end

  test "allows objects prefixed by module" do
    """
    defmodule CredoSampleModule.MockName do
      @moduledoc false
      use Absinthe.Schema.Notation

      object :mock_name_payload do
        field :age, :integer
      end

      object :mock_name_echo_payload do
        field :name, :string
        field :message, :string
      end

      input_object :mock_name_echo_input do
        field :message, non_null(:string)
      end

      input_object :mock_name_input do
        field :message, non_null(:string)
      end

      object :mock_name_mutations do
        field :mock_name_echo, :mock_name_echo_payload do
          arg :input, non_null(:mock_name_echo_input)

          resolve fn args, _ -> {:ok, %{message: args.input.message}} end
        end

        field :mock_name, :string do
          arg :input, non_null(:mock_name_input)

          resolve fn args, _ -> {:ok, args.input.message} end
        end
      end

      object :mock_name_queries do
        field :mock_name, :mock_name_payload do
          resolve fn _, _ -> {:ok, %{age: 1}} end
        end
      end
    end
    """
    |> to_source_file()
    |> AbsintheObjectNamePrefix.run([])
    |> refute_issues()
  end
end
