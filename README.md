# RequisCredoChecks

A set of custom checks used by the Requis Elixir team on top of the excellent ones included with Credo. We use these checks to catch errors, improve code quality, maintain consistency, and shorten pull request review times.

Check the moduledocs inside the check modules themselves for details on the individual checks.

## Getting Started

### 1. Add dependencies

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `requis_credo_checks` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
    {:requis_credo_checks, "~> 0.1", only: [:dev, :test], runtime: false}
  ]
end
```

### 2. Create configuration file
If you do not have one already in the root of your project, a default Credo configuration file .credo.exs can be generated with

```elixir
mix credo.gen.config
```

### 3. Add these checks
Add some or all of these checks under the checks key in .credo.exs

```elixir
  checks: [
    # Custom checks
    {RequisCredoChecks.AbsintheObjectName, []},
    {RequisCredoChecks.AbsintheMutationUniqueObject, []},
    {RequisCredoChecks.AbsintheMutationInput, []},
    
    # ... all the other checks that come with Credo
  ]
```

### 4. Run Credo

```elixir
mix credo
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/requis_credo_checks>.

