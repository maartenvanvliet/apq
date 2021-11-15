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
          if key == :document do
            concat([
              Atom.to_string(key) <> ": ~S'''",
              break("\n"),
              string,
              break("\n"),
              "'''",
              break("\n")
            ])
          else
            concat(Atom.to_string(key) <> ": ", inspect(string))
          end
        end

      container_doc("#Apq.Document<", list, ">", opts, fn str, _ -> str end)
    end
  end
end
