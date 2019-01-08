defmodule K8s.Client.RouteData do
  @moduledoc """
  Generates route information from a swagger spec.
  """

  @doc """
  Generates route information from a swagger spec.
  """
  @spec build(binary()) :: map()
  def build(file) when is_binary(file) do
    file |> File.read!() |> Jason.decode!() |> build
  end

  @spec build(map) :: map()
  def build(%{"paths" => paths}) when is_map(paths) do
    paths
    |> Enum.reduce(%{}, fn {path, operations}, agg ->
      Map.merge(agg, route_details(operations, path))
    end)
  end

  def build(_), do: %{}

  defp api_version("", version), do: version
  defp api_version(group, version), do: "#{group}/#{version}"

  defp metadata(operation, method, path, path_params) do
    gvk = operation["x-kubernetes-group-version-kind"]
    group = gvk["group"]
    version = gvk["version"]
    id = operation["operationId"]
    action = operation["x-kubernetes-action"]

    action = case subaction(path) do
      nil -> "#{action}"
      subaction -> "#{action}_#{subaction}"
    end

    %{
      "action" => action,
      "path_params" => path_params || [],
      "id" => id,
      "desc" => operation["description"],
      "api_version" => api_version(group, version),
      "kind" => gvk["kind"],
      "method" => method,
      "path" => path,
      "all_namespaces" => Regex.match?(~r/AllNamespaces$/, id),
      "params" => operation["parameters"]
    }
  end

  @methods ~w(get post delete put patch options head)
  defp route_details(operations, path) do
    for {http_method, operation} <- operations,
        # remove "parameters" from list of HTTP methods
        http_method in @methods,
        # only build paths for things that are have gvk
        Map.has_key?(operation, "x-kubernetes-group-version-kind"),
        # Skip `connect` operations
        operation["x-kubernetes-action"] != "connect",
        # Skip `Scale` resources
        operation["x-kubernetes-group-version-kind"]["kind"] != "Scale",
        # Skip finalize, bindings and approval subactions
        !Regex.match?(~r/\/(finalize|bindings|approval)$/, path),
        # Skip deprecated watch paths; no plan to support
        !Regex.match?(~r/\/watch\//, path),
        into: %{},
        do: {operation["operationId"], metadata(operation, http_method, path, operations["parameters"])}
  end

  @doc """
  Returns the subaction from a path
  """
  def subaction(path) do
    ~r/\/(log|status)$/
      |> Regex.scan(path)
      |> Enum.map(fn(matches) -> List.last(matches) end)
      |> List.first
  end
end
