defmodule K8s do
  @moduledoc """
  An experimental Kubernetes API client.
  """

  def process_request(), do: "camelize"
  def process_response(), do: "snakeify"

  def to_struct(kind, attrs) do
    # TODO: check if struct exists, if so, do it, else {:error, :unknown_kind}
    # Client should accept a struct to convert to... Client.xxx(..., to: My.Deployment)
    struct = struct(kind)

    Enum.reduce(Map.to_list(struct), struct, fn {k, _}, acc ->
      case Map.fetch(attrs, Atom.to_string(k)) do
        {:ok, v} -> %{acc | k => v}
        :error -> acc
      end
    end)
  end
end
