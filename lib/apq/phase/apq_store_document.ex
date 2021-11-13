defmodule Apq.Phase.ApqStoreDocument do
  @moduledoc false

  use Absinthe.Phase

  @doc false

  def run(blueprint, options) do
    # remove initial phases, only used for subscriptions and APQ does not deal with that
    blueprint = %{blueprint | initial_phases: []}

    options[:cache_provider].put(options[:digest], blueprint)

    {:ok, blueprint}
  end
end
