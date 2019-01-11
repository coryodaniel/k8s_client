defmodule K8s.ClientTest do
  use ExUnit.Case, async: true
  alias K8s.Client
  doctest K8s.Client

  setup do
    conf = K8s.Conf.from_file("test/support/k8s_conf.yaml")

    [conf: conf]
  end

  def valid_deployment_args() do
    ["apps/v1", "Deployment", [namespace: "default", name: "kewl"]]
  end

  def mock_resource(version, kind) do
    %{
      "apiVersion" => version,
      "kind" => kind,
      "metadata" => %{
        "name" => "mock-#{String.downcase(kind)}",
        "namespace" => "test"
      }
    }
  end
end
