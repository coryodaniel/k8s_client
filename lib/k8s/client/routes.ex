defmodule K8s.Client.Routes do
  @moduledoc """
  Kubernetes operation URL paths
  """

  alias K8s.Client.Swagger

  @operations Swagger.build(Swagger.spec())
  @operation_kind_map Swagger.operation_kind_map(@operations)
  @route_map Swagger.route_map(@operations)

  def route_map(), do: @route_map

  def operation_kind_map(), do: @operation_kind_map

  @doc """
  Gets the proper kubernets Kind name given an atom, or downcased string.

  ## Examples

      iex> K8s.Client.Routes.proper_kind_name(:deployment)
      "Deployment"

      iex> K8s.Client.Routes.proper_kind_name(:Deployment)
      "Deployment"

      iex> K8s.Client.Routes.proper_kind_name("deployment")
      "Deployment"

      iex> K8s.Client.Routes.proper_kind_name(:horizontalpodautoscaler)
      "HorizontalPodAutoscaler"
  """
  def proper_kind_name(name) when is_atom(name), do: name |> Atom.to_string() |> proper_kind_name
  def proper_kind_name(name) when is_binary(name), do: Map.get(operation_kind_map(), name, name)

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
    key = Swagger.make_route_key(action, api_version, proper_kind_name(kind), Keyword.keys(opts))

    case Map.get(route_map(), key) do
      nil -> {:error, "Unsupported operation: #{key}"}
      template -> Swagger.replace_path_vars(template, opts)
    end
  end
end
