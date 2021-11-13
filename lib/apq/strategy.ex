defmodule Apq.Strategy do
  @moduledoc """
  Behaviour to customize how Apq interacts with Absinthe pipeline
  """

  @callback pipeline(Absinthe.Pipeline.t(), Keyword.t()) :: Absinthe.Pipeline.t()
end
