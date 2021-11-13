defmodule Apq.Strategy.BlueprintQuery do
  @moduledoc """
  Caching strategy that will cache the blueprint
  with validations having run.
  """
  def pipeline([Absinthe.Phase.Init | _] = pipeline, opts) do
    do_pipeline(pipeline, opts)
  end

  def pipeline([phase | _] = _pipeline, _opts) do
    raise RuntimeError, """
    #{__MODULE__} strategy expects `Absinthe.Phase.Init` as
    first phase.

    First phase in pipeline was: #{inspect(phase)}

    """
  end

  def do_pipeline(pipeline, opts) do
    pipeline
    |> Absinthe.Pipeline.insert_before(
      Absinthe.Phase.Init,
      {Apq.Phase.ApqBlueprint, opts}
    )
    |> Absinthe.Pipeline.insert_before(
      Absinthe.Phase.Document.Context,
      {Apq.Phase.ApqStoreDocument, opts}
    )
  end
end
