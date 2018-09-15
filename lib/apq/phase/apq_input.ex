defmodule Apq.Phase.ApqInput do
  @moduledoc false

  use Absinthe.Phase

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

  def run({:apq_not_found_error, _}, _options) do
    result_with_error(@query_not_found_error)
  end

  def run({:apq_hash_match_error, _}, _options) do
    result_with_error(@query_sha_match_error)
  end

  def run({:apq_query_format_error, _}, _options) do
    result_with_error(@query_format_error)
  end

  def run({:apq_hash_format_error, _}, _options) do
    result_with_error(@hash_format_error)
  end

  def run({:apq_found, document}, _options) do
    {:ok, document}
  end

  def run({:apq_stored, input}, _options) do
    {:ok, input}
  end

  defp result_with_error(error) do
    {:jump, %Absinthe.Blueprint{errors: [error]}, Absinthe.Phase.Document.Validation.Result}
  end
end
