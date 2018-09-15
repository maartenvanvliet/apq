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

  @doc false
  def run(_, options \\ [])

  def run({:apq_not_found_error, _}, _options) do
    {:jump, %Absinthe.Blueprint{errors: [@query_not_found_error]},
     Absinthe.Phase.Document.Validation.Result}
  end

  def run({:apq_hash_match_error, _}, _options) do
    {:jump, %Absinthe.Blueprint{errors: [@query_sha_match_error]},
     Absinthe.Phase.Document.Validation.Result}
  end

  def run({:apq_found, document}, _options) do
    {:ok, document}
  end

  def run({:apq_stored, input}, _options) do
    {:ok, input}
  end
end
