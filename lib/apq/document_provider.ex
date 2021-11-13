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
  - `:strategy` -- Strategy whether to cache raw graphql strings, or the parsed/validated blueprint. Defaults to raw.

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
  @max_query_size 16_384

  require Logger

  defmacro __using__(opts) do
    cache_provider = Keyword.fetch!(opts, :cache_provider)
    max_query_size = Keyword.get(opts, :max_query_size, @max_query_size)
    json_codec = Keyword.get(opts, :json_codec)
    strategy = Keyword.get(opts, :strategy, Apq.Strategy.RawQuery)

    quote do
      @behaviour Absinthe.Plug.DocumentProvider

      Module.put_attribute(__MODULE__, :max_query_size, unquote(max_query_size))

      def pipeline(options) do
        Apq.DocumentProvider.pipeline(options,
          json_codec: unquote(json_codec),
          strategy: unquote(strategy),
          cache_provider: unquote(cache_provider)
        )
      end

      @doc """
      Handles any requests with the Apq extensions and forwards those without
      to the next document provider.
      """
      def process(%{params: params} = request, opts) do
        opts =
          Keyword.merge(
            [
              json_codec: unquote(json_codec),
              max_query_size: unquote(max_query_size),
              cache_provider: unquote(cache_provider),
              strategy: unquote(strategy)
            ],
            opts
          )

        Apq.DocumentProvider.process(request, opts)
      end

      defoverridable pipeline: 1
    end
  end

  @doc """
  Handles any requests with the Apq extensions and forwards those without
  to the next document provider.
  """
  def process(request, opts) do
    cache_provider = Keyword.fetch!(opts, :cache_provider)
    json_codec = Keyword.get(opts, :json_codec)
    max_query_size = Keyword.get(opts, :max_query_size)

    processed_params =
      request.params
      |> format_params(json_codec)
      |> process_params()

    case processed_params do
      {hash, nil} -> get_document(cache_provider, request, hash)
      {hash, query} -> store_document(request, hash, query, max_query_size)
      _ -> {:cont, request}
    end
  end

  @doc """
  Determine the remaining pipeline for a request with an apq document.
  """
  def pipeline(%{pipeline: as_configured} = request, opts) do
    opts[:strategy].pipeline(as_configured, [digest: request.document.digest] ++ opts)
  end

  defp store_document(request, _digest, query, max_query_size)
       when byte_size(query) > max_query_size do
    {:halt, %{request | document: %Apq{error: :apq_query_max_size_error}}}
  end

  defp store_document(request, digest, query, _max_query_size)
       when is_binary(query) and is_binary(digest) do
    calculated_digest = Apq.Digest.digest(query)

    case calculated_digest == digest do
      true ->
        {:halt,
         %{
           request
           | document: %Apq{
               action: :apq_stored,
               document: query,
               digest: digest
             }
         }}

      false ->
        {:halt, %{request | document: %Apq{error: :apq_hash_match_error, document: query}}}
    end
  end

  defp store_document(request, hash, _, _max_query_size)
       when is_binary(hash) do
    {:halt, %{request | document: %Apq{error: :apq_query_format_error}}}
  end

  defp store_document(request, _hash, query, _max_query_size)
       when is_binary(query) do
    {:halt, %{request | document: %Apq{error: :apq_hash_format_error}}}
  end

  defp get_document(cache_provider, request, digest) when is_binary(digest) do
    case cache_provider.get(digest) do
      # Cache miss
      {:ok, nil} ->
        {:halt, %{request | document: %Apq{error: :apq_not_found_error}}}

      # Cache hit
      {:ok, document} ->
        {:halt,
         %{
           request
           | document: %Apq{
               action: :apq_found,
               document: document,
               digest: digest
             }
         }}

      _error ->
        Logger.warn("Error occured getting cache entry for #{digest}")
        {:cont, request}
    end
  end

  defp get_document(_cache_provider, request, _) do
    {:halt, %{request | document: %Apq{error: :apq_hash_format_error}}}
  end

  defp format_params(%{"extensions" => extensions} = params, json_codec)
       when is_binary(extensions) do
    case Kernel.function_exported?(json_codec, :decode!, 1) do
      true ->
        Map.put(params, "extensions", json_codec.decode!(extensions))

      _ ->
        raise RuntimeError, message: "json_codec must be specified and respond to decode!/1"
    end
  end

  defp format_params(params, _json_codec), do: params

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
end
