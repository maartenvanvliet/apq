defmodule Apq.BenchmarkTest do
  use Apq.Plug.TestCase
  alias Apq.TestSchema

  defmodule ApqDocumentWithCompiledCacheMock do
    use Apq.DocumentProvider, cache_provider: __MODULE__.CompiledQueryCache

    defmodule CompiledQueryCache do
      @behaviour Apq.CacheProvider
      use Apq.BenchmarkUtils, document_size: 50

      @cache blueprint_before_variables_from_query(Apq.TestSchema, @query)

      def get(_hash) do
        {:ok, @cache}
      end

      def put(_hash, _query), do: {:ok, nil}
    end
  end

  defmodule ApqDocumentWithStringCacheMock do
    use Apq.DocumentProvider, cache_provider: __MODULE__.StringQueryCache, cache_compiled: false

    defmodule StringQueryCache do
      @behaviour Apq.CacheProvider
      use Apq.BenchmarkUtils, document_size: 50

      @cache @query

      def get(_hash) do
        {:ok, @cache}
      end

      def put(_hash, _query), do: {:ok, nil}
    end
  end

  @tag :benchmark
  test "Benchmark storing the query string vs storing the compiled query in the cache" do
    Benchee.run(
      %{
        "cache_compiled_query" => fn ->
          cache_compiled_query()
        end,
        "cache_string_query" => fn ->
          cache_string_query()
        end
      },
      time: 10,
      memory_time: 2
    )
  end

  # We can pass bogus hashes as the cache lookup returns the document always.
  defp cache_compiled_query() do
    conn(:post, "/", %{
      "extensions" => %{
        "persistedQuery" => %{"version" => 1, "sha256Hash" => "bogus"}
      },
      "variables" => %{"id" => "foo"}
    })
    |> put_req_header("content-type", "application/graphql")
    |> plug_parser
    |> Absinthe.Plug.call(
      Absinthe.Plug.init(
        schema: TestSchema,
        document_providers: [__MODULE__.ApqDocumentWithCompiledCacheMock],
        json_codec: Jason
      )
    )
  end

  defp cache_string_query() do
    conn(:post, "/", %{
      "extensions" => %{
        "persistedQuery" => %{"version" => 1, "sha256Hash" => "bogus"}
      },
      "variables" => %{"id" => "foo"}
    })
    |> put_req_header("content-type", "application/graphql")
    |> plug_parser
    |> Absinthe.Plug.call(
      Absinthe.Plug.init(
        schema: TestSchema,
        document_providers: [__MODULE__.ApqDocumentWithStringCacheMock],
        json_codec: Jason
      )
    )
  end
end
