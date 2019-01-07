defmodule K8s.Codegen do
  @moduledoc false

  @doc """
  Generates route information from a swagger spec.
  """
  @spec route_info(binary()) :: map()
  def route_info(file) do
    spec = file |> File.read!() |> Jason.decode!()

    Enum.reduce(spec["paths"], %{}, fn {path, operations}, agg ->
      Map.merge(agg, route_details(operations, path))
    end)
  end

  defp api_version("", version), do: version
  defp api_version(group, version), do: "#{group}/#{version}"

  defp make_details(operation, method, path) do
    gvk = operation["x-kubernetes-group-version-kind"]
    group = gvk["group"]
    version = gvk["version"]

    %{
      "desc" => operation["description"],
      "group" => group,
      "version" => version,
      "api_version" => api_version(group, version),
      "kind" => gvk["kind"],
      "method" => method,
      "path" => path,
      "params" => operation["parameters"]
    }
  end

  # @methods ~w(get post delete put patch options head)
  @methods ~w(get)
  defp route_details(operations, path) do
    for {http_method, operation} <- operations,
        # "parameters" is in here in some places in the swagger file
        http_method in @methods,
        !Regex.match?(~r/\/watch\//, path),
        into: %{},
        do: {operation["operationId"], make_details(operation, http_method, path)}
  end
end
