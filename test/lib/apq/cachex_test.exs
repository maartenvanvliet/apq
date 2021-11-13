defmodule Apq.CachexTest do
  use Apq.Plug.TestCase
  alias Apq.TestSchema

  import Mox

  setup :verify_on_exit!

  defmodule ApqExample.Cachex do
    @behaviour Apq.CacheProvider

    def get(hash) do
      send(self(), {:get, hash})
      Cachex.get(:apq_cache, hash)
    end

    def put(hash, query) do
      send(self(), {:put, hash, query})
      Cachex.put(:apq_cache, hash, query)
    end
  end

  defmodule ApqCachex.BlueprintQuery do
    use Apq.DocumentProvider,
      cache_provider: ApqExample.Cachex,
      strategy: Apq.Strategy.BlueprintQuery
  end

  defmodule ApqCachex.RawQuery do
    use Apq.DocumentProvider,
      cache_provider: ApqExample.Cachex,
      strategy: Apq.Strategy.RawQuery
  end

  @opts Absinthe.Plug.init(
          schema: TestSchema,
          document_providers: [__MODULE__.ApqCachex.BlueprintQuery],
          json_codec: Jason
        )
  @opts2 Absinthe.Plug.init(
           schema: TestSchema,
           document_providers: [__MODULE__.ApqCachex.RawQuery],
           json_codec: Jason
         )

  @query """
  query FooQuery($id: ID!) {
    item(id: $id) {
      name
    }
  }
  """

  @result ~s({"data":{"item":{"name":"Foo"}}})

  @tag :focus
  test "persists query and reads it back from cache" do
    start_supervised({Cachex, name: :apq_cache})

    digest = sha256_hexdigest(@query)

    assert %{resp_body: resp_body} =
             conn(:post, "/", %{
               "query" => @query,
               "extensions" => %{
                 "persistedQuery" => %{"version" => 1, "sha256Hash" => digest}
               },
               "variables" => %{"id" => "foo"}
             })
             |> put_req_header("content-type", "application/graphql")
             |> plug_parser
             |> Absinthe.Plug.call(@opts)

    assert resp_body == @result
    assert_received {:put, ^digest, _}

    # Read cache
    assert %{resp_body: resp_body} =
             conn(:post, "/", %{
               "extensions" => %{
                 "persistedQuery" => %{"version" => 1, "sha256Hash" => digest}
               },
               "variables" => %{"id" => "foo"}
             })
             |> put_req_header("content-type", "application/graphql")
             |> plug_parser
             |> Absinthe.Plug.call(@opts)

    assert resp_body == @result
    assert_received {:get, ^digest}
  end

  test "persists query and reads it back from cache simple" do
    start_supervised({Cachex, name: :apq_cache})

    digest = sha256_hexdigest(@query)

    assert %{resp_body: resp_body} =
             conn(:post, "/", %{
               "query" => @query,
               "extensions" => %{
                 "persistedQuery" => %{"version" => 1, "sha256Hash" => digest}
               },
               "variables" => %{"id" => "foo"}
             })
             |> put_req_header("content-type", "application/graphql")
             |> plug_parser
             |> Absinthe.Plug.call(@opts2)

    assert resp_body == @result
    assert_received {:put, ^digest, _}

    # Read cache
    assert %{resp_body: resp_body} =
             conn(:post, "/", %{
               "extensions" => %{
                 "persistedQuery" => %{"version" => 1, "sha256Hash" => digest}
               },
               "variables" => %{"id" => "foo"}
             })
             |> put_req_header("content-type", "application/graphql")
             |> plug_parser
             |> Absinthe.Plug.call(@opts2)

    assert resp_body == @result
    assert_received {:get, ^digest}
  end
end
