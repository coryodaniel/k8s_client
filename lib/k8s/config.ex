defmodule K8s.Config do
  @doc """
  Returns a list of swagger specs to compile using.

  Can be set via `config :k8s_client, specs: ["priv/swagger/1.13.json"]` or via `K8S_SPECS`

  Swagger specs will be merged together by operationId.

  This allows you to add additional swagger specs for CRDs.

  ## Examples

      iex> K8s.Config.specs()
      ["priv/swagger/1.13.json"]

  """
  @spec specs() :: list(binary)
  def specs() do
    case System.get_env("K8S_SPECS") do
      spec when is_binary(spec) -> String.split(spec, ",")
      nil -> Application.get_env(:k8s_client, :specs)
    end
  end
end
