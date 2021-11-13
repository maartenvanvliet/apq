defmodule Apq do
  @moduledoc """
  Provide support for [automatic persisted queries](https://www.apollographql.com/docs/guides/performance.html#automatic-persisted-queries)

  When a request contains the apq extension and the query-document is not provided we do
  a lookup in a cache using a hash to fetch the document. If it is available the normal graphql
  resolving starts, if not we return an error.

  The graphql-client should retry when it sees the error, but now with the query so
  we can store the query in the cache using the hash as a cache key.
  """

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
