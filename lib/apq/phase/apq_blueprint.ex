defmodule Apq.Phase.ApqBlueprint do
  @moduledoc """
  When document is found in the cache it will skip
  to the Context phase, passing by parsing/validation steps

  Otherwise it will just pass through the document.
  The ApqStoreDocument phase will pick it up for storing in the cache
  """

  use Absinthe.Phase

  @doc false
  def run(_, options \\ [])

  def run(%Apq{action: :apq_found, document: document}, _options) do
    {:jump, document, Absinthe.Phase.Document.Context}
  end

  def run(%Apq{action: :apq_stored, document: document}, _options) do
    {:ok, document}
  end

  def run(%Apq{error: error}, _options) do
    Apq.Phase.Error.build_error(error)
  end
end
