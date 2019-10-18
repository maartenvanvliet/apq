defmodule Apq.TestSchema do
  @moduledoc false
  use Absinthe.Schema

  @items %{
    "foo" => %{id: "foo", name: "Foo"},
    "bar" => %{id: "bar", name: "Bar"}
  }

  query do
    field(:item,
      type: :item,
      args: [
        id: [type: non_null(:id)]
      ],
      resolve: fn %{id: item_id}, _ ->
        {:ok, @items[item_id]}
      end
    )
  end

  object :item do
    description("A Basic Type")

    field(:id, :id)
    field(:name, :string)
  end
end
