defmodule Apq.Document do
  @moduledoc false
  defstruct [:error, :action, :document]

  import Inspect.Algebra

  defimpl Inspect do
    def inspect(doc, opts) do
      list =
        for {key, string} <-
              doc
              |> Map.from_struct()
              |> Map.to_list(),
            string != nil do
          concat(Atom.to_string(key) <> ": ", render_value(string))
        end

      container_doc("#Apq.Document<", list, ">", opts, fn str, _ -> str end)
    end

    defp render_value(val) when is_atom(val) do
      ":" <> Atom.to_string(val)
    end

    defp render_value(val) do
      "\"\"\"" <> val <> "\"\"\""
    end
  end
end
