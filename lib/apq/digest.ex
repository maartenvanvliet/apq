defmodule Apq.Digest do
  @moduledoc false
  def digest(input) do
    :crypto.hash(:sha256, input) |> Base.encode16(case: :lower)
  end
end
