Application.put_env(:absinthe, :log, false)

Supervisor.start_link([{Cachex, stats: true, compressed: true, name: :apq_cache_raw}],
  strategy: :one_for_one
)

Supervisor.start_link([{Cachex, stats: true, compressed: true, name: :apq_cache_blueprint}],
  strategy: :one_for_one
)

defmodule Apq.Bench.Cachex.Raw do
  @behaviour Apq.CacheProvider

  def get(hash) do
    Cachex.get(:apq_cache_raw, hash)
  end

  def put(hash, query) do
    Cachex.put(:apq_cache_raw, hash, query)
  end
end

defmodule Apq.Bench.Cachex.Blueprint do
  @behaviour Apq.CacheProvider

  def get(hash) do
    Cachex.get(:apq_cache_blueprint, hash)
  end

  def put(hash, query) do
    Cachex.put(:apq_cache_blueprint, hash, query)
  end
end

defmodule Apq.Bench.Raw do
  use Apq.DocumentProvider,
    cache_provider: Apq.Bench.Cachex.Raw,
    strategy: Apq.Strategy.RawQuery
end

defmodule Apq.Bench.Blueprint do
  use Apq.DocumentProvider,
    cache_provider: Apq.Bench.Cachex.Blueprint,
    strategy: Apq.Strategy.BlueprintQuery
end

opts_raw =
  Absinthe.Plug.init(
    schema: Apq.TestSchema,
    document_providers: [Apq.Bench.Raw],
    json_codec: Jason
  )

opts_blueprint =
  Absinthe.Plug.init(
    schema: Apq.TestSchema,
    document_providers: [Apq.Bench.Blueprint],
    json_codec: Jason
  )

introspection_query = """
query IntrospectionQuery {
  __schema {
    description
    queryType {
      name
    }
    mutationType {
      name
    }
    subscriptionType {
      name
    }
    types {
      ...FullType
    }
    directives {
      name
      description
      locations
      isRepeatable
      args {
        ...InputValue
      }
    }
  }
}

fragment FullType on __Type {
  kind
  name
  description
  fields(includeDeprecated: true) {
    name
    description
    args {
      ...InputValue
    }
    type {
      ...TypeRef
    }
    isDeprecated
    deprecationReason
  }
  inputFields {
    ...InputValue
  }
  interfaces {
    ...TypeRef
  }
  enumValues(includeDeprecated: true) {
    name
    description
    isDeprecated
    deprecationReason
  }
  possibleTypes {
    ...TypeRef
  }
}

fragment InputValue on __InputValue {
  name
  description
  type {
    ...TypeRef
  }
  defaultValue
}

fragment TypeRef on __Type {
  kind
  name
  ofType {
    kind
    name
    ofType {
      kind
      name
      ofType {
        kind
        name
        ofType {
          kind
          name
          ofType {
            kind
            name
            ofType {
              kind
              name
              ofType {
                kind
                name
              }
            }
          }
        }
      }
    }
  }
}
"""

simple_query = """
query FooQuery($id: ID!) {
  item(id: $id) {
    name
  }
}
"""

import Apq.Plug.TestCase
import Plug.Conn

# store in cache
conn_store = fn query, digest ->
  Plug.Test.conn(:post, "/", %{
    "query" => query,
    "extensions" => %{
      "persistedQuery" => %{"version" => 1, "sha256Hash" => digest}
    },
    "variables" => %{"id" => "foo"}
  })
  |> put_req_header("content-type", "application/graphql")
  |> plug_parser
end

conn_get = fn digest ->
  Plug.Test.conn(:post, "/", %{
    "extensions" => %{
      "persistedQuery" => %{"version" => 1, "sha256Hash" => digest}
    },
    "variables" => %{"id" => "foo"}
  })
  |> put_req_header("content-type", "application/graphql")
  |> plug_parser
end

Benchee.run(
  %{
    "raw" =>
      {fn digest ->
         conn_get.(digest) |> Absinthe.Plug.call(opts_raw)
       end,
       before_scenario: fn input ->
         digest = sha256_hexdigest(input)
         conn_store.(input, digest) |> Absinthe.Plug.call(opts_raw)
         digest
       end},
    "blueprint" =>
      {fn digest ->
         conn_get.(digest) |> Absinthe.Plug.call(opts_blueprint)
       end,
       before_scenario: fn input ->
         digest = sha256_hexdigest(input)
         conn_store.(input, digest) |> Absinthe.Plug.call(opts_blueprint)
         digest
       end}
  },
  inputs: %{
    "Introspection" => introspection_query,
    "Simple query" => simple_query
  },
  memory_time: 2,
  time: 10
)
