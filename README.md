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

## Contributing

We welcome contributions to this library. Bear in mind however that new checks can be very controversial as they have a large impact on developer experience. We therefore recommend that you open an issue to discuss a new check before beginning work on a new one.

### Getting set up locally

1. Consider opening an issue for discussion
2. Fork and clone this repository on GitHub
3. Install elixir and erlang versions with asdf

```
asdf install
```

4. Fetch dependencies

```
mix deps.get
```

5. Run the test suite

```
mix check
```

6. Use your work in another project

It is an excellent idea to not just write tests, but to also run your check against another codebase.

Include your cloned project under deps in the mix.exs of your other codebase

```
{:requis_credo_checks, path: "../requis_credo_checks/"}
```

And fetch your dependencies to pull in the local version you are working on

```
mix deps.get
```

