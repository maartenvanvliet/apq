defmodule Apq.Phase.ApqInput do
  @moduledoc false

  use Absinthe.Phase
  require Logger

  @query_not_found_error %Absinthe.Phase.Error{
    phase: __MODULE__,
    message: "PersistedQueryNotFound"
  }

  @query_sha_match_error %Absinthe.Phase.Error{
    phase: __MODULE__,
    message: "ProvidedShaDoesNotMatch"
  }

  @query_format_error %Absinthe.Phase.Error{
    phase: __MODULE__,
    message: "QueryFormatIncorrect"
  }

  @hash_format_error %Absinthe.Phase.Error{
    phase: __MODULE__,
    message: "HashFormatIncorrect"
  }

  @doc false
  def run(_, options \\ [])

  def run({:apq_cache_put, document, hash}, options)
      when is_binary(document) and is_binary(hash) do
    calculated_hash = :crypto.hash(:sha256, document) |> Base.encode16(case: :lower)

    case hash == calculated_hash do
      true -> maybe_defer_cache_put(document, hash, options)
      false -> result_with_error(@query_sha_match_error)
    end
  end

  def run({:apq_cache_put, _document, hash}, _options) when is_binary(hash) do
    result_with_error(@query_format_error)
  end

  def run({:apq_cache_put, document, _hash}, _options) when is_binary(document) do
    result_with_error(@hash_format_error)
  end

  def run({:apq_cache_get, _document, hash}, options) when is_binary(hash) do
    cache_provider = Keyword.fetch!(options, :cache_provider)
    cache_compiled = Keyword.fetch!(options, :cache_compiled)

    case cache_provider.get(hash) do
      # Cache miss
      {:ok, nil} ->
        result_with_error(@query_not_found_error)

      # Cache hit
      {:ok, document} ->
        maybe_jump(document, cache_compiled: cache_compiled)

      _error ->
        Logger.warn("Error occured getting cache entry for #{hash}")
        {:ok, nil}
    end
  end

  def run({:apq_cache_get, _document, _hash}, _options) do
    result_with_error(@hash_format_error)
  end

  defp maybe_defer_cache_put(document, hash, options) do
    cache_compiled = Keyword.fetch!(options, :cache_compiled)
    cache_provider = Keyword.fetch!(options, :cache_provider)

    case cache_compiled do
      true ->
        {:ok, document}

      false ->
        cache_provider.put(hash, document)
        {:ok, document}
    end
  end

  defp maybe_jump(document, options) do
    case Keyword.fetch!(options, :cache_compiled) do
      true -> {:jump, document, Absinthe.Phase.Document.Variables}
      false -> {:ok, document}
    end
  end

  defp result_with_error(error) do
    {:jump, %Absinthe.Blueprint{errors: [error]}, Absinthe.Phase.Document.Validation.Result}
  end
end
