defmodule K8s.Client.Operation do
  @moduledoc """
  Encapsulates a k8s swagger operations
  """

  alias K8s.Client.Swagger
  @operations Swagger.build(Swagger.spec())
  @operation_kind_map Swagger.operation_kind_map(@operations)

  @type t :: %__MODULE__{
          method: atom(),
          path: String.t(),
          resource: map()
        }

  defstruct [:method, :path, :resource]

  def list(), do: @operations
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
end
