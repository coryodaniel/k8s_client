# K8s.Client

[K8s.Client](https://hexdocs.pm/k8s_client/readme.html) - Kubernetes client in elixir

[![Build Status](https://travis-ci.org/coryodaniel/k8s_client.svg?branch=master)](https://travis-ci.org/coryodaniel/k8s_client)
[![Coverage Status](https://coveralls.io/repos/github/coryodaniel/k8s_client/badge.svg?branch=master)](https://coveralls.io/github/coryodaniel/k8s_client?branch=master)
[![Hex.pm](http://img.shields.io/hexpm/v/k8s_client.svg?style=flat)](https://hex.pm/packages/k8s_client) 
[![Documentation](https://img.shields.io/badge/documentation-on%20hexdocs-green.svg)](https://hexdocs.pm/k8s_client/)
![Hex.pm](https://img.shields.io/hexpm/l/k8s_client.svg?style=flat)

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `k8s` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:k8s_client, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/k8s](https://hexdocs.pm/k8s).

Before starting the client you must start a Router:

```elixir
K8s.Client.Router.start("path/to/your/k8s/swagger.json")
K8s.Client.get("v1", :pod, name: "nginx", namespace: "default")
```

## Notes

K8s.Client never assumes the "default" namespace. A namespace is always required when applicable to an operation.

Client path generation does not currently support:
* `connect` operations
* `scale` operations
* `finalize|bindings|approval` operations

No plans to support *deprecated* `watch` functions.

See a full list of removed operations [here](./lib/k8s/client/swagger.ex#L81-L91).
