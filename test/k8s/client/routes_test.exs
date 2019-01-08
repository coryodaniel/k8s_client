defmodule K8s.Client.RoutesTest do
  use ExUnit.Case
  alias K8s.Client.Routes
  alias K8s.Client.Swagger

  @default_k8s_spec System.get_env("K8S_SPECS") || "priv/swagger/1.13.json"
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

  def actual_list(op) do
    opts = path_opts(op)

    if opts[:namespace] == :all do
      :list_all_namespaces
    else
      :list
    end
  end

  def actual_post(_operation) do
    :post
  end

  def actual_delete(_operation) do
    :delete
  end

  def actual_deletecollection(_operation) do
    :delete_collection
  end

  def actual_get(_operation) do
    :get
  end

  def actual_get_log(_operation) do
    :get_log
  end

  def actual_get_status(_operation) do
    :get_status
  end

  def actual_put(_operation) do
    :put
  end

  def actual_patch(_operation) do
    :patch
  end

  def actual_patch_status(_operation) do
    :patch_status
  end

  def actual_put_status(_operation) do
    :put_status
  end

  def operation_to_map(op) do
    %{"version" => version, "group" => group, "kind" => kind} =
      op["x-kubernetes-group-version-kind"]

    path_opts = path_opts(op)

    metadata = case path_opts[:namespace] do
      :all -> %{"name" => path_opts[:name]}
      other -> %{"namespace" => other, "name" => path_opts[:name]}
    end

    %{
      "apiVersion" => api_version(group, version),
      "kind" => kind,
      "metadata" => metadata
    }
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
                nil -> "actual_#{@route_function}"
                subaction -> "actual_#{@route_function}_#{subaction}"
              end

            function_under_test = apply(__MODULE__, String.to_atom(test_function), [@operation])

            map = operation_to_map(@operation)
            assert expected == apply(Routes, function_under_test, [map])
          end

          test "given path components, renders the path" do
            expected = expected_path(@path)

            test_function =
              case Swagger.subaction(@path) do
                nil -> "actual_#{@route_function}"
                subaction -> "actual_#{@route_function}_#{subaction}"
              end

            function_under_test = apply(__MODULE__, String.to_atom(test_function), [@operation])

            %{"version" => version, "group" => group, "kind" => kind} = @operation["x-kubernetes-group-version-kind"]
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
    assert {:error, "Missing required option: namespace"} = result
  end

  test "returns error when operation not supported" do
    result = Routes.post("apps/v9000", "Deployment", [])
    assert {:error, "No kubernetes operation for Deployment(apps/v9000); Options: []"}
  end

  # test "given an arbitrary struct, renders the path" do
  #   deployment = %MyDeployment{
  #     apiVersion: "apps/v1",
  #     kind: "Deployment",
  #     metadata: %{
  #       namespace: "default"
  #     }
  #   }
  #
  #   assert "/apis/apps/v1/deployments/default" == Routes.post(deployment)
  # end
end
