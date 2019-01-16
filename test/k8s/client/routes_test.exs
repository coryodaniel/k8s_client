defmodule K8s.Client.RoutesTest do
  use ExUnit.Case, async: true
  doctest K8s.Client.Routes
  alias K8s.Client.Routes
  alias K8s.Client.Swagger

  @k8s_spec System.get_env("K8S_SPEC") || "priv/swagger/1.13.json"
  @swagger Jason.decode!(File.read!(@k8s_spec))

  # Interpolates path variables {path, namespace, name, logpath}
  def expected_path(path_template) do
    path_template
    |> String.replace("{namespace}", "foo")
    |> String.replace("{name}", "bar")
    |> String.replace("{path}", "pax")
    |> String.replace("{logpath}", "qux")
  end

  def path_opts(params) when not is_list(params), do: []

  def path_opts(params) when is_list(params) do
    values = [namespace: "foo", name: "bar", path: "pax", logpath: "qux"]

    Enum.reduce(params, [], fn param, agg ->
      case param["in"] do
        "path" ->
          name = String.to_existing_atom(param["name"])
          agg ++ [{name, values[name]}]

        _ ->
          agg
      end
    end)
  end

  def api_version(nil, version), do: version
  def api_version("", version), do: version
  def api_version(group, version), do: "#{group}/#{version}"

  def fn_to_test_for__list(op) do
    case Regex.match?(~r/AllNamespaces/, op["operationId"]) do
      true -> :list_all_namespaces
      false -> :list
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

  # Skips /watch/ Deprecated URLs and finalize|bindings|approval|scale paths
  @paths Enum.filter(@swagger["paths"], fn {path, _operations} ->
           !Regex.match?(~r/\/(finalize|bindings|approval|scale)$/, path) &&
             !Regex.match?(~r/\/watch\//, path)
         end)

  Enum.each(@paths, fn {path, operations} ->
    @path path
    @params operations["parameters"] || []

    operations
    |> Map.delete("parameters")
    |> Enum.each(fn {http_method, operation} ->
      @http_method http_method
      @operation operation
      @operation_id @operation["operationId"]
      @route_function @operation["x-kubernetes-action"]

      # Skips connect, and operations w/o k8s group-version-kind
      if Map.has_key?(@operation, "x-kubernetes-group-version-kind") &&
           @operation["x-kubernetes-action"] != "connect" do
        describe "#{@k8s_spec}: #{@operation_id} [#{@http_method}] #{@path}" do
          test "given path components, renders the path" do
            expected = expected_path(@path)

            test_function =
              case Swagger.subaction(@path) do
                nil -> "fn_to_test_for__#{@route_function}"
                subaction -> "fn_to_test_for__#{@route_function}_#{subaction}"
              end

            path_action_to_test = apply(__MODULE__, String.to_atom(test_function), [@operation])

            %{"version" => version, "group" => group, "kind" => kind} =
              @operation["x-kubernetes-group-version-kind"]

            api_version = api_version(group, version)
            opts = path_opts(@params)
            assert expected == Routes.path_for(path_action_to_test, api_version, kind, opts)
          end
        end
      end
    end)
  end)

  test "returns error when missing required path arguments" do
    result = Routes.path_for(:post, "apps/v1", "Deployment", [])
    assert {:error, "Unsupported operation: post/apps/v1/Deployment"} = result
  end

  test "returns error when operation not supported" do
    result = Routes.path_for(:post, "apps/v9000", "Deployment", namespace: "default")
    assert {:error, "Unsupported operation: post/apps/v9000/Deployment/namespace"} = result
  end
end
