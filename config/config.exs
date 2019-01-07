# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :k8s, specs: [
  "priv/swagger/1.13.json",
  "priv/custom/example.json"
]
