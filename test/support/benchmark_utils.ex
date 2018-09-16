defmodule Apq.BenchmarkUtils do
  @moduledoc false
  defmacro __using__(opts \\ []) do
    document_size = Keyword.fetch!(opts, :document_size)

    quote do
      @document_size unquote(document_size)
      @query Apq.BenchmarkUtils.query(@document_size)

      import unquote(__MODULE__)
    end
  end

  def blueprint_before_variables_from_query(schema, query) do
    pipeline = Absinthe.Pipeline.for_document(schema, [])

    {:ok, blueprint, _} =
      Absinthe.Pipeline.run(
        query,
        pipeline |> Absinthe.Pipeline.upto(Absinthe.Phase.Document.Variables)
      )

    blueprint
  end

  @doc """
  Build a query document, takes an integer to make the document larger for the benchmark
  """
  def query(n \\ 1) do
    query_aliases =
      1..n
      |> Enum.map_join("\n", fn i ->
        "a#{i}: item(id: $id) {
        name
      }"
      end)

    """
    query FooQuery($id: ID!) {
      #{query_aliases}
    }
    """
  end
end
