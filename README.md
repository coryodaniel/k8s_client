# K8s

An experimental Kubernetes client. 

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `k8s` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:k8s, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/k8s](https://hexdocs.pm/k8s).


## TODO

* [ ] see example.ex
* [ ] Naming: maximum length of 253 characters and consist of lower case alphanumeric characters, -, and .
* [ ] Client: Encapsulate k8s conf, accept it as an argument too
* [ ] Client: should it be compiled for a version or accept them at runtime
* [ ] Client: include watch & connect in router, but not client for now...
* [ ] CRD Monitor:
  * [ ] discover CRDs at runtime, or accept swagger for them.
  * [ ] Vs. Naive 'user is right' assumption. No pattern matching, just interpolating to make paths...
* [ ] Client: CRD subresources
* [ ] Client: Rules engine vs accepting additional swaggers
* [ ] Client: What sucks about compilation is applications using k8s have to be compiled for the k8s version vs runtime `Client.create(deployment, k8s_version: "1.10")`
* [ ] "inflecting?"
  * [ ] K8s.Model `@preserve "deployment.kubernetes.io/revision"`
  * [ ] K8s.Model `@skip_parse "metadata.annotations"`
