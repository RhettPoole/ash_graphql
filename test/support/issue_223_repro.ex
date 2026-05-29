# Manual repro for GitHub issue #223: empty embedded GraphQL input triggers IO.warn. Meant for testing only, not meant for the library for users to install.

# Start Issue223EmptyEmbed (embedded resource with no real inputs.)
defmodule AshGraphql.Test.Issue223EmptyEmbed do
  @moduledoc false # Prevent docs from being generated for this module.

  use Ash.Resource, # Use Ash.Resource to build a new resource (Ash.Resource is a template).
    data_layer: :embedded, # This resource will live in another resource (not a database table) that matches union subtypes that are embedded types.
    extensions: [AshGraphql.Resource] # Hook the resource up to ash_graphql so GraphQL types can be generated for it.

  # Below tells GraphQL that when this shows up in the API, it should call it issue223_empty_embed, without it ash_graphql wouldn't treat this as a GraphQL type.
  graphql do
    type(:issue223_empty_embed) 
  end

  # Below defines what we can do with this resource.
  actions do
    create :create do 
      primary?(true) # Marks this as the main create action ash_graphql should use when building input types.
      # --- This accept line is the key test case for issue #223, empty accept is a requirement for error to be triggered. ---
      accept([]) # Accepts no inputs, so no input fields are produced.
    end

    update :update do
      primary?(true)
      accept([]) # Same story for update: primary update action, but nothing accepted. Create and update both contribute fields when ash_graphql builds input types; both are empty here.
    end
  end

  # Starts the list of fields this resource has, even if they are not accepted as input.
  attributes do
    attribute :type, :atom do
      public?(true) # Can show up in API's / GraphQL in general.
      writable?(false) # Clients aren't allowed to set it on create/update.
      constraints(one_of: [:issue223_empty_embed]) # This is the only allowed value, cannot be changed. This is not a user-fillable input field.
    end
  end
end

# Starts parent resource that reference the empty embed resource. This is what forces ash_graphql to think about the embed as input.
defmodule AshGraphql.Test.Issue223EmptyParent do
  @moduledoc false

  use Ash.Resource,
    domain: AshGraphql.Test.SimpleDomain, # Belongs to test domain 'SimpleDomain', listed in simple_domain.ex.
    data_layer: Ash.DataLayer.Ets, # Use Erlang Term Storage (ETS), for in-memory testing instead of connecting to a database.
    extensions: [AshGraphql.Resource]

  graphql do
    type(:issue223_empty_parent) # GraphQL type name for this resource.
  end

  actions do
    default_accept(:*) # Accepts all inputs, so ash_graphql will build input types for all actions.
    defaults([:read]) # Adds standard read action, don't need create/update on the parent for this tests, the test only needs the parent to exist and have na attribute pointing at the embed resource (our test case.)
  end

  attributes do
    uuid_primary_key(:id) # Primary key for the parent resource.

    # A field whose type is our empty embed module. This is the link: “this parent has a nested empty embed.” When GraphQL builds input types and walks this attribute with input?: true, it hits Issue223EmptyEmbed and triggers the warning path.
    attribute :empty_value, AshGraphql.Test.Issue223EmptyEmbed do
      public?(true)
    end
  end
end