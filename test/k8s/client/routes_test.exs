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
    %{"version" => version, "group" => group, "kind" => kind} =
      op["x-kubernetes-group-version-kind"]

    api_version = api_version(group, version)
    opts = path_opts(op)

    if opts[:namespace] == :all do
      Routes.list_all_namespaces(api_version, kind, opts)
    else
      Routes.list(api_version, kind, opts)
    end
  end

  def actual_post(op) do
    %{"version" => version, "group" => group, "kind" => kind} =
      op["x-kubernetes-group-version-kind"]

    api_version = api_version(group, version)
    Routes.post(api_version, kind, path_opts(op))
  end

  def actual_delete(op) do
    %{"version" => version, "group" => group, "kind" => kind} =
      op["x-kubernetes-group-version-kind"]

    api_version = api_version(group, version)
    Routes.delete(api_version, kind, path_opts(op))
  end

  def actual_deletecollection(op) do
    %{"version" => version, "group" => group, "kind" => kind} =
      op["x-kubernetes-group-version-kind"]

    api_version = api_version(group, version)
    Routes.delete_collection(api_version, kind, path_opts(op))
  end

  def actual_get(op) do
    %{"version" => version, "group" => group, "kind" => kind} =
      op["x-kubernetes-group-version-kind"]

    api_version = api_version(group, version)
    Routes.get(api_version, kind, path_opts(op))
  end

  def actual_get_log(op) do
    %{"version" => version, "group" => group, "kind" => kind} =
      op["x-kubernetes-group-version-kind"]

    api_version = api_version(group, version)
    Routes.get_log(api_version, kind, path_opts(op))
  end

  def actual_get_status(op) do
    %{"version" => version, "group" => group, "kind" => kind} =
      op["x-kubernetes-group-version-kind"]

    api_version = api_version(group, version)
    Routes.get_status(api_version, kind, path_opts(op))
  end

  def actual_put(op) do
    %{"version" => version, "group" => group, "kind" => kind} =
      op["x-kubernetes-group-version-kind"]

    api_version = api_version(group, version)
    Routes.put(api_version, kind, path_opts(op))
  end

  def actual_patch(op) do
    %{"version" => version, "group" => group, "kind" => kind} =
      op["x-kubernetes-group-version-kind"]

    api_version = api_version(group, version)
    Routes.patch(api_version, kind, path_opts(op))
  end

  def actual_patch_status(op) do
    %{"version" => version, "group" => group, "kind" => kind} =
      op["x-kubernetes-group-version-kind"]

    api_version = api_version(group, version)
    Routes.patch_status(api_version, kind, path_opts(op))
  end

  def actual_put_status(op) do
    %{"version" => version, "group" => group, "kind" => kind} =
      op["x-kubernetes-group-version-kind"]

    api_version = api_version(group, version)
    Routes.put_status(api_version, kind, path_opts(op))
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
          test "generates the path" do
            expected = expected_path(@path)

            test_function =
              case Swagger.subaction(@path) do
                nil -> "actual_#{@route_function}"
                subaction -> "actual_#{@route_function}_#{subaction}"
              end

            actual = apply(__MODULE__, String.to_atom(test_function), [@operation])
            assert expected == actual
          end
        end
      end
    end)
  end)
end