defmodule Apq.Phase.CacheCompiled do
  @moduledoc false

  use Absinthe.Phase

  def run(input, options) do
    cache_provider = Keyword.fetch!(options, :cache_provider)
    cache_key = Keyword.fetch!(options, :cache_key)

    cache_provider.put(cache_key, input)

    {:ok, input}
  end
end
