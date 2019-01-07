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

## Notes

Client path generation does not currently support:
* `connect` operations
* `scale` operations

No plans to support *deprecated* `watch` functions.

## TODO

```elixir
K8s.models(:deployment) 
[K8s.Models.Apps.V1.Deployment]

K8s.Models.Apps.V1.Deployment.list_path(namespace: )
K8s.list(:Deployment, namespace: :all, api_version: "apps/v1")
K8s.create(%Deployment)
K8s.status(%Deployment)
```

* [ ]opts[]/validate_opts/2 vs function args macro :/
* [ ] Client.*_path(map)
* [ ] remove conflict catcher...
* [ ] Naming: maximum length of 253 characters and consist of lower case alphanumeric characters, -, and .
* [ ] Client: Encapsulate k8s conf, accept it as an argument too
* [ ] Client: should it be compiled for a version or accept them at runtime
* [ ] CRD Monitor:
  * [ ] discover CRDs at runtime, or accept swagger for them.
  * [ ] Vs. Naive 'user is right' assumption. No pattern matching, just interpolating to make paths...
* [ ] Client: CRD subresources
* [ ] Client: Rules engine vs accepting additional swaggers
* [ ] Client: What sucks about compilation is applications using k8s have to be compiled for the k8s version vs runtime `Client.create(deployment, k8s_version: "1.10")`
* [ ] "inflecting?"
  * [ ] K8s.Model `@preserve "deployment.kubernetes.io/revision"`
  * [ ] K8s.Model `@skip_parse "metadata.annotations"`

Rule:
```elixir
definition = %{"kind" => "Deployment"}
route = {IO, :puts, ["hello"]}
rules = [%{def: definition, route: route}]

obj = %{"kind" => "Deployment", "apiVersion" => "v1"}

what = Enum.find(rules, fn(%{def: definition, route: route}) ->
  match?(obj, definition)
end)

```
