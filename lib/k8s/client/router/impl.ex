defmodule K8s.Client.Router.Impl do
  @moduledoc """
  Logic for generating a kubernetes operation/resource path
  """
  alias K8s.Client.Swagger

  @doc """
  Creates a route map from a swagger spec.

  ## Examples

      iex> K8s.Client.Router.Impl.new("priv/custom/simple.json")
      %{
        "delete_collection/apps/v1/Deployment/namespace" => "/apis/apps/v1/namespaces/{namespace}/deployments",
        "list/apps/v1/Deployment/namespace" => "/apis/apps/v1/namespaces/{namespace}/deployments",
        "post/apps/v1/Deployment/namespace" => "/apis/apps/v1/namespaces/{namespace}/deployments",
        "delete/apps/v1/Deployment/name/namespace" => "/apis/apps/v1/namespaces/{namespace}/deployments/{name}",
        "get/apps/v1/Deployment/name/namespace" => "/apis/apps/v1/namespaces/{namespace}/deployments/{name}",
        "patch/apps/v1/Deployment/name/namespace" => "/apis/apps/v1/namespaces/{namespace}/deployments/{name}",
        "put/apps/v1/Deployment/name/namespace" => "/apis/apps/v1/namespaces/{namespace}/deployments/{name}"
      }
  """
  @spec new(binary | map) :: map
  def new(spec_path_or_spec_map) do
    spec_path_or_spec_map
    |> Swagger.build()
    |> route_map()
  end

  @doc """
  Generates a map of operation attributes to path template.
  """
  def route_map(operations) do
    operations
    |> Map.values()
    |> Enum.reduce(%{}, fn metadata, agg ->
      path_with_args = metadata["path"]

      action_name = Swagger.gen_action_name(metadata)
      api_version = metadata["api_version"]
      kind = metadata["kind"]
      arg_names = Swagger.find_args(path_with_args)

      key = make_route_key(action_name, api_version, kind, arg_names)
      Map.put(agg, key, path_with_args)
    end)
  end

  @doc """
  Find similar routes.

  ## Examples

  Finds routes when too many route params are specified:

      iex> route_map = K8s.Client.Router.Impl.new("priv/custom/simple.json")
      ...> K8s.Client.Router.Impl.similar(route_map, "post/apps/v1/Deployment/namespace/name")
      ["post/apps/v1/Deployment/namespace"]

  Finds routes when not enough route params are specified:

      iex> route_map = K8s.Client.Router.Impl.new("priv/custom/simple.json")
      ...> K8s.Client.Router.Impl.similar(route_map, "post/apps/v1/Deployment")
      ["post/apps/v1/Deployment/namespace"]

  """
  @spec similar(map, binary) :: list(binary)
  def similar(route_map, name) do
    name_length = String.length(name)

    route_map
    |> Map.keys()
    |> Enum.filter(fn key ->
      case String.length(key) <= name_length do
        true -> String.starts_with?(name, key)
        false -> String.starts_with?(key, name)
      end
    end)
  end

  @doc """
  Replaces path variables with options.

  ## Examples

      iex> K8s.Client.Router.Impl.replace_path_vars("/foo/{name}", name: "bar")
      "/foo/bar"

  """
  @spec replace_path_vars(binary(), keyword(atom())) :: binary()
  def replace_path_vars(path_template, opts) do
    Regex.replace(~r/\{(\w+?)\}/, path_template, fn _, var ->
      opts[String.to_existing_atom(var)]
    end)
  end

  @doc """
  Makes a route key.

  Sorts the args because the interpolation doesn't care, and it makes finding the key much easier.
  """
  @spec make_route_key(binary, binary, binary, list(atom)) :: binary
  def make_route_key(action_name, api_version, kind, arg_names) do
    key_list = [action_name, api_version, kind] ++ Enum.sort(arg_names)
    Enum.join(key_list, "/")
  end

  @doc """
  Generates the path for an action.

  ## Examples

      iex> route_map = K8s.Client.Router.Impl.new("priv/custom/simple.json")
      ...> deploy = %{"apiVersion" => "apps/v1", "kind" => "Deployment", "metadata" => %{"namespace" => "default", "name" => "nginx"}}
      ...> K8s.Client.Router.Impl.path_for(route_map, :put, deploy)
      "/apis/apps/v1/namespaces/default/deployments/nginx"

  """
  @spec path_for(map, binary, map) :: binary | {:error, binary}
  def path_for(route_map, action, %{
        "apiVersion" => v,
        "kind" => k,
        "metadata" => %{"name" => name, "namespace" => ns}
      }) do
    path_for(route_map, action, v, k, namespace: ns, name: name)
  end

  def path_for(route_map, action, %{"apiVersion" => v, "kind" => k, "metadata" => %{"name" => name}}) do
    path_for(route_map, action, v, k, name: name)
  end

  def path_for(route_map, action, %{"apiVersion" => v, "kind" => k, "metadata" => %{"namespace" => ns}}) do
    path_for(route_map, action, v, k, namespace: ns)
  end

  def path_for(route_map, action, %{"apiVersion" => v, "kind" => k}) do
    path_for(route_map, action, v, k, [])
  end

  @doc """
  Generates the path for an action.

  ## Examples

      iex> route_map = K8s.Client.Router.Impl.new("priv/custom/simple.json")
      ...> K8s.Client.Router.Impl.path_for(route_map, "post", "apps/v1", :deployment, namespace: "default")
      "/apis/apps/v1/namespaces/default/deployments"

  """
  @spec path_for(map, binary, binary, binary, keyword(atom)) :: binary | {:error, binary}
  def path_for(route_map, action, api_version, kind, opts \\ []) do
    key =
      make_route_key(
        action,
        api_version,
        K8s.Client.Operation.proper_kind_name(kind),
        Keyword.keys(opts)
      )

    path = Map.get(route_map, key)

    case path do
      nil -> {:error, "Unsupported operation: #{key}"}
      template -> replace_path_vars(template, opts)
    end
  end
end
