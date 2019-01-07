defmodule K8s.Client.Test do
  use ExUnit.Case
  alias K8s.Client
  alias K8s.Client.Routes

  @default_k8s_spec System.get_env("K8S_SPECS") || "priv/swagger/1.13.json"
  @route_info K8s.Client.Routes.build(@default_k8s_spec)
  File.write!("./route_info.json", Jason.encode!(@route_info, pretty: true))

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
   # Send all the opts, K8s.Client.generate_path/2 will only use the ones it needs
    case Regex.match?(~r/AllNamespaces/, op["operationId"]) do
      true -> [namespace: :all, name: "bar", path: "pax", logpath: "qux"]
      false -> [namespace: "foo", name: "bar", path: "pax", logpath: "qux"]
    end
  end

  def api_version(nil, version), do: version
  def api_version("", version), do: version
  def api_version(group, version), do: "#{group}/#{version}"

  def actual_list_path(op) do
    %{"version" => version, "group" => group, "kind" => kind} = op["x-kubernetes-group-version-kind"]
    api_version = api_version(group, version)
    Client.list_path(api_version, kind, path_opts(op))
  end

  def actual_post_path(op) do
    %{"version" => version, "group" => group, "kind" => kind} = op["x-kubernetes-group-version-kind"]
    api_version = api_version(group, version)
    Client.post_path(api_version, kind, path_opts(op))
  end

  def actual_delete_path(op) do
    %{"version" => version, "group" => group, "kind" => kind} = op["x-kubernetes-group-version-kind"]
    api_version = api_version(group, version)
    Client.delete_path(api_version, kind, path_opts(op))
  end

  def actual_deletecollection_path(op) do
    %{"version" => version, "group" => group, "kind" => kind} = op["x-kubernetes-group-version-kind"]
    api_version = api_version(group, version)
    Client.delete_collection_path(api_version, kind, path_opts(op))
  end

  def actual_get_path(op) do
    %{"version" => version, "group" => group, "kind" => kind} = op["x-kubernetes-group-version-kind"]
    api_version = api_version(group, version)
    Client.get_path(api_version, kind, path_opts(op))
  end

  def actual_get_log_path(op) do
    %{"version" => version, "group" => group, "kind" => kind} = op["x-kubernetes-group-version-kind"]
    api_version = api_version(group, version)
    Client.get_log_path(api_version, kind, path_opts(op))
  end

  def actual_get_status_path(op) do
    %{"version" => version, "group" => group, "kind" => kind} = op["x-kubernetes-group-version-kind"]
    api_version = api_version(group, version)
    Client.get_status_path(api_version, kind, path_opts(op))
  end

  def actual_put_path(op) do
    %{"version" => version, "group" => group, "kind" => kind} = op["x-kubernetes-group-version-kind"]
    api_version = api_version(group, version)
    Client.put_path(api_version, kind, path_opts(op))
  end

  def actual_patch_path(op) do
    %{"version" => version, "group" => group, "kind" => kind} = op["x-kubernetes-group-version-kind"]
    api_version = api_version(group, version)
    Client.patch_path(api_version, kind, path_opts(op))
  end

  def actual_patch_status_path(op) do
    %{"version" => version, "group" => group, "kind" => kind} = op["x-kubernetes-group-version-kind"]
    api_version = api_version(group, version)
    Client.patch_status_path(api_version, kind, path_opts(op))
  end

  def actual_put_status_path(op) do
    %{"version" => version, "group" => group, "kind" => kind} = op["x-kubernetes-group-version-kind"]
    api_version = api_version(group, version)
    Client.put_status_path(api_version, kind, path_opts(op))
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
      @client_function @operation["x-kubernetes-action"]

      # Skips scale, connect, and operations w/o k8s group-version-kind
      if !String.ends_with?(@path, "scale") && Map.has_key?(@operation, "x-kubernetes-group-version-kind") && @operation["x-kubernetes-action"] != "connect" do
        describe "#{@default_k8s_spec}: #{@operation_id} [#{@http_method}] #{@path}" do
          test "generates the path" do
            expected = expected_path(@path)

            test_function = case Routes.subaction(@path) do
              nil -> "actual_#{@client_function}_path"
              subaction -> "actual_#{@client_function}_#{subaction}_path"
            end

            actual = apply(__MODULE__, String.to_atom(test_function), [@operation])
            assert expected == actual
          end
        end
      end
    end)
  end)
end
