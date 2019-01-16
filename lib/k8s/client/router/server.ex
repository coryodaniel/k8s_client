defmodule K8s.Client.Router.Server do
  use GenServer
  alias K8s.Client.Router.Impl

  @impl true
  def init(store) do
    {:ok, store}
  end

  @impl true
  def handle_call({:path_for, action, resource}, _, route_map) do
    result = Impl.path_for(route_map, action, resource)
    {:reply, result, route_map}
  end

  @impl true
  def handle_call({:path_for, action, api_version, kind, opts}, _, route_map) do
    result = Impl.path_for(route_map, action, api_version, kind, opts)
    {:reply, result, route_map}
  end
end
