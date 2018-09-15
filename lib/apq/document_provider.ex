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
    cache_compiled = Keyword.get(opts, :cache_compiled, true)

    quote do
      require Logger
      @behaviour Absinthe.Plug.DocumentProvider

      @doc """
      Handles any requests with the Apq extensions and forwards those without
      to the next document provider.
      """
      def process(%{params: params} = request, _) do
        case process_params(params) do
          {hash, nil} ->
            {:halt, %{request | document: {:apq_cache_get, nil, hash}}}

          {hash, query} ->
            {:halt, %{request | document: {:apq_cache_put, query, hash}}}

          _ ->
            {:cont, request}
        end
      end

      def process(request, _), do: {:cont, request}

      @doc """
      Determine the remaining pipeline for an request with an apq document.

      This prepends the Apq Phase before the first Absinthe.Parse phase and handles
      Apq errors, cache hits and misses.
      """
      def pipeline(%{document: {_, _, hash}, pipeline: as_configured} = query) do
        as_configured
        |> Absinthe.Pipeline.insert_before(
          Absinthe.Phase.Parse,
          {
            Apq.Phase.ApqInput,
            [cache_provider: unquote(cache_provider), cache_compiled: unquote(cache_compiled)]
          }
        )
        |> maybe_cache_compiled(hash)
      end

      defp maybe_cache_compiled(pipeline, hash) do
        case unquote(cache_compiled) do
          true ->
            pipeline
            |> Absinthe.Pipeline.insert_before(
              Absinthe.Phase.Document.Variables,
              {
                Apq.Phase.CacheCompiled,
                [
                  cache_provider: unquote(cache_provider),
                  cache_key: hash,
                  cache_compiled: unquote(cache_compiled)
                ]
              }
            )

          _ ->
            pipeline
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
