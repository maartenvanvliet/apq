defmodule Apq.DocumentProvider do
  @moduledoc """
  Apq document provider or Absinthe plug.


  ### Example

  Define a new module and `use Apq.DocumentProvider`:
  ```elixir
  defmodule ApqExample.Apq do
    use Apq.DocumentProvider,
      cache_provider: ApqExample.Cache,
      max_query_size: 16384 # default

  end
  ```

  #### Options

  - `:cache_provider` -- Module responsible for cache retrieval and placement. The cache provider needs to follow the `Apq.CacheProvider` behaviour.
  - `:max_query_size` -- (Optional) Maximum number of bytes of the graphql query document. Defaults to 16384 bytes (16kb).
  - `:json_codec` -- (Optional) Only required if using GET for APQ's hashed queries.  Must respond to `decode!/1`.

  Example configuration for using Apq in `Absinthe.Plug`. Same goes for configuring
  Phoenix.

      match("/api",
        to: Absinthe.Plug,
        init_opts: [
          schema: ApqExample.Schema,
          json_codec: Jason,
          interface: :playground,
          document_providers: [ApqExample.Apq, Absinthe.Plug.DocumentProvider.Default]
        ]
      )

  When the Apq document provider does not match (i.e. the apq extensions are not set in the request),
  the request is passed to the next document provider. This will most likely by the default
  provider available (`Absinthe.Plug.DocumentProvider.Default`).

  """

  # Maximum query size
  @max_query_size 16384

  defmacro __using__(opts) do
    cache_provider = Keyword.fetch!(opts, :cache_provider)
    max_query_size = Keyword.get(opts, :max_query_size, @max_query_size)
    json_codec = Keyword.get(opts, :json_codec)

    quote do
      require Logger
      @behaviour Absinthe.Plug.DocumentProvider

      Module.put_attribute(__MODULE__, :max_query_size, unquote(max_query_size))

      @doc """
      Handles any requests with the Apq extensions and forwards those without
      to the next document provider.
      """
      def process(%{params: params} = request, _) do
        processed_params =
          params
          |> format_params()
          |> process_params()

        case processed_params do
          {hash, nil} -> cache_get(request, hash)
          {hash, query} -> cache_put(request, hash, query)
          _ -> {:cont, request}
        end
      end

      def process(request, _), do: {:cont, request}

      @doc """
      Determine the remaining pipeline for an request with an apq document.

      This prepends the Apq Phase before the first Absinthe.Parse phase and handles
      Apq errors, cache hits and misses.
      """
      def pipeline(%{pipeline: as_configured} = options) do
        as_configured
        |> Absinthe.Pipeline.insert_before(
          Absinthe.Phase.Parse,
          {
            Apq.Phase.ApqInput,
            []
          }
        )
      end

      defp cache_put(request, hash, query) when byte_size(query) > @max_query_size do
        {:halt, %{request | document: {:apq_query_max_size_error, nil}}}
      end

      defp cache_put(request, hash, query) when is_binary(query) and is_binary(hash) do
        calculated_hash = :crypto.hash(:sha256, query) |> Base.encode16(case: :lower)

        case calculated_hash == hash do
          true ->
            unquote(cache_provider).put(hash, query)
            {:halt, %{request | document: {:apq_stored, query}}}

          false ->
            {:halt, %{request | document: {:apq_hash_match_error, query}}}
        end
      end

      defp cache_put(request, hash, _) when is_binary(hash) do
        {:halt, %{request | document: {:apq_query_format_error, nil}}}
      end

      defp cache_put(request, _hash, query) when is_binary(query) do
        {:halt, %{request | document: {:apq_hash_format_error, nil}}}
      end

      defp cache_get(request, hash) when is_binary(hash) do
        case unquote(cache_provider).get(hash) do
          # Cache miss
          {:ok, nil} ->
            {:halt, %{request | document: {:apq_not_found_error, nil}}}

          # Cache hit
          {:ok, document} ->
            {:halt, %{request | document: {:apq_found, document}}}

          error ->
            Logger.warn("Error occured getting cache entry for #{hash}")
            {:cont, request}
        end
      end

      defp cache_get(request, _) do
        {:halt, %{request | document: {:apq_hash_format_error, nil}}}
      end

      defp format_params(%{"extensions" => extensions} = params) when is_binary(extensions) do
        case Kernel.function_exported?(unquote(json_codec), :decode!, 1) do
          true -> Map.put(params, "extensions", unquote(json_codec).decode!(extensions))
          _ -> raise RuntimeError, message: "json_codec must be specified and response to decode!/1"
        end
      end

      defp format_params(params), do: params

      defp process_params(%{
             "query" => query,
             "extensions" => %{"persistedQuery" => %{"version" => 1, "sha256Hash" => hash}}
           }) do
        {hash, query}
      end

      defp process_params(%{
             "extensions" => %{"persistedQuery" => %{"version" => 1, "sha256Hash" => hash}}
           }) do
        {hash, nil}
      end

      defp process_params(params), do: params

      defoverridable pipeline: 1
    end
  end
end
