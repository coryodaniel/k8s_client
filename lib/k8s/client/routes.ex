defmodule K8s.Client.Routes do
  @moduledoc """
  Kubernetes operation URL paths
  """

  alias K8s.Client.{Operation, Swagger}
  @route_map Swagger.route_map(Operation.list())

  def route_map(), do: @route_map

  @doc """
  Find similar routes.

  ## Examples

      iex> K8s.Client.Routes.similar("post/apps/v1beta1/Deployment/namespace/name")
      ["post/apps/v1beta1/Deployment/namespace"]

      iex> K8s.Client.Routes.similar("post/apps/v1beta1/Deployment")
      ["post/apps/v1beta1/DeploymentRollback/name/namespace", "post/apps/v1beta1/Deployment/namespace"]

  """
  def similar(name) do
    name_length = String.length(name)

    route_map()
    |> Map.keys()
    |> Enum.filter(fn key ->
      case String.length(key) <= name_length do
        true -> String.starts_with?(name, key)
        false -> String.starts_with?(key, name)
      end
    end)
  end

  @doc """
  Generates the path for an action.

  The available routes can be inspected with `K8s.Client.Routes.route_map/0`

  ## Examples

      iex> K8s.Client.Routes.path_for("post", "apps/v1", :deployment, namespace: "default")
      "/apis/apps/v1/namespaces/default/deployments"

      iex> deploy = %{"apiVersion" => "apps/v1", "kind" => "Deployment", "metadata" => %{"namespace" => "default", "name" => "nginx"}}
      ...> K8s.Client.Routes.path_for(:put, deploy)
      "/apis/apps/v1/namespaces/default/deployments/nginx"

  """
  def path_for(action, %{
        "apiVersion" => v,
        "kind" => k,
        "metadata" => %{"name" => name, "namespace" => ns}
      }) do
    path_for(action, v, k, namespace: ns, name: name)
  end

  def path_for(action, %{"apiVersion" => v, "kind" => k, "metadata" => %{"name" => name}}) do
    path_for(action, v, k, name: name)
  end

  def path_for(action, %{"apiVersion" => v, "kind" => k, "metadata" => %{"namespace" => ns}}) do
    path_for(action, v, k, namespace: ns)
  end

  def path_for(action, %{"apiVersion" => v, "kind" => k}) do
    path_for(action, v, k, [])
  end

  @spec path_for(binary, binary, binary, keyword(atom)) :: binary | {:error, binary}
  def path_for(action, api_version, kind, opts \\ []) do
    key = Swagger.make_route_key(action, api_version, Operation.proper_kind_name(kind), Keyword.keys(opts))

    case Map.get(route_map(), key) do
      nil ->
        {:error, "Unsupported operation: #{key}"}

      template ->
        Swagger.replace_path_vars(template, opts)
    end
  end
end
