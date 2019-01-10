defmodule K8s.ClientTest do
  use ExUnit.Case, async: true
  alias K8s.Client

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

  # TODO:
  # * add watch()
  # * handle query strings
  # * execute/N
  # * review questionable below

  # describe "execute/2" do
  #   test "fail", %{conf: conf} do
  #     assert false
  #   end
  # end

  # describe "execute/3" do
  #   test "fail", %{conf: conf} do
  #     assert false
  #   end
  # end

  # describe "execute/4" do
  #   test "fail", %{conf: conf} do
  #     assert false
  #   end
  # end

  describe "delete/1" do
    test "returns a K8s.Client.Request" do
      expected = %K8s.Client.Request{
        method: :delete,
        path: "/apis/apps/v1/namespaces/default/deployments/kewl",
        resource: @deployment
      }

      assert expected == Client.delete(@deployment)
    end
  end

  describe "delete/2" do
    test "returns a K8s.Client.Request" do
      expected = {:error, "Missing required parameter: namespace, name"}
      assert expected == Client.delete("apps/v1", "Deployment")
    end
  end

  describe "delete/3" do
    test "returns a K8s.Client.Request" do
      expected = %K8s.Client.Request{
        method: :delete,
        path: "/apis/apps/v1/namespaces/default/deployments/kewl",
        resource: nil
      }
      assert expected == apply(Client, :delete, valid_deployment_args())
    end
  end

  describe "delete_collection/1" do
    test "returns a K8s.Client.Request" do
      # TODO: questionable API implementation here, take a resource and delete collection?
      assert true
    end
  end

  describe "delete_collection/2" do
    test "returns a K8s.Client.Request" do
      expected = %K8s.Client.Request{
        method: :delete,
        path: "/apis/extensions/v1beta1/podsecuritypolicies",
        resource: nil
      }
      assert expected == Client.delete_collection("extensions/v1beta1", "PodSecurityPolicy")
    end
  end

  describe "delete_collection/3" do
    test "returns a K8s.Client.Request" do
      expected = %K8s.Client.Request{
        method: :delete,
        path: "/apis/apps/v1beta1/namespaces/default/controllerrevisions",
        resource: nil
      }
      assert expected == Client.delete_collection("apps/v1beta1", "ControllerRevision", [namespace: "default"])
    end
  end

  describe "get/1" do
    test "returns a K8s.Client.Request" do
      expected = %K8s.Client.Request{
        method: :get,
        path: "/apis/apps/v1/namespaces/default/deployments/kewl",
        resource: @deployment
      }

      assert expected == Client.get(@deployment)
    end
  end

  describe "get/2" do
    test "returns a K8s.Client.Request" do
      expected = {:error, "Missing required parameter: namespace, name"}
      assert expected == Client.get("apps/v1", "Deployment")
    end
  end

  describe "get/3" do
    test "returns a K8s.Client.Request" do
      expected = %K8s.Client.Request{
        method: :get,
        path: "/apis/apps/v1/namespaces/default/deployments/kewl",
        resource: nil
      }
      assert expected == apply(Client, :get, valid_deployment_args())
    end
  end

  describe "get_log/1" do
    test "returns a K8s.Client.Request" do
      pod = mock_resource("v1", "Pod")

      expected = %K8s.Client.Request{
        method: :get,
        path: "/api/v1/namespaces/test/pods/mock-pod/log",
        resource: pod
      }

      assert expected == Client.get_log(pod)
    end
  end

  describe "get_log/2" do
    test "returns a K8s.Client.Request" do
      expected = {:error, "Missing required parameter: namespace, name"}
      assert expected == Client.get_log("v1", "Pod")
    end
  end

  describe "get_log/3" do
    test "returns a K8s.Client.Request" do
      expected = %K8s.Client.Request{
        method: :get,
        path: "/api/v1/namespaces/test/pods/mock-pod/log"
      }

      assert expected == Client.get_log("v1", "Pod", [namespace: "test", name: "mock-pod"])
    end
  end

  describe "get_status/1" do
    test "returns a K8s.Client.Request" do
      expected = %K8s.Client.Request{
        method: :get,
        path: "/apis/apps/v1/namespaces/default/deployments/kewl/status",
        resource: @deployment
      }

      assert expected == Client.get_status(@deployment)
    end
  end

  describe "get_status/2" do
    test "returns a K8s.Client.Request" do
      expected = {:error, "Missing required parameter: namespace, name"}
      assert expected == Client.get_status("apps/v1", "Deployment")
    end
  end

  describe "get_status/3" do
    test "returns a K8s.Client.Request" do
      expected = %K8s.Client.Request{
        method: :get,
        path: "/api/v1/nodes/i3-kewl-node/status"
      }

      assert expected == Client.get_status("v1", "Node", name: "i3-kewl-node")
    end
  end

  describe "patch/1" do
    test "returns a K8s.Client.Request" do
      expected = %K8s.Client.Request{
        method: :patch,
        path: "/apis/apps/v1/namespaces/default/deployments/kewl",
        resource: @deployment
      }

      assert expected == Client.patch(@deployment)
    end
  end

  describe "patch/2" do
    test "returns a K8s.Client.Request" do
      expected = {:error, "Missing required parameter: namespace, name"}
      assert expected == Client.patch("apps/v1", "Deployment")
    end
  end

  describe "patch/3" do
    test "returns a K8s.Client.Request" do
      expected = %K8s.Client.Request{
        method: :patch,
        path: "/apis/apps/v1/namespaces/default/deployments/kewl",
        resource: nil
      }
      assert expected == apply(Client, :patch, valid_deployment_args())
    end
  end

  describe "patch_status/1" do
    test "returns a K8s.Client.Request" do
      expected = %K8s.Client.Request{
        method: :patch,
        path: "/apis/apps/v1/namespaces/default/deployments/kewl/status",
        resource: @deployment
      }

      assert expected == Client.patch_status(@deployment)
    end
  end

  describe "patch_status/2" do
    test "returns a K8s.Client.Request" do
      expected = {:error, "Missing required parameter: namespace, name"}
      assert expected == Client.patch_status("apps/v1", "Deployment")
    end
  end

  describe "patch_status/3" do
    test "returns a K8s.Client.Request" do
      expected = %K8s.Client.Request{
        method: :patch,
        path: "/apis/apps/v1/namespaces/default/deployments/kewl/status",
        resource: nil
      }
      assert expected == apply(Client, :patch_status, valid_deployment_args())
    end
  end

  describe "post/1" do
    test "returns a K8s.Client.Request" do
      expected = %K8s.Client.Request{
        method: :post,
        path: "/apis/apps/v1/namespaces/default/deployments",
        resource: @deployment
      }

      assert expected == Client.post(@deployment)
    end
  end

  describe "post/2" do
    test "returns a K8s.Client.Request" do
      expected = {:error, "Missing required parameter: namespace"}
      assert expected == Client.post("apps/v1", "Deployment")
    end
  end

  describe "post/3" do
    test "returns a K8s.Client.Request" do
      expected = %K8s.Client.Request{
        method: :post,
        path: "/apis/apps/v1/namespaces/default/deployments",
        resource: nil
      }
      assert expected == apply(Client, :post, valid_deployment_args())
    end
  end

  describe "put/1" do
    test "returns a K8s.Client.Request" do
      expected = %K8s.Client.Request{
        method: :put,
        path: "/apis/apps/v1/namespaces/default/deployments/kewl",
        resource: @deployment
      }

      assert expected == Client.put(@deployment)
    end
  end

  describe "put/2" do
    test "returns a K8s.Client.Request" do
      expected = {:error, "Missing required parameter: namespace, name"}
      assert expected == Client.put("apps/v1", "Deployment")
    end
  end

  describe "put/3" do
    test "returns a K8s.Client.Request" do
      expected = %K8s.Client.Request{
        method: :put,
        path: "/apis/apps/v1/namespaces/default/deployments/kewl",
        resource: nil
      }
      assert expected == apply(Client, :put, valid_deployment_args())
    end
  end

  describe "put_status/1" do
    test "returns a K8s.Client.Request" do
      expected = %K8s.Client.Request{
        method: :put,
        path: "/apis/apps/v1/namespaces/default/deployments/kewl/status",
        resource: @deployment
      }

      assert expected == Client.put_status(@deployment)
    end
  end

  describe "put_status/2" do
    test "returns a K8s.Client.Request" do
      expected = {:error, "Missing required parameter: namespace, name"}
      assert expected == Client.put_status("apps/v1", "Deployment")
    end
  end

  describe "put_status/3" do
    test "returns a K8s.Client.Request" do
      expected = %K8s.Client.Request{
        method: :put,
        path: "/apis/apps/v1/namespaces/default/deployments/kewl/status",
        resource: nil
      }
      assert expected == apply(Client, :put_status, valid_deployment_args())
    end
  end
end
