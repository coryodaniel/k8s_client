defmodule Mix.Tasks.K8s.Swagger do
  use Mix.Task

  @switches [version: :string]
  @aliases [v: :version]
  @defaults [version: "master"]

  @shortdoc "Downloads a k8s swagger spec"
  @spec run([binary()]) :: nil | :ok
  def run(args) do
    {:ok, _started} = Application.ensure_all_started(:httpoison)
    {opts, _, _} = Mix.K8s.parse_args(args, @defaults, switches: @switches, aliases: @aliases)

    url = url(opts[:version])
    version = opts[:version]
    target = "./priv/swagger/#{version}.json"

    with {:ok, response} <- HTTPoison.get(url) do
      Mix.Generator.create_file(target, response.body)
    else
      {:error, msg} -> raise_with_help(msg)
    end
  end

  def url(version) do
    case version do
      "master" ->
        "https://raw.githubusercontent.com/kubernetes/kubernetes/master/api/openapi-spec/swagger.json"

      version ->
        "https://raw.githubusercontent.com/kubernetes/kubernetes/release-#{version}/api/openapi-spec/swagger.json"
    end
  end

  @spec raise_with_help(binary) :: none()
  def raise_with_help(msg) do
    Mix.raise("""
    #{msg}

    mix k8s.swagger downloads a K8s swagger file to priv/swagger/

    Downloading master:
       mix k8s.swagger

    Downloading a specific version:
       mix k8s.swagger --version 1.13

    """)
  end
end
