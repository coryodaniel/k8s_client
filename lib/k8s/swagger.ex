defmodule K8s.Swagger do
  @moduledoc """
  Utilities for interacting with swagger files
  """

  @gvk_key "x-kubernetes-group-version-kind"

  @doc """
  Merges and returns all `definitions` from swagger specs
  """
  @spec definitions() :: map
  def definitions() do
    K8s.Config.specs()
    |> Enum.map(fn(spec) -> spec |> File.read! |> Jason.decode! end)
    |> Enum.reduce(%{}, fn spec, acc ->
      K8s.Utils.deep_merge(acc, spec["definitions"])
    end)
  end

  @spec models() :: [map()]
  def models() do
    definitions()
    |> Enum.filter(fn {_, model} -> Map.has_key?(model, @gvk_key) end)
    |> Enum.into(%{})
  end
end
