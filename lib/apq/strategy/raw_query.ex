defmodule Apq.Strategy.RawQuery do
  @moduledoc """
  Caching strategy that will cache the raw
  string query
  """

  @behaviour Apq.Strategy

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
      {Apq.Phase.ApqRawInput, opts}
    )
  end
end
