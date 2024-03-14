defmodule RequisCredoChecks.AbsintheMutationInputTest do
  use Credo.Test.Case, async: true

  alias RequisCredoChecks.AbsintheMutationInput

  test "rejects mutations that do not have a unique payload object" do
    """
    defmodule TestModule.BadMock do
      @moduledoc false
      use Absinthe.Schema.Notation

      input_object :example_input do
        field :message, non_null(:string)
      end

      input_object :another_example_input do
        field :number, :integer
      end

      object :example_mutations do
        field :has_multiple_inputs, :string do
          arg :input, non_null(:example_input)
          arg :another_input, :another_example_input

          resolve fn args, _ -> {:ok, args.input.message} end
        end

        field :should_be_non_null, :string do
          arg :input, :example_input

          resolve fn args, _ -> {:ok, args.input.message} end
        end

        field :bad_name, :string do
          arg :incorrect_name, non_null(:example_input)

          resolve fn args, _ -> {:ok, args.input.message} end
        end
      end

      object :example_queries do
      end
    end
    """
    |> to_source_file()
    |> AbsintheMutationInput.run([])
    |> assert_issues()
  end

  test "allows objects prefixed by module" do
    """
    defmodule TestModule.Mock do
      @moduledoc false
      use Absinthe.Schema.Notation

      object :echo_payload do
        field :text, :string
      end

      input_object :echo_input do
        field :text, non_null(:string)
      end

      object :mock_mutations do
        field :echo, :ectho_payload do
          arg :input, non_null(:echo_input)

          resolve fn args, _ -> {:ok, args.input.text} end
        end
      end

      object :mock_queries do
      end
    end
    """
    |> to_source_file()
    |> AbsintheMutationInput.run([])
    |> refute_issues()
  end

  test "can set custom mutation suffix" do
    """
    defmodule TestModule.Mock do
      @moduledoc false
      use Absinthe.Schema.Notation

      object :echo_payload do
        field :text, :string
      end

      input_object :echo_input do
        field :text, non_null(:string)
      end

      object :mock_mutations_test do
        field :echo, :ectho_payload do
          arg :input, non_null(:echo_input)

          resolve fn args, _ -> {:ok, args.input.text} end
        end
      end

      object :mock_queries do
      end
    end
    """
    |> to_source_file()
    |> AbsintheMutationInput.run([mutation_suffix: "_mutations_test"])
    |> refute_issues()
  end
end
