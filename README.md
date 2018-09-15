# Apq

[![Build Status](https://travis-ci.com/maartenvanvliet/apq.svg?branch=master)](https://travis-ci.com/maartenvanvliet/apq) [![Hex pm](http://img.shields.io/hexpm/v/apq.svg?style=flat)](https://hex.pm/packages/apq) [![Hex Docs](https://img.shields.io/badge/hex-docs-9768d1.svg)](https://hexdocs.pm/apq) [![License](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

Support for [Automatic Persisted Queries](https://www.apollographql.com/docs/guides/performance.html#automatic-persisted-queries) in Absinthe. 


## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `apq` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:apq, "~> 1.0.0"}
  ]
end
```

## Examples

Define a new module and `use Apq.DocumentProvider`:

    defmodule ApqExample.Apq do
      use Apq.DocumentProvider, cache_provider: ApqExample.Cache
    end

You'll need to implement a cache provider. This is up to you, in this example I use [Cachex](https://github.com/whitfin/cachex) but you could use a Genserver, Redis or anything else. 

Define a module for the cache, e.g when using Cachex:

    defmodule ApqExample.Cache do
      @behaviour Apq.CacheProvider

      def get(hash) do
        Cachex.get(:apq_cache, hash)
      end

      def put(hash, query) do
        Cachex.put(:apq_cache, hash, query)
      end
    end

When using Cachex you'll need to start it in your supervision tree:

    worker(Cachex, [ :apq_cache, [ limit: 100 ] ])


Now we need to add the `ApqExample.Apq` module to the list of document providers.

    match("/api",
      to: Absinthe.Plug,
      init_opts: [
        schema: ApqExample.Schema,
        json_codec: Jason,
        interface: :playground,
        document_providers: [ApqExample.Apq, Absinthe.Plug.DocumentProvider.Default]
      ]
    )

This is it, if you query with a client that has support for Apq it should work with Absinthe.


Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/apq](https://hexdocs.pm/apq).

