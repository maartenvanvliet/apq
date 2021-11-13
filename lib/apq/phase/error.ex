defmodule Apq.Phase.Error do
  @moduledoc false

  @errors %{
    apq_not_found_error: "PersistedQueryNotFound",
    apq_hash_match_error: "ProvidedShaDoesNotMatch",
    apq_query_format_error: "QueryFormatIncorrect",
    apq_query_max_size_error: "PersistedQueryLargerThanMaxSize",
    apq_hash_format_error: "HashFormatIncorrect"
  }

  def build_error(error) do
    result_with_error(@errors[error])
  end

  defp result_with_error(error) do
    {:jump,
     %Absinthe.Blueprint{
       errors: [
         %Absinthe.Phase.Error{
           phase: __MODULE__,
           message: error
         }
       ]
     }, Absinthe.Phase.Document.Validation.Result}
  end
end
