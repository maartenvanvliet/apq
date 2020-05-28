# Apq

[![Build Status](https://travis-ci.com/maartenvanvliet/apq.svg?branch=master)][build-status] [![Hex pm](http://img.shields.io/hexpm/v/apq.svg?style=flat)][hex-page] [![Hex Docs](https://img.shields.io/badge/hex-docs-9768d1.svg)][apq-hexdocs] [![License](https://img.shields.io/badge/License-MIT-blue.svg)][mit-license]

Support for [Automatic Persisted Queries][apq] in Absinthe. Query documents in GraphQL can be be of a significant size. Especially on mobile it may be beneficial to limit the size of the queries so fewer bytes go across the network. APQ uses a deterministic hash of the input query in a request. If the server does not know the hash the client can retry the request with the expanded query. The server can use this request to store the query in its cache.

You'll need a GraphQL client that can use APQ, such as Apollo Client.

Complete example project is available [here][example-project]

## Installation

Since APQ is [available in Hex][hex-page], the package can be installed
by adding `apq` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:apq, "~> 1.2"}
  ]
end
```

## Examples

Define a new module and `use Apq.DocumentProvider`:
```elixir
defmodule ApqExample.Apq do
   use Apq.DocumentProvider, 
    cache_provider: ApqExample.Cache,
    max_query_size: 16384 #default

end
```

If you're going to [use `GET` requests for APQ's hashed queries][apq-with-get], you'll need to specify a `json_codec` that responds to `decode!/1` such as [Jason][jason] or [Poison][poison]:

```elixir
defmodule ApqExample.Apq do
   use Apq.DocumentProvider, 
    json_codec: Jason

end
```
In a Phoenix project, this should be set with `Phoenix.json_library()`.

You'll need to implement a cache provider. This is up to you, in this example I use [Cachex][cachex] but you could use a Genserver, Redis or anything else. 

Define a module for the cache, e.g when using Cachex:
```elixir
defmodule ApqExample.Cache do
  @behaviour Apq.CacheProvider

  def get(hash) do
    Cachex.get(:apq_cache, hash)
  end

  def put(hash, query) do
    Cachex.put(:apq_cache, hash, query)
  end
end
```
When using Cachex you'll need to start it in your supervision tree:
```elixir
worker(Cachex, [ :apq_cache, [ limit: 100 ] ])
```

Now we need to add the `ApqExample.Apq` module to the list of document providers. This goes in your router file.
```elixir
match("/api",
  to: Absinthe.Plug,
  init_opts: [
    schema: ApqExample.Schema,
    json_codec: Jason,
    interface: :playground,
    document_providers: [ApqExample.Apq, Absinthe.Plug.DocumentProvider.Default]
  ]
)
```
This is it, if you query with a client that has support for Apq it should work with Absinthe.

## Documentation

Documentation can be generated with [ExDoc][exdoc]
and published on [HexDocs][hexdocs]. Once published, the docs can
be found at [https://hexdocs.pm/apq][hex-page].

[build-status]: https://travis-ci.com/maartenvanvliet/apq
[apq]: https://www.apollographql.com/docs/guides/performance.html#automatic-persisted-queries
[hex-page]: https://hex.pm/packages/apq
[apq-hexdocs]: https://hexdocs.pm/apq/readme.html
[mit-license]: https://opensource.org/licenses/MIT
[example-project]: https://github.com/maartenvanvliet/apq_example
[apq-with-get]: https://www.apollographql.com/docs/apollo-server/performance/apq/#using-get-requests-with-apq-on-a-cdn
[jason]: https://github.com/michalmuskala/jason
[poison]: https://github.com/devinus/poison
[cachex]: https://github.com/whitfin/cachex
[exdoc]: https://github.com/elixir-lang/ex_doc
[hexdocs]: https://hexdocs.pm
