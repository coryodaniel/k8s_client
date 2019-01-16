defmodule K8s.Client.Router do
  @moduledoc """
  Encapsulates a route map built from kubernetes' swagger operations.
  """
  alias K8s.Client.Router.{Impl, Server}

  @doc """
  Start a router

  ## Examples

  Starting a K8s 1.13 router

      iex> K8s.Client.Router.start_link("priv/swagger/1.13.json")

  """
  def start_link(spec_path_or_spec_map \\ %{}) do
    route_map = Impl.new(spec_path_or_spec_map)
    GenServer.start_link(Server, route_map, name: Server)
  end

  @spec path_for(binary, map) :: binary | {:error, binary}
  def path_for(action, resource) when is_map(resource) do
    GenServer.call(Server, {:path_for, action, resource})
  end

  @doc """
  Get the path for an operation

  ## Examples

      iex> K8s.Client.Router.path_for(:list, "v1", :pod, namespace: "default")
      "/api/v1/namespaces/default/pods"

  """
  @spec path_for(binary, binary, binary, keyword(atom) | nil) :: binary | {:error, binary}
  def path_for(action, api_version, kind, opts \\ []) do
    GenServer.call(Server, {:path_for, action, api_version, kind, opts})
  end
end
