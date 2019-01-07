defmodule K8s.Client.Routes do
  defmodule KeyGenerationError do
    defexception message: nil
  end

  alias __MODULE__

  @moduledoc false

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
      Map.merge(agg, route_details(operations, path), fn key, v1, v2 ->
        raise K8s.Client.Routes.KeyGenerationError, message: "Conflicting key generated #{key}\n#{inspect(v1)}\n#{inspect(v2)}"
      end)
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

    action = case Routes.subaction(path) do
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
        operation["x-kubernetes-group-version-kind"]["kind"] != "Scale",
        # skip deprecated watch paths
        !Regex.match?(~r/\/watch\//, path),
        into: %{},
        do: metadata_tuple(operation, http_method, path, operations["parameters"])
  end

  @doc """
  Returns the subaction from a path
  """
  def subaction(path) do
    ~r/\/(log|status|finalize|bindings|approval)$/
      |> Regex.scan(path)
      |> Enum.map(fn(matches) -> List.last(matches) end)
      |> List.first
  end

  defp metadata_tuple(operation, http_method, path, path_params) do
    details = metadata(operation, http_method, path, path_params)
    {generate_route_key(details), details}
  end

  defp generate_route_key(details) do
    action = details["action"]
    api_version = details["api_version"]
    kind = details["kind"]
    all_namespaces = case details["all_namespaces"] do
      true -> :all
      _ -> nil
    end

    route_key(action, api_version, kind, all_namespaces)
  end

  @doc """
  Generates a route key for locating a k8s swagger operation
  """
  @spec route_key(binary(), binary(), binary(), :all | binary()) :: binary()
  def route_key(action, api_version, kind, :all), do: "#{action}/#{api_version}/#{kind}/AllNamespaces"
  def route_key(action, api_version, kind, _namespace), do: "#{action}/#{api_version}/#{kind}"
end
