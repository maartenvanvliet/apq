defmodule Apq do
  @external_resource "./README.md"
  @moduledoc @external_resource
             |> File.read!()
             |> String.split("<!-- MDOC !-->")
             |> Enum.fetch!(1)

  defstruct [:error, :action, :document, :digest]

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

    defp render_value(val) when is_binary(val) do
      concat([break("\n"), inspect(val)])
    end

    defp render_value(val) do
      inspect(val)
    end
  end
end
