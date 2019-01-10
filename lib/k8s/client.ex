defmodule K8s.Client do
  @moduledoc """
  An experimental k8s client
  """

  alias K8s.Conf
  alias K8s.Client.{Request, Routes}

  @spec post(map()) :: Request.t() | {:error, binary()}
  def post(resource = %{}) do
    path = Routes.post(resource)

    case path do
      {:error, msg} ->
        {:error, msg}

      path ->
        %Request{
          path: path,
          method: :post,
          resource: resource
        }
    end
  end

  @spec post(binary, binary, keyword(atom) | nil) :: Request.t() | {:error, binary()}
  def post(api_version, kind, opts \\ []) do
    path = Routes.post(api_version, kind, opts)

    case path do
      {:error, msg} ->
        {:error, msg}

      path ->
        %Request{
          path: path,
          method: :post
        }
    end
  end

  @spec delete(map()) :: Request.t() | {:error, binary()}
  def delete(resource = %{}) do
    path = Routes.delete(resource)

    case path do
      {:error, msg} ->
        {:error, msg}

      path ->
        %Request{
          path: path,
          method: :delete,
          resource: resource
        }
    end
  end

  @spec delete(binary, binary, keyword(atom) | nil) :: Request.t() | {:error, binary()}
  def delete(api_version, kind, opts \\ []) do
    path = Routes.delete(api_version, kind, opts)

    case path do
      {:error, msg} ->
        {:error, msg}

      path ->
        %Request{
          path: path,
          method: :delete
        }
    end
  end

  @spec delete_collection(map()) :: Request.t() | {:error, binary()}
  def delete_collection(resource = %{}) do
    path = Routes.delete_collection(resource)

    case path do
      {:error, msg} ->
        {:error, msg}

      path ->
        %Request{
          path: path,
          method: :delete,
          resource: resource
        }
    end
  end

  @spec delete_collection(binary, binary, keyword(atom) | nil) :: Request.t() | {:error, binary()}
  def delete_collection(api_version, kind, opts \\ []) do
    path = Routes.delete_collection(api_version, kind, opts)

    case path do
      {:error, msg} ->
        {:error, msg}

      path ->
        %Request{
          path: path,
          method: :delete
        }
    end
  end

  @spec get(map()) :: Request.t() | {:error, binary()}
  def get(resource = %{}) do
    path = Routes.get(resource)

    case path do
      {:error, msg} ->
        {:error, msg}

      path ->
        %Request{
          path: path,
          method: :get,
          resource: resource
        }
    end
  end

  @spec get(binary, binary, keyword(atom) | nil) :: Request.t() | {:error, binary()}
  def get(api_version, kind, opts \\ []) do
    path = Routes.get(api_version, kind, opts)

    case path do
      {:error, msg} ->
        {:error, msg}

      path ->
        %Request{
          path: path,
          method: :get
        }
    end
  end

  @spec get_log(map()) :: Request.t() | {:error, binary()}
  def get_log(resource = %{}) do
    path = Routes.get_log(resource)

    case path do
      {:error, msg} ->
        {:error, msg}

      path ->
        %Request{
          path: path,
          method: :get,
          resource: resource
        }
    end
  end

  @spec get_log(binary, binary, keyword(atom) | nil) :: Request.t() | {:error, binary()}
  def get_log(api_version, kind, opts \\ []) do
    path = Routes.get_log(api_version, kind, opts)

    case path do
      {:error, msg} ->
        {:error, msg}

      path ->
        %Request{
          path: path,
          method: :get
        }
    end
  end

  @spec get_status(map()) :: Request.t() | {:error, binary()}
  def get_status(resource = %{}) do
    path = Routes.get_status(resource)

    case path do
      {:error, msg} ->
        {:error, msg}

      path ->
        %Request{
          path: path,
          method: :get,
          resource: resource
        }
    end
  end

  @spec get_status(binary, binary, keyword(atom) | nil) :: Request.t() | {:error, binary()}
  def get_status(api_version, kind, opts \\ []) do
    path = Routes.get_status(api_version, kind, opts)

    case path do
      {:error, msg} ->
        {:error, msg}

      path ->
        %Request{
          path: path,
          method: :get
        }
    end
  end

  @spec put(map()) :: Request.t() | {:error, binary()}
  def put(resource = %{}) do
    path = Routes.put(resource)

    case path do
      {:error, msg} ->
        {:error, msg}

      path ->
        %Request{
          path: path,
          method: :put,
          resource: resource
        }
    end
  end

  @spec put(binary, binary, keyword(atom) | nil) :: Request.t() | {:error, binary()}
  def put(api_version, kind, opts \\ []) do
    path = Routes.put(api_version, kind, opts)

    case path do
      {:error, msg} ->
        {:error, msg}

      path ->
        %Request{
          path: path,
          method: :put
        }
    end
  end

  @spec patch(map()) :: Request.t() | {:error, binary()}
  def patch(resource = %{}) do
    path = Routes.patch(resource)

    case path do
      {:error, msg} ->
        {:error, msg}

      path ->
        %Request{
          path: path,
          method: :patch,
          resource: resource
        }
    end
  end

  @spec patch(binary, binary, keyword(atom) | nil) :: Request.t() | {:error, binary()}
  def patch(api_version, kind, opts \\ []) do
    path = Routes.patch(api_version, kind, opts)

    case path do
      {:error, msg} ->
        {:error, msg}

      path ->
        %Request{
          path: path,
          method: :patch
        }
    end
  end

  @spec patch_status(map()) :: Request.t() | {:error, binary()}
  def patch_status(resource = %{}) do
    path = Routes.patch_status(resource)

    case path do
      {:error, msg} ->
        {:error, msg}

      path ->
        %Request{
          path: path,
          method: :patch,
          resource: resource
        }
    end
  end

  @spec patch_status(binary, binary, keyword(atom) | nil) :: Request.t() | {:error, binary()}
  def patch_status(api_version, kind, opts \\ []) do
    path = Routes.patch_status(api_version, kind, opts)

    case path do
      {:error, msg} ->
        {:error, msg}

      path ->
        %Request{
          path: path,
          method: :patch
        }
    end
  end

  @spec put_status(map()) :: Request.t() | {:error, binary()}
  def put_status(resource = %{}) do
    path = Routes.put_status(resource)

    case path do
      {:error, msg} ->
        {:error, msg}

      path ->
        %Request{
          path: path,
          method: :put,
          resource: resource
        }
    end
  end

  @spec put_status(binary, binary, keyword(atom) | nil) :: Request.t() | {:error, binary()}
  def put_status(api_version, kind, opts \\ []) do
    path = Routes.put_status(api_version, kind, opts)

    case path do
      {:error, msg} ->
        {:error, msg}

      path ->
        %Request{
          path: path,
          method: :put
        }
    end
  end

  @spec execute(Request.t(), Conf.t()) :: {:ok, struct} | {:error, struct}
  def execute(request = %{}, config = %{}), do: execute(request, config, [])

  @spec execute(Request.t(), Conf.t(), map()) :: {:ok, struct} | {:error, struct}
  def execute(request = %{}, config = %{}, body = %{}), do: execute(request, config, body, [])

  @spec execute(Request.t(), Conf.t(), keyword()) :: {:ok, struct} | {:error, struct}
  def execute(request = %{}, config = %{}, opts) do
    request
    |> build_http_req(config, request.resource, opts)
    |> handle_response
  end

  @spec execute(Request.t(), Conf.t(), map(), keyword()) :: {:ok, struct} | {:error, struct}
  def execute(request = %{}, config = %{}, body = %{}, opts) do
    request
    |> build_http_req(config, body, opts)
    |> handle_response
  end

  @spec build_http_req(Request.t(), Conf.t(), map(), keyword()) :: HTTPoison :: Request.t()
  defp build_http_req(request, config, body, opts) do
    request_options = Conf.RequestOptions.generate(config)
    http_headers = headers(request_options)
    http_opts = Keyword.merge([ssl: request_options.ssl_options], opts)
    url = Path.join(config.url, request.path)

    http_body =
      case Jason.encode(body) do
        {:ok, json} -> json
        _ -> ""
      end

    HTTPoison.request(request.method, url, http_body, http_headers, http_opts)
  end

  defp handle_response(resp) do
    case resp do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, Jason.decode!(body)}

      {:ok, %HTTPoison.Response{status_code: code}} when code in 201..299 ->
        :ok

      {:ok, %HTTPoison.Response{status_code: code, body: body}} when code in 400..499 ->
        {:error, "HTTP Error: #{code}; #{body}"}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, "HTTP Client Error: #{reason}"}
    end
  end

  defp headers(ro = %Conf.RequestOptions{}) do
    ro.headers ++ [{"Accept", "application/json"}, {"Content-Type", "application/json"}]
  end
end
