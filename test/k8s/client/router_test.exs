defmodule K8s.Client.RouterTest do
  use ExUnit.Case
  use ExUnitProperties
  alias K8s.Client.{Router, Swagger}

  @k8s_spec System.get_env("K8S_SPEC") || "priv/swagger/1.13.json"
  @swagger @k8s_spec |> File.read! |> Jason.decode!
  @paths @swagger["paths"]
  @operations @paths |> Enum.reduce([], fn {path, ops}, agg ->
    operations =
      ops
      |> Enum.filter(fn({method, op}) ->
        method != "parameters" &&
        Map.has_key?(op, "x-kubernetes-group-version-kind") &&
        op["x-kubernetes-action"] != "connect" &&
        !Regex.match?(~r/\/watch\//, path) &&
        !Regex.match?(~r/\/(finalize|bindings|approval|scale)$/, path)
      end)
      |> Enum.map(fn({method, op}) ->
        path_params = (@paths[path]["parameters"] || [])
        op_params = (op["parameters"] || [])
        op
        |> Map.put("http_method", method)
        |> Map.put("path", path)
        |> Map.put("parameters", path_params ++ op_params)
      end)

    agg ++ operations
  end)

  defp expected_path(path) do
    path
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

  property "generates valid paths" do
    check all op <- member_of(@operations) do
      path = op["path"]
      route_function = op["x-kubernetes-action"]
      params = op["parameters"]

      expected = expected_path(path)

      test_function =
        case Swagger.subaction(path) do
          nil -> "fn_to_test_for__#{route_function}"
          subaction -> "fn_to_test_for__#{route_function}_#{subaction}"
        end

      path_action_to_test = apply(__MODULE__, String.to_atom(test_function), [op])

      %{"version" => version, "group" => group, "kind" => kind} = op["x-kubernetes-group-version-kind"]

      api_version = api_version(group, version)
      opts = path_opts(params)
      assert expected == Router.path_for(path_action_to_test, api_version, kind, opts)
    end
  end
end
