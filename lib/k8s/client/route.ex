defmodule K8s.Client.Route do
  @moduledoc """
  Handles identifying and interpolating URI paths.
  """

  @doc """
  Makes a route key.

  Sorts the args because the interpolation doesn't care, and it makes finding the key much easier.

  ## Examples

      iex> K8s.Client.Route.make_route_key(:get, "v1", "Pod", [:name, :namespace])
      "get/v1/pod/name/namespace"

      iex> K8s.Client.Route.make_route_key(:get, "v1", :Pod, [:name, :namespace])
      "get/v1/pod/name/namespace"

      iex> K8s.Client.Route.make_route_key(:get, "v1", :pod, [:name, :namespace])
      "get/v1/pod/name/namespace"

  """
  @spec make_route_key(binary, binary, binary, list(atom)) :: binary
  def make_route_key(action_name, api_version, kind, arg_names) do
    formatted_kind = String.downcase("#{kind}")
    key_list = [action_name, api_version, formatted_kind] ++ Enum.sort(arg_names)
    Enum.join(key_list, "/")
  end

  @doc """
  Replaces path variables with options.

  ## Examples

      iex> K8s.Client.Route.replace_path_vars("/foo/{name}", name: "bar")
      "/foo/bar"

  """
  @spec replace_path_vars(binary(), keyword(atom())) :: binary()
  def replace_path_vars(path_template, opts) do
    Regex.replace(~r/\{(\w+?)\}/, path_template, fn _, var ->
      opts[String.to_existing_atom(var)]
    end)
  end
end
