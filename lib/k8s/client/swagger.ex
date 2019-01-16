defmodule K8s.Client.Swagger do
  @moduledoc """
  Functions for converting swagger specs
  """

  @doc """
  Returns kubernetes swagger spec

  Can be set via `config :k8s_client, spec: "priv/swagger/1.13.json"` or via `K8S_SPEC`

  This allows you to use a custom swagger specs with custom CRDs.

  ## Examples

      iex> K8s.Client.Swagger.spec()
      "priv/swagger/1.13.json"

  """
  @spec spec() :: list(binary)
  def spec() do
    case System.get_env("K8S_SPEC") do
      spec when is_binary(spec) -> spec
      nil -> Application.get_env(:k8s_client, :spec)
    end
  end

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

  @doc """
  Map metadata to an `K8s.Client` action name
  """
  @spec gen_action_name(map()) :: binary()
  def gen_action_name(metadata = %{"action" => name}), do: gen_action_name(metadata, name)

  @spec gen_action_name(map(), binary()) :: binary()
  def gen_action_name(%{"all_namespaces" => true}, name), do: "#{name}_all_namespaces"
  def gen_action_name(_, "deletecollection"), do: "delete_collection"
  def gen_action_name(_, name), do: name

  @doc """
  Find arguments in a URL path.
  """
  @spec find_args(binary()) :: list(atom())
  def find_args(path_with_args) do
    ~r/{([a-z]+)}/
    |> Regex.scan(path_with_args)
    |> Enum.map(fn match -> match |> List.last() |> String.to_atom() end)
  end

  @doc """
  Build a map of downcased k8s-style resource kind name (eg; deployment).

  ## Examples

  Allow client calls to provide name variants so they aren't resticted to constant-style names (eg HorizontalPodAutoscaler).

  ```elixir
    K8s.Client.get("apps/v1", "Deployment")
    "Deployment"

    K8s.Client.get("apps/v1", "deployment")
    "Deployment"

    K8s.Client.get("apps/v1", :deployment)
    "Deployment"
  ```
  """
  def operation_kind_map(operations) do
    operations
    |> Map.values()
    |> Enum.reduce(%{}, fn op, agg ->
      kind = op["kind"]
      downkind = String.downcase(kind)

      agg
      |> Map.put(downkind, kind)
      |> Map.put(kind, kind)
    end)
  end

  defp api_version("", version), do: version
  defp api_version(group, version), do: "#{group}/#{version}"

  defp metadata(operation, method, path, path_params) do
    gvk = operation["x-kubernetes-group-version-kind"]
    group = gvk["group"]
    version = gvk["version"]
    id = operation["operationId"]
    action = operation["x-kubernetes-action"]

    action =
      case subaction(path) do
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
        do:
          {operation["operationId"],
           metadata(operation, http_method, path, operations["parameters"])}
  end

  @doc """
  Returns the subaction from a path
  """
  def subaction(path) do
    ~r/\/(log|status)$/
    |> Regex.scan(path)
    |> Enum.map(fn matches -> List.last(matches) end)
    |> List.first()
  end
end
