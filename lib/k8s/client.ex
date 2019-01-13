defmodule K8s.Client do
  @moduledoc """
  An experimental k8s client.

  Functions return `K8s.Client.Operation`s that represent kubernetes operations.

  To run operations pass them to: `run/2`, `run/3`, or `run/4`.
  """

  alias K8s.Conf
  alias K8s.Client.{Operation, Routes}
  @type operation_or_error :: Operation.t() | {:error, binary()}
  @type option :: {:name, String.t()} | {:namespace, binary() | :all}
  @type options :: [option]
  @type http_method :: :get | :put | :patch | :post | :head | :options | :delete

  @doc "Alias of `create/1`"
  defdelegate post(resource), to: __MODULE__, as: :create

  @doc "Alias of `update/1`"
  defdelegate replace(resource), to: __MODULE__, as: :update

  @doc "Alias of `update/1`"
  defdelegate put(resource), to: __MODULE__, as: :update

  @doc """
  Returns a `GET` operation for a resource given a manifest. May be a partial manifest as long as it contains:

    * apiVersion
    * kind
    * metadata.name
    * metadata.namespace (if applicable)

  ## Examples

      iex> pod = %{
      ...>   "apiVersion" => "v1",
      ...>   "kind" => "Pod",
      ...>   "metadata" => %{"name" => "nginx-pod", "namespace" => "test"},
      ...>   "spec" => %{"containers" => %{"image" => "nginx"}}
      ...> }
      ...> K8s.Client.get(pod)
      %K8s.Client.Operation{
        method: :get,
        path: "/api/v1/namespaces/test/pods/nginx-pod",
        resource: %{
          "apiVersion" => "v1",
          "kind" => "Pod",
          "metadata" => %{"name" => "nginx-pod", "namespace" => "test"},
          "spec" => %{"containers" => %{"image" => "nginx"}}
        }
      }
  """
  @spec get(map()) :: operation_or_error
  def get(resource = %{}) do
    path = Routes.get(resource)
    operation_or_error(path, :get, resource)
  end

  @doc """
  Returns a `GET` operation for a resource by version, kind, name, and optionally namespace.

  ## Examples
      iex> K8s.Client.get("apps/v1", "Deployment", namespace: "test", name: "nginx")
      %K8s.Client.Operation{
        method: :get,
        path: "/apis/apps/v1/namespaces/test/deployments/nginx",
        resource: nil
      }

  """
  @spec get(binary, binary, options | nil) :: operation_or_error
  def get(api_version, kind, opts \\ []) do
    path = Routes.get(api_version, kind, opts)
    operation_or_error(path, :get)
  end

  @doc """
  Returns a `GET` operation to list all resources by version, kind, and namespace.

  Given the namespace `:all` as an atom, will perform a list across all namespaces.

  ## Examples
      iex> K8s.Client.list("v1", "Pod", namespace: "default")
      %K8s.Client.Operation{
        method: :get,
        path: "/api/v1/namespaces/default/pods",
        resource: nil
      }

      iex> K8s.Client.list("apps/v1", "Deployment", namespace: :all)
      %K8s.Client.Operation{
        method: :get,
        path: "/apis/apps/v1/deployments",
        resource: nil
      }

  """
  @spec list(binary, binary, options | nil) :: operation_or_error
  def list(api_version, kind, namespace: :all) do
    path = Routes.list_all_namespaces(api_version, kind, [])
    operation_or_error(path, :get)
  end

  def list(api_version, kind, namespace: namespace) do
    path = Routes.list(api_version, kind, namespace: namespace)
    operation_or_error(path, :get)
  end

  @doc """
  Returns a `POST` operation to create the given resource.

  ## Examples

      iex> deployment = %{
      ...> "kind" => "Deployment",
      ...> "apiVersion" => "apps/v1",
      ...> "metadata" => %{
      ...>   "name" => "nginx",
      ...>   "namespace" => "test"
      ...>  },
      ...>  "spec" => %{
      ...>    "replicas" => 1,
      ...>      "template" => %{
      ...>        "spec" => %{
      ...>          "containers" => [%{"image" => "nginx"}]
      ...>         }
      ...>       }
      ...>     }
      ...>   }
      ...> K8s.Client.create(deployment)
      %K8s.Client.Operation{
        method: :post,
        path: "/apis/apps/v1/namespaces/test/deployments",
        resource: %{
          "kind" => "Deployment",
          "apiVersion" => "apps/v1",
          "metadata" => %{
            "name" => "nginx",
            "namespace" => "test"
          },
          "spec" => %{
            "replicas" => 1,
            "template" => %{
              "spec" => %{
                "containers" => [%{"image" => "nginx"}]
              }
            }
          }
        }
      }
  """
  @spec create(map()) :: operation_or_error
  def create(resource = %{}) do
    path = Routes.post(resource)
    operation_or_error(path, :post, resource)
  end

  @doc """
  Returns a `PATCH` operation to patch the given resource.

  ## Examples

      iex> deployment = %{
      ...> "kind" => "Deployment",
      ...> "apiVersion" => "apps/v1",
      ...> "metadata" => %{
      ...>   "name" => "nginx",
      ...>   "namespace" => "test"
      ...>  },
      ...>  "spec" => %{
      ...>    "replicas" => 1,
      ...>      "template" => %{
      ...>        "spec" => %{
      ...>          "containers" => [%{"image" => "nginx"}]
      ...>         }
      ...>       }
      ...>     }
      ...>   }
      ...> K8s.Client.patch(deployment)
      %K8s.Client.Operation{
        method: :patch,
        path: "/apis/apps/v1/namespaces/test/deployments/nginx",
        resource: %{
          "kind" => "Deployment",
          "apiVersion" => "apps/v1",
          "metadata" => %{
            "name" => "nginx",
            "namespace" => "test"
          },
          "spec" => %{
            "replicas" => 1,
            "template" => %{
              "spec" => %{
                "containers" => [%{"image" => "nginx"}]
              }
            }
          }
        }
      }
  """
  @spec patch(map()) :: operation_or_error
  def patch(resource = %{}) do
    path = Routes.patch(resource)
    operation_or_error(path, :patch, resource)
  end

  @doc """
  Returns a `PUT` operation to update/replace the given resource.

  ## Examples

      iex> deployment = %{
      ...> "kind" => "Deployment",
      ...> "apiVersion" => "apps/v1",
      ...> "metadata" => %{
      ...>   "name" => "nginx",
      ...>   "namespace" => "test"
      ...>  },
      ...>  "spec" => %{
      ...>    "replicas" => 1,
      ...>      "template" => %{
      ...>        "spec" => %{
      ...>          "containers" => [%{"image" => "nginx"}]
      ...>         }
      ...>       }
      ...>     }
      ...>   }
      ...> K8s.Client.update(deployment)
      %K8s.Client.Operation{
        method: :put,
        path: "/apis/apps/v1/namespaces/test/deployments/nginx",
        resource: %{
          "kind" => "Deployment",
          "apiVersion" => "apps/v1",
          "metadata" => %{
            "name" => "nginx",
            "namespace" => "test"
          },
          "spec" => %{
            "replicas" => 1,
            "template" => %{
              "spec" => %{
                "containers" => [%{"image" => "nginx"}]
              }
            }
          }
        }
      }
  """
  @spec update(map()) :: operation_or_error
  def update(resource = %{}) do
    path = Routes.patch(resource)
    operation_or_error(path, :put, resource)
  end

  @doc """
  Returns a `DELETE` operation for a resource by manifest. May be a partial manifest as long as it contains:

  * apiVersion
  * kind
  * metadata.name
  * metadata.namespace (if applicable)

  ## Examples

      iex> deployment = %{
      ...> "kind" => "Deployment",
      ...> "apiVersion" => "apps/v1",
      ...> "metadata" => %{
      ...>   "name" => "nginx",
      ...>   "namespace" => "test"
      ...>  },
      ...>  "spec" => %{
      ...>    "replicas" => 1,
      ...>      "template" => %{
      ...>        "spec" => %{
      ...>          "containers" => [%{"image" => "nginx"}]
      ...>         }
      ...>       }
      ...>     }
      ...>   }
      ...> K8s.Client.delete(deployment)
      %K8s.Client.Operation{
        method: :delete,
        path: "/apis/apps/v1/namespaces/test/deployments/nginx",
        resource: %{
          "kind" => "Deployment",
          "apiVersion" => "apps/v1",
          "metadata" => %{
            "name" => "nginx",
            "namespace" => "test"
          },
          "spec" => %{
            "replicas" => 1,
            "template" => %{
              "spec" => %{
                "containers" => [%{"image" => "nginx"}]
              }
            }
          }
        }
      }

  """
  @spec delete(map()) :: operation_or_error
  def delete(resource = %{}) do
    path = Routes.delete(resource)
    operation_or_error(path, :delete, resource)
  end

  @doc """
  Returns a `DELETE` operation for a resource by version, kind, name, and optionally namespace.

  ## Examples
      iex> K8s.Client.delete("apps/v1", "Deployment", namespace: "test", name: "nginx")
      %K8s.Client.Operation{
        method: :delete,
        path: "/apis/apps/v1/namespaces/test/deployments/nginx",
        resource: nil
      }

  """
  @spec delete(binary, binary, options | nil) :: operation_or_error
  def delete(api_version, kind, opts) do
    path = Routes.delete(api_version, kind, opts)
    operation_or_error(path, :delete)
  end

  @doc """
  Returns a `DELETE` collection operation for all instances of a cluster scoped resource kind.

  ## Examples

      iex> K8s.Client.delete_all("extensions/v1beta1", "PodSecurityPolicy")
      %K8s.Client.Operation{
        method: :delete,
        path: "/apis/extensions/v1beta1/podsecuritypolicies",
        resource: nil
      }

      iex> K8s.Client.delete_all("storage.k8s.io/v1", "StorageClass")
      %K8s.Client.Operation{
        method: :delete,
        path: "/apis/storage.k8s.io/v1/storageclasses",
        resource: nil
      }
  """
  @spec delete_all(binary(), binary()) :: operation_or_error
  def delete_all(api_version, kind) do
    path = Routes.delete_collection(api_version, kind, [])
    operation_or_error(path, :delete)
  end

  @doc """
  Returns a `DELETE` collection operation for all instances of a resource kind in a specific namespace.

  ## Examples

      iex> Client.delete_all("apps/v1beta1", "ControllerRevision", namespace: "default")
      %K8s.Client.Operation{
        method: :delete,
        path: "/apis/apps/v1beta1/namespaces/default/controllerrevisions",
        resource: nil
      }

      iex> Client.delete_all("apps/v1", "Deployment", namespace: "staging")
      %K8s.Client.Operation{
        method: :delete,
        path: "/apis/apps/v1/namespaces/staging/deployments",
        resource: nil
      }
  """
  @spec delete_all(binary(), binary(), namespace: binary()) :: operation_or_error
  def delete_all(api_version, kind, namespace: namespace) do
    path = Routes.delete_collection(api_version, kind, namespace: namespace)
    operation_or_error(path, :delete)
  end

  @doc """
  Returns a `GET` operation for a pod's logs given a manifest. May be a partial manifest as long as it contains:

    * apiVersion
    * kind
    * metadata.name
    * metadata.namespace

  ## Examples
      iex> pod = %{
      ...>   "apiVersion" => "v1",
      ...>   "kind" => "Pod",
      ...>   "metadata" => %{"name" => "nginx-pod", "namespace" => "test"},
      ...>   "spec" => %{"containers" => %{"image" => "nginx"}}
      ...> }
      ...> K8s.Client.get_log(pod)
      %K8s.Client.Operation{
        method: :get,
        path: "/api/v1/namespaces/test/pods/nginx-pod/log",
        resource: %{
          "apiVersion" => "v1",
          "kind" => "Pod",
          "metadata" => %{"name" => "nginx-pod", "namespace" => "test"},
          "spec" => %{"containers" => %{"image" => "nginx"}}
        }
      }
  """
  @spec get_log(map()) :: operation_or_error
  def get_log(resource = %{}) do
    path = Routes.get_log(resource)
    operation_or_error(path, :get, resource)
  end

  @doc """
  Returns a `GET` operation for a pod's logs given a namespace and a pod name.

  ## Examples
      iex> K8s.Client.get_log("v1", "Pod", namespace: "test", name: "nginx-pod")
      %K8s.Client.Operation{
        method: :get,
        path: "/api/v1/namespaces/test/pods/nginx-pod/log"
      }
  """
  @spec get_log(binary, binary, options) :: operation_or_error
  def get_log(api_version, kind, opts) do
    path = Routes.get_log(api_version, kind, opts)
    operation_or_error(path, :get)
  end

  @doc """
  Returns a `GET` operation for a resource's status given a manifest. May be a partial manifest as long as it contains:

    * apiVersion
    * kind
    * metadata.name
    * metadata.namespace (if applicable)

  ## Examples

      iex> pod = %{
      ...>   "apiVersion" => "v1",
      ...>   "kind" => "Pod",
      ...>   "metadata" => %{"name" => "nginx-pod", "namespace" => "test"},
      ...>   "spec" => %{"containers" => %{"image" => "nginx"}}
      ...> }
      ...> K8s.Client.get_status(pod)
      %K8s.Client.Operation{
        method: :get,
        path: "/api/v1/namespaces/test/pods/nginx-pod/status",
        resource: %{
          "apiVersion" => "v1",
          "kind" => "Pod",
          "metadata" => %{"name" => "nginx-pod", "namespace" => "test"},
          "spec" => %{"containers" => %{"image" => "nginx"}}
        }
      }
  """
  @spec get_status(map()) :: operation_or_error
  def get_status(resource = %{}) do
    path = Routes.get_status(resource)
    operation_or_error(path, :get, resource)
  end

  @doc """
  Returns a `GET` operation for a resource's status by version, kind, name, and optionally namespace.

  ## Examples
      iex> K8s.Client.get_status("apps/v1", "Deployment", namespace: "test", name: "nginx")
      %K8s.Client.Operation{
        method: :get,
        path: "/apis/apps/v1/namespaces/test/deployments/nginx/status",
        resource: nil
      }

  """
  @spec get_status(binary, binary, options | nil) :: operation_or_error
  def get_status(api_version, kind, opts \\ []) do
    path = Routes.get_status(api_version, kind, opts)
    operation_or_error(path, :get)
  end

  @doc """
  Returns a `PATCH` operation for a resource's status given a manifest. May be a partial manifest as long as it contains:

    * apiVersion
    * kind
    * metadata.name
    * metadata.namespace (if applicable)

  ## Examples

      iex> pod = %{
      ...>   "apiVersion" => "v1",
      ...>   "kind" => "Pod",
      ...>   "metadata" => %{"name" => "nginx-pod", "namespace" => "test"},
      ...>   "spec" => %{"containers" => %{"image" => "nginx"}}
      ...> }
      ...> K8s.Client.patch_status(pod)
      %K8s.Client.Operation{
        method: :patch,
        path: "/api/v1/namespaces/test/pods/nginx-pod/status",
        resource: %{
          "apiVersion" => "v1",
          "kind" => "Pod",
          "metadata" => %{"name" => "nginx-pod", "namespace" => "test"},
          "spec" => %{"containers" => %{"image" => "nginx"}}
        }
      }
  """
  @spec patch_status(map()) :: operation_or_error
  def patch_status(resource = %{}) do
    path = Routes.patch_status(resource)
    operation_or_error(path, :patch, resource)
  end

  @doc """
  Returns a `PATCH` operation for a resource's status by version, kind, name, and optionally namespace.

  ## Examples
      iex> K8s.Client.patch_status("apps/v1", "Deployment", namespace: "test", name: "nginx")
      %K8s.Client.Operation{
        method: :patch,
        path: "/apis/apps/v1/namespaces/test/deployments/nginx/status",
        resource: nil
      }

  """
  @spec patch_status(binary, binary, options | nil) :: operation_or_error
  def patch_status(api_version, kind, opts \\ []) do
    path = Routes.patch_status(api_version, kind, opts)
    operation_or_error(path, :patch)
  end

  @doc """
  Returns a `PUT` operation for a resource's status given a manifest. May be a partial manifest as long as it contains:

    * apiVersion
    * kind
    * metadata.name
    * metadata.namespace (if applicable)

  ## Examples

      iex> pod = %{
      ...>   "apiVersion" => "v1",
      ...>   "kind" => "Pod",
      ...>   "metadata" => %{"name" => "nginx-pod", "namespace" => "test"},
      ...>   "spec" => %{"containers" => %{"image" => "nginx"}}
      ...> }
      ...> K8s.Client.put_status(pod)
      %K8s.Client.Operation{
        method: :put,
        path: "/api/v1/namespaces/test/pods/nginx-pod/status",
        resource: %{
          "apiVersion" => "v1",
          "kind" => "Pod",
          "metadata" => %{"name" => "nginx-pod", "namespace" => "test"},
          "spec" => %{"containers" => %{"image" => "nginx"}}
        }
      }
  """
  @spec put_status(map()) :: operation_or_error
  def put_status(resource = %{}) do
    path = Routes.put_status(resource)
    operation_or_error(path, :put, resource)
  end

  @doc """
  Returns a `PUT` operation for a resource's status by version, kind, name, and optionally namespace.

  ## Examples
      iex> K8s.Client.put_status("apps/v1", "Deployment", namespace: "test", name: "nginx")
      %K8s.Client.Operation{
        method: :put,
        path: "/apis/apps/v1/namespaces/test/deployments/nginx/status",
        resource: nil
      }

  """
  @spec put_status(binary, binary, options | nil) :: operation_or_error
  def put_status(api_version, kind, opts \\ []) do
    path = Routes.get_status(api_version, kind, opts)
    operation_or_error(path, :put)
  end

  @doc """
  Async run multiple operations. Operations will be returned in same order given.
  Operations will not cease in event of failure.

  ## Example

  Get a list of pods, then map each one to an individual `GET` operation:

    ```elixir
    # Get a config reference
    conf = K8s.Conf.from_file "~/.kube/config"

    # Get the pods
    operation = K8s.Client.list("v1", "Pod", namespace: :all)
    {:ok, %{"items" => pods}} = K8s.Client.run(operation, conf)

    # Map each one to an individual `GET` operation.
    operations = Enum.map(pods, fn(%{"metadata" => %{"name" => name, "namespace" => ns}}) ->
       K8s.Client.get("v1", "Pod", namespace: ns, name: name)
    end)

    # Get the results asynchronously
    results = K8s.Client.async(operations, conf)
    ```
  """
  @spec async(list(Operation.t()), Conf.t()) :: list({:ok, struct} | {:error, struct})
  def async(operations, conf) do
    operations
    |> Enum.map(&(Task.async(fn -> run(&1, conf) end)))
    |> Enum.map(&Task.await/1)
  end

  @spec run(Operation.t(), Conf.t()) :: {:ok, struct} | {:error, struct}
  def run(request = %{}, config = %{}), do: run(request, config, [])

  @spec run(Operation.t(), Conf.t(), map()) :: {:ok, struct} | {:error, struct}
  def run(request = %{}, config = %{}, body = %{}), do: run(request, config, body, [])

  @spec run(Operation.t(), Conf.t(), keyword()) :: {:ok, struct} | {:error, struct}
  def run(request = %{}, config = %{}, opts) do
    request
    |> build_http_req(config, request.resource, opts)
    |> handle_response
  end

  @spec run(Operation.t(), Conf.t(), map(), keyword()) :: {:ok, struct} | {:error, struct}
  def run(request = %{}, config = %{}, body = %{}, opts) do
    request
    |> build_http_req(config, body, opts)
    |> handle_response
  end

  @spec build_http_req(Operation.t(), Conf.t(), map(), keyword()) ::
          {:ok, HTTPoison.Response.t() | HTTPoison.AsyncResponse.t()}
          | {:error, HTTPoison.Error.t()}
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

  @spec handle_response(
          {:ok, HTTPoison.Response.t() | HTTPoison.AsyncResponse.t()}
          | {:error, HTTPoison.Error.t()}
        ) :: :ok | {:ok, map()} | {:error, binary()}
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

  @spec operation_or_error(binary, http_method, map | nil) :: operation_or_error
  defp operation_or_error(path, method, resource \\ nil) do
    case path do
      {:error, msg} ->
        {:error, msg}

      path ->
        %Operation{
          path: path,
          method: method,
          resource: resource
        }
    end
  end
end
