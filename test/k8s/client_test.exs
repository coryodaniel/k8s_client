defmodule K8s.ClientTest do
  use ExUnit.Case, async: true
  alias K8s.Client
  doctest K8s.Client

  @json File.read!("test/support/example_deployment.json")
  @deployment Jason.decode!(@json)

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

  describe "get_log/1" do
    test "returns a K8s.Client.Operation" do
      pod = mock_resource("v1", "Pod")

      expected = %K8s.Client.Operation{
        method: :get,
        path: "/api/v1/namespaces/test/pods/mock-pod/log",
        resource: pod
      }

      assert expected == Client.get_log(pod)
    end
  end

  describe "get_log/2" do
    test "returns a K8s.Client.Operation" do
      expected = {:error, "Missing required parameter: namespace, name"}
      assert expected == Client.get_log("v1", "Pod")
    end
  end

  describe "get_log/3" do
    test "returns a K8s.Client.Operation" do
      expected = %K8s.Client.Operation{
        method: :get,
        path: "/api/v1/namespaces/test/pods/mock-pod/log"
      }

      assert expected == Client.get_log("v1", "Pod", namespace: "test", name: "mock-pod")
    end
  end

  describe "get_status/1" do
    test "returns a K8s.Client.Operation" do
      expected = %K8s.Client.Operation{
        method: :get,
        path: "/apis/apps/v1/namespaces/default/deployments/kewl/status",
        resource: @deployment
      }

      assert expected == Client.get_status(@deployment)
    end
  end

  describe "get_status/2" do
    test "returns a K8s.Client.Operation" do
      expected = {:error, "Missing required parameter: namespace, name"}
      assert expected == Client.get_status("apps/v1", "Deployment")
    end
  end

  describe "get_status/3" do
    test "returns a K8s.Client.Operation" do
      expected = %K8s.Client.Operation{
        method: :get,
        path: "/api/v1/nodes/i3-kewl-node/status"
      }

      assert expected == Client.get_status("v1", "Node", name: "i3-kewl-node")
    end
  end

  describe "patch_status/1" do
    test "returns a K8s.Client.Operation" do
      expected = %K8s.Client.Operation{
        method: :patch,
        path: "/apis/apps/v1/namespaces/default/deployments/kewl/status",
        resource: @deployment
      }

      assert expected == Client.patch_status(@deployment)
    end
  end

  describe "patch_status/2" do
    test "returns a K8s.Client.Operation" do
      expected = {:error, "Missing required parameter: namespace, name"}
      assert expected == Client.patch_status("apps/v1", "Deployment")
    end
  end

  describe "patch_status/3" do
    test "returns a K8s.Client.Operation" do
      expected = %K8s.Client.Operation{
        method: :patch,
        path: "/apis/apps/v1/namespaces/default/deployments/kewl/status",
        resource: nil
      }

      assert expected == apply(Client, :patch_status, valid_deployment_args())
    end
  end

  describe "put_status/1" do
    test "returns a K8s.Client.Operation" do
      expected = %K8s.Client.Operation{
        method: :put,
        path: "/apis/apps/v1/namespaces/default/deployments/kewl/status",
        resource: @deployment
      }

      assert expected == Client.put_status(@deployment)
    end
  end

  describe "put_status/2" do
    test "returns a K8s.Client.Operation" do
      expected = {:error, "Missing required parameter: namespace, name"}
      assert expected == Client.put_status("apps/v1", "Deployment")
    end
  end

  describe "put_status/3" do
    test "returns a K8s.Client.Operation" do
      expected = %K8s.Client.Operation{
        method: :put,
        path: "/apis/apps/v1/namespaces/default/deployments/kewl/status",
        resource: nil
      }

      assert expected == apply(Client, :put_status, valid_deployment_args())
    end
  end
end
