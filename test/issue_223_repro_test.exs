defmodule AshGraphql.Issue223ReproTest do
  @moduledoc """
  Reproduces the warning from GitHub issue #223 locally.

  Run (from repo root):

      mix test test/issue_223_repro_test.exs

  """

  # Hook test into the ExUnit (Elixir's built-in testing framework) system.
  use ExUnit.Case, async: true # Async: true means the test can run in parallel with other tests. Safe as this doesn't interact with db or external sources.
  import ExUnit.CaptureIO # Import the ExUnit.CaptureIO module to capture the output of the test. This allows us to assert the output of the test.

  # Defines test case.
  test "empty embedded type used as GraphQL input emits warning on stderr" do
    attribute = Ash.Resource.Info.attribute(AshGraphql.Test.Issue223EmptyParent, :empty_value) # Looks up the :empty_value attribute on the Issue223EmptyParent resource. Resource.info.attribute tell's Ash to give us the full attribute struct/definition.
    
    # Captures the output of the test in variable called stderr.
    stderr =
      capture_io(:stderr, fn ->
        _ = # Ignore return value of function call, we only want the warning text.
          AshGraphql.Resource.field_type( # IO.warn in resource.ex triggers warning to be printed to stderr. Called using field_type library.
            attribute.type,
            attribute,
            AshGraphql.Test.Issue223EmptyParent, # Call resource that owns this attribute into scope so we can retrieve the type.
            true # 'true' Tells Ash we are building this for GraphQL input
          )
      end)
      
    IO.puts(stderr)

    assert stderr =~ "Embedded type"
    assert stderr =~ "cannot define a GraphQL input type"
    assert stderr =~ "no input fields were produced"
    assert stderr =~ "accept lists"
    assert stderr =~ "Application.get_env(:ash_graphql, :json_type)"
  end
end
