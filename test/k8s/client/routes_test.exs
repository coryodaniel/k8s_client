defmodule K8s.Client.RoutesTest do
  use ExUnit.Case, async: true
  alias K8s.Client.Routes
  alias K8s.Client.Swagger

  @default_k8s_spec System.get_env("K8S_SPEC") || "priv/swagger/1.13.json"
  @swagger Jason.decode!(File.read!(@default_k8s_spec))

  # Interpolates path variables {path, namespace, name, logpath}
  def expected_path(path_template) do
    path_template
    |> String.replace("{namespace}", "foo")
    |> String.replace("{name}", "bar")
    |> String.replace("{path}", "pax")
    |> String.replace("{logpath}", "qux")
  end

  def path_opts(op) do
    # Send all the opts, routes will only use the opts it needs
    case Regex.match?(~r/AllNamespaces/, op["operationId"]) do
      true -> [namespace: :all, name: "bar", path: "pax", logpath: "qux"]
      false -> [namespace: "foo", name: "bar", path: "pax", logpath: "qux"]
    end
  end

  def api_version(nil, version), do: version
  def api_version("", version), do: version
  def api_version(group, version), do: "#{group}/#{version}"

  def fn_to_test_for__list(op) do
    opts = path_opts(op)

    if opts[:namespace] == :all do
      :list_all_namespaces
    else
      :list
    end
  end

  def fn_to_test_for__post(_operation) do
    :post
  end

  def fn_to_test_for__delete(_operation) do
    :delete
  end

  def fn_to_test_for__deletecollection(_operation) do
    :delete_collection
  end

  def fn_to_test_for__get(_operation) do
    :get
  end

  def fn_to_test_for__get_log(_operation) do
    :get_log
  end

  def fn_to_test_for__get_status(_operation) do
    :get_status
  end

  def fn_to_test_for__put(_operation) do
    :put
  end

  def fn_to_test_for__patch(_operation) do
    :patch
  end

  def fn_to_test_for__patch_status(_operation) do
    :patch_status
  end

  def fn_to_test_for__put_status(_operation) do
    :put_status
  end

  def operation_to_map(op) do
    %{"version" => version, "group" => group, "kind" => kind} =
      op["x-kubernetes-group-version-kind"]

    path_opts = path_opts(op)

    metadata =
      case path_opts[:namespace] do
        :all -> %{"name" => path_opts[:name]}
        other -> %{"namespace" => other, "name" => path_opts[:name]}
      end

    %{
      "apiVersion" => api_version(group, version),
      "kind" => kind,
      "metadata" => metadata
    }
  end

  describe "proper_kind_name/1" do
    test "accepts a constant-style string" do
      assert "Pod" == Routes.proper_kind_name("Pod")
    end

    test "accepts a constant-style atom" do
      assert "Node" == Routes.proper_kind_name(:Node)
    end

    test "accepts a downcased string" do
      assert "ServiceAccount" == Routes.proper_kind_name("serviceaccount")
    end

    test "accepts a downcased atom" do
      assert "Deployment" == Routes.proper_kind_name(:deployment)
    end
  end

  # Skips /watch/ Deprecated URLs
  @swagger["paths"]
  |> Enum.filter(fn {path, _operations} -> !Regex.match?(~r/\/watch\//, path) end)
  |> Enum.each(fn {path, operations} ->
    @path path

    operations
    |> Map.delete("parameters")
    |> Enum.each(fn {http_method, operation} ->
      @http_method http_method
      @operation operation
      @operation_id @operation["operationId"]
      @route_function @operation["x-kubernetes-action"]

      # Skips finalize|bindings|approval|scale paths, connect, and operations w/o k8s group-version-kind
      if !Regex.match?(~r/\/(finalize|bindings|approval|scale)$/, @path) &&
           Map.has_key?(@operation, "x-kubernetes-group-version-kind") &&
           @operation["x-kubernetes-action"] != "connect" do
        describe "#{@default_k8s_spec}: #{@operation_id} [#{@http_method}] #{@path}" do
          test "given a map, renders the path" do
            expected = expected_path(@path)

            test_function =
              case Swagger.subaction(@path) do
                nil -> "fn_to_test_for__#{@route_function}"
                subaction -> "fn_to_test_for__#{@route_function}_#{subaction}"
              end

            function_under_test = apply(__MODULE__, String.to_atom(test_function), [@operation])

            map = operation_to_map(@operation)
            assert expected == apply(Routes, function_under_test, [map])
          end

          test "given path components, renders the path" do
            expected = expected_path(@path)

            test_function =
              case Swagger.subaction(@path) do
                nil -> "fn_to_test_for__#{@route_function}"
                subaction -> "fn_to_test_for__#{@route_function}_#{subaction}"
              end

            function_under_test = apply(__MODULE__, String.to_atom(test_function), [@operation])

            %{"version" => version, "group" => group, "kind" => kind} =
              @operation["x-kubernetes-group-version-kind"]

            api_version = api_version(group, version)
            path_opts = path_opts(@operation)

            assert expected == apply(Routes, function_under_test, [api_version, kind, path_opts])
          end
        end
      end
    end)
  end)

  test "returns error when missing required path arguments" do
    result = Routes.post("apps/v1", "Deployment", [])
    assert {:error, "Missing required parameter: namespace"} = result
  end

  test "returns error when operation not supported" do
    result = Routes.post("apps/v9000", "Deployment", [])
    assert {:error, "No kubernetes operation for Deployment(apps/v9000); Options: []"} = result
  end
end
