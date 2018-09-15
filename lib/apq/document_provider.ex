defmodule Apq.DocumentProvider do
  @moduledoc """
  Apq document provider or Absinthe plug.


  ### Example

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
  defmacro __using__(opts) do
    cache_provider = Keyword.fetch!(opts, :cache_provider)

    quote do
      require Logger
      @behaviour Absinthe.Plug.DocumentProvider

      @doc """
      Handles any requests with the Apq extensions and forwards those without
      to the next document provider.
      """
      def process(%{params: params} = request, _) do
        case process_params(params) do
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

      defp cache_put(request, hash, query) do
        calculated_hash = :crypto.hash(:sha256, query) |> Base.encode16(case: :lower)

        case calculated_hash == hash do
          true ->
            unquote(cache_provider).put(hash, query)
            {:halt, %{request | document: {:apq_stored, query}}}

          false ->
            {:halt, %{request | document: {:apq_hash_match_error, query}}}
        end
      end

      defp cache_get(request, hash) do
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
