defmodule Apq do
  @moduledoc """
  Provide support for [automatic persisted queries](https://www.apollographql.com/docs/guides/performance.html#automatic-persisted-queries)

  When a request contains the apq extension and the query-document is not provided we do
  a lookup in a cache using a hash to fetch the document. If it is available the normal graphql
  resolving starts, if not we return an error.

  The graphql-client should retry when it sees the error, but now with the query so
  we can store the query in the cache using the hash as a cache key.
  """
end
