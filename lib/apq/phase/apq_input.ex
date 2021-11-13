defmodule Apq.Phase.ApqInput do
  @moduledoc false

  use Absinthe.Phase

  alias Apq.Document

  @query_not_found_error %Absinthe.Phase.Error{
    phase: __MODULE__,
    message: "PersistedQueryNotFound"
  }

  @query_max_size_error %Absinthe.Phase.Error{
    phase: __MODULE__,
    message: "PersistedQueryLargerThanMaxSize"
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

  def run(%Document{error: :apq_query_max_size_error}, _options) do
    result_with_error(@query_max_size_error)
  end

  def run(%Document{error: :apq_not_found_error}, _options) do
    result_with_error(@query_not_found_error)
  end

  def run(%Document{error: :apq_hash_match_error}, _options) do
    result_with_error(@query_sha_match_error)
  end

  def run(%Document{error: :apq_query_format_error}, _options) do
    result_with_error(@query_format_error)
  end

  def run(%Document{error: :apq_hash_format_error}, _options) do
    result_with_error(@hash_format_error)
  end

  def run(%Document{action: :apq_found, document: document}, _options) do
    {:ok, document}
  end

  def run(%Document{action: :apq_stored, document: input}, _options) do
    {:ok, input}
  end

  defp result_with_error(error) do
    {:jump, %Absinthe.Blueprint{errors: [error]}, Absinthe.Phase.Document.Validation.Result}
  end
end
