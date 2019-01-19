defmodule K8s.Client.Router do
  @moduledoc """
  Encapsulates a route map built from kubernetes' swagger operations.
  """
  alias K8s.Client.Route
  alias K8s.Client.Swagger

  @table_prefix "k8s_client"

  @doc """
  Start a new router. Returns the name of the `Router`. The default name is `:default`

  ## Examples

  Starting a K8s 1.13 router:

  ```elixir
  router_name = K8s.Client.Router.start("priv/swagger/1.13.json")
  ```

  Starting a named K8s 1.10 router:

  ```elixir
  router_name = K8s.Client.Router.start("priv/swagger/1.10.json", :legacy)
  ```
  """
  @spec start(binary | map, atom | nil) :: atom
  def start(spec_path_or_spec_map, name \\ :default) do
    table_name = create_table(name)

    spec_path_or_spec_map
    |> build
    |> Enum.each(fn {key, path} ->
      :ets.insert(table_name, {key, path})
    end)

    name
  end

  @doc false
  @spec lookup(binary, binary | atom) :: binary | nil
  def lookup(key, name) do
    case :ets.lookup(name, key) do
      [] -> nil
      [{_, path}] -> path
    end
  end

  @doc """
  Creates a route map from a swagger spec.

  ## Examples

      iex> K8s.Client.Router.build("priv/custom/simple.json")
      %{
        "delete_collection/apps/v1/deployment/namespace" => "/apis/apps/v1/namespaces/{namespace}/deployments",
        "list/apps/v1/deployment/namespace" => "/apis/apps/v1/namespaces/{namespace}/deployments",
        "post/apps/v1/deployment/namespace" => "/apis/apps/v1/namespaces/{namespace}/deployments",
        "delete/apps/v1/deployment/name/namespace" => "/apis/apps/v1/namespaces/{namespace}/deployments/{name}",
        "get/apps/v1/deployment/name/namespace" => "/apis/apps/v1/namespaces/{namespace}/deployments/{name}",
        "patch/apps/v1/deployment/name/namespace" => "/apis/apps/v1/namespaces/{namespace}/deployments/{name}",
        "put/apps/v1/deployment/name/namespace" => "/apis/apps/v1/namespaces/{namespace}/deployments/{name}"
      }
  """
  @spec build(binary | map) :: map
  def build(spec_path_or_spec_map) do
    spec_path_or_spec_map
    |> Swagger.build()
    |> Map.values()
    |> Enum.reduce(%{}, fn metadata, agg ->
      path_with_args = metadata["path"]

      action_name = Swagger.gen_action_name(metadata)
      api_version = metadata["api_version"]
      kind = metadata["kind"]
      arg_names = Swagger.find_args(path_with_args)

      key = Route.make_route_key(action_name, api_version, kind, arg_names)
      Map.put(agg, key, path_with_args)
    end)
  end

  @doc """
  Generates the path for an action.

  ## Examples

      iex> deploy = %{"apiVersion" => "apps/v1", "kind" => "Deployment", "metadata" => %{"namespace" => "default", "name" => "nginx"}}
      ...> K8s.Client.Router.path_for(:put, deploy)
      "/apis/apps/v1/namespaces/default/deployments/nginx"

  """
  @spec path_for(binary, map) :: binary | {:error, binary}
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

  @doc """
  Generates the path for an action.

  ## Examples

      iex> K8s.Client.Router.path_for("post", "apps/v1", :deployment, namespace: "default")
      "/apis/apps/v1/namespaces/default/deployments"

  """
  @spec path_for(binary, binary, binary, keyword(atom)) :: binary | {:error, binary}
  def path_for(action, api_version, kind, opts \\ []) do
    key = Route.make_route_key(action, api_version, kind, Keyword.keys(opts))

    # TODO: this is going to blow up in your face.
    path = lookup(key, to_table_name(:default))

    case path do
      nil -> {:error, "Unsupported operation: #{key}"}
      template -> Route.replace_path_vars(template, opts)
    end
  end

  # Create a namespaced ets table name
  @spec to_table_name(atom) :: atom
  defp to_table_name(name), do: String.to_atom("#{@table_prefix}_#{name}")

  # Create an ets table if it doesn't exist
  @spec create_table(atom) :: atom | {:error, :router_exists}
  defp create_table(name) do
    table_name = to_table_name(name)

    case :ets.info(table_name) do
      :undefined -> :ets.new(table_name, [:set, :protected, :named_table])
      _ -> {:error, :router_exists}
    end
  end
end
