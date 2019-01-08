# k8s_client

An experimental Kubernetes client. 

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

## Notes

Client path generation does not currently support:
* `connect` operations
* `scale` operations
* `finalize|bindings|approval` operations

No plans to support *deprecated* `watch` functions.

See a full list of removed operations [here](./)
