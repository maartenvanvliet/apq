defmodule Apq.Phase.ApqRawInput do
  @moduledoc false

  use Absinthe.Phase

  alias Apq.Phase.Error
  @doc false
  def run(_, options \\ [])

  def run(%Apq{action: :apq_found, document: document}, _options) do
    {:ok, document}
  end

  def run(
        %Apq{action: :apq_stored, document: document, digest: digest},
        options
      ) do
    options[:cache_provider].put(digest, document)

    {:ok, document}
  end

  def run(%Apq{error: error}, _options) do
    Error.build_error(error)
  end
end
