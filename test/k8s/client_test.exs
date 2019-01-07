defmodule K8s.Client.Test do
  use ExUnit.Case
  alias K8s.Client

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

  def build_arg_list(path_template) do
    matches = Regex.scan(~r/{([a-z]+)}/, path_template)

    arg_names =
      Enum.map(matches, fn match -> match |> List.last() |> String.to_existing_atom() end)

    arg_vals = %{
      namespace: "foo",
      name: "bar",
      path: "pax",
      logpath: "qux"
    }

    Enum.map(arg_names, fn arg -> arg_vals[arg] end)
  end

  def api_version(nil, version), do: version
  def api_version("", version), do: version
  def api_version(group, version), do: "#{group}/#{version}"

  @swagger["paths"]
  |> Enum.filter(fn {path, operations} -> !Regex.match?(~r/\/watch\//, path) end)
  |> Enum.each(fn {path, operations} ->
    @path path

    operations
    |> Map.delete("parameters")
    |> Enum.each(fn {http_method, operation} ->
      @http_method http_method
      @operation operation
      @client_function @operation["operationId"] |> String.split(~r/[A-Z]/) |> List.first

      if Map.has_key?(@operation, "x-kubernetes-group-version-kind") do
        describe "#{@default_k8s_spec}: K8s.Client.#{@client_function}_path -> [#{@http_method}] #{@path}" do
          test "generates the path" do
            function = "#{@client_function}_path"


            # supports all namespaces

            # %{"version" => version, "group" => group, "kind" => kind} = @operation["x-kubernetes-group-version-kind"]
            expected = expected_path(@path)

            # args = [api_version(group, version), kind, [namespace: "foo", name: "bar", path: "pax", logpath: "qux"]]
            args = [api_version(group, version), kind]
            actual = apply(Client, String.to_atom(function), args)

            assert expected == actual
          end
        end
      end
    end)
  end)
end
