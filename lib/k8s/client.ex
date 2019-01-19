defmodule K8s.Client do
  @moduledoc """
  An experimental k8s client.

  Functions return `K8s.Client.Operation`s that represent kubernetes operations.

  To run operations pass them to: `run/2`, `run/3`, or `run/4`.

  When specifying kinds the format should either be in the literal kubernetes kind name (eg `"ServiceAccount"`)
  or the downcased version seen in kubectl (eg `"serviceaccount"`). A string or atom may be used.

  ## Examples
  ```elixir
  "Deployment", "deployment", :Deployment, :deployment
  "ServiceAccount", "serviceaccount", :ServiceAccount, :serviceaccount
  "HorizontalPodAutoscaler", "horizontalpodautoscaler", :HorizontalPodAutoscaler, :horizontalpodautoscaler
  ```
  """

  alias K8s.Conf
  alias K8s.Client.{Operation, Route, Router}
  @allow_http_body [:put, :patch, :post]
  @type operation_or_error :: Operation.t() | {:error, binary()}
  @type option :: {:name, String.t()} | {:namespace, binary() | :all}
  @type options :: [option]
  @type http_method :: :get | :put | :patch | :post | :head | :options | :delete
  @type result :: :ok | {:ok, map()} | {:error, binary()}

  @doc "Alias of `create/1`"
  defdelegate post(resource), to: __MODULE__, as: :create

  @doc "Alias of `replace/1`"
  defdelegate update(resource), to: __MODULE__, as: :replace

  @doc "Alias of `replace/1`"
  defdelegate put(resource), to: __MODULE__, as: :replace

  @doc """
  Returns a `GET` operation for a resource given a manifest. May be a partial manifest as long as it contains:

    * apiVersion
    * kind
    * metadata.name
    * metadata.namespace (if applicable)

  [K8s Docs](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.13/):

  > Get will retrieve a specific resource object by name.

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
        path: "/api/v1/namespaces/test/pods/nginx-pod"
      }
  """
  @spec get(map()) :: operation_or_error
  def get(resource = %{}) do
    path = Router.path_for(:get, resource)
    operation_or_error(path, :get, resource)
  end

  @doc """
  Returns a `GET` operation for a resource by version, kind, name, and optionally namespace.

  [K8s Docs](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.13/):

  > Get will retrieve a specific resource object by name.

  ## Examples

      iex> K8s.Client.get("apps/v1", "Deployment", namespace: "test", name: "nginx")
      %K8s.Client.Operation{
        method: :get,
        path: "/apis/apps/v1/namespaces/test/deployments/nginx"
      }

      iex> K8s.Client.get("apps/v1", :deployment, namespace: "test", name: "nginx")
      %K8s.Client.Operation{
        method: :get,
        path: "/apis/apps/v1/namespaces/test/deployments/nginx"
      }

  """
  @spec get(binary, binary, options | nil) :: operation_or_error
  def get(api_version, kind, opts \\ []) do
    path = Router.path_for(:get, api_version, kind, opts)
    operation_or_error(path, :get)
  end

  @doc """
  Returns a `GET` operation to list all resources by version, kind, and namespace.

  Given the namespace `:all` as an atom, will perform a list across all namespaces.

  [K8s Docs](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.13/):

  > List will retrieve all resource objects of a specific type within a namespace, and the results can be restricted to resources matching a selector query.
  > List All Namespaces: Like List but retrieves resources across all namespaces.

  ## Examples

      iex> K8s.Client.list("v1", "Pod", namespace: "default")
      %K8s.Client.Operation{
        method: :get,
        path: "/api/v1/namespaces/default/pods"
      }

      iex> K8s.Client.list("apps/v1", "Deployment", namespace: :all)
      %K8s.Client.Operation{
        method: :get,
        path: "/apis/apps/v1/deployments"
      }

  """
  @spec list(binary, binary, options | nil) :: operation_or_error
  def list(api_version, kind, namespace: :all) do
    path = Router.path_for(:list_all_namespaces, api_version, kind)
    operation_or_error(path, :get)
  end

  def list(api_version, kind, namespace: namespace) do
    path = Router.path_for(:list, api_version, kind, namespace: namespace)
    operation_or_error(path, :get)
  end

  @doc """
  Returns a `POST` operation to create the given resource.

  ## Examples

      iex>  deployment = %{
      ...>    "apiVersion" => "apps/v1",
      ...>    "kind" => "Deployment",
      ...>    "metadata" => %{
      ...>      "labels" => %{
      ...>        "app" => "nginx"
      ...>      },
      ...>      "name" => "nginx",
      ...>      "namespace" => "test"
      ...>    },
      ...>    "spec" => %{
      ...>      "replicas" => 2,
      ...>      "selector" => %{
      ...>        "matchLabels" => %{
      ...>          "app" => "nginx"
      ...>        }
      ...>      },
      ...>      "template" => %{
      ...>        "metadata" => %{
      ...>          "labels" => %{
      ...>            "app" => "nginx"
      ...>          }
      ...>        },
      ...>        "spec" => %{
      ...>          "containers" => %{
      ...>            "image" => "nginx",
      ...>            "name" => "nginx"
      ...>          }
      ...>        }
      ...>      }
      ...>    }
      ...>  }
      ...> K8s.Client.create(deployment)
      %K8s.Client.Operation{
        method: :post,
        path: "/apis/apps/v1/namespaces/test/deployments",
        resource: %{
          "apiVersion" => "apps/v1",
          "kind" => "Deployment",
          "metadata" => %{
            "labels" => %{
              "app" => "nginx"
            },
            "name" => "nginx",
            "namespace" => "test"
          },
          "spec" => %{
            "replicas" => 2,
            "selector" => %{
                "matchLabels" => %{
                  "app" => "nginx"
                }
            },
            "template" => %{
              "metadata" => %{
                "labels" => %{
                  "app" => "nginx"
                }
              },
              "spec" => %{
                "containers" => %{
                  "image" => "nginx",
                  "name" => "nginx"
                }
              }
            }
          }
        }
      }
  """
  @spec create(map()) :: operation_or_error
  def create(
        resource = %{
          "apiVersion" => api_version,
          "kind" => kind,
          "metadata" => %{"namespace" => ns}
        }
      ) do
    path = Router.path_for(:post, api_version, kind, namespace: ns)
    operation_or_error(path, :post, resource)
  end

  def create(resource = %{"apiVersion" => api_version, "kind" => kind}) do
    path = Router.path_for(:post, api_version, kind)
    operation_or_error(path, :post, resource)
  end

  @doc """
  Returns a `PATCH` operation to patch the given resource.

  [K8s Docs](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.13/):

  > Patch will apply a change to a specific field. How the change is merged is defined per field. Lists may either be replaced or merged. Merging lists will not preserve ordering.
  > Patches will never cause optimistic locking failures, and the last write will win. Patches are recommended when the full state is not read before an update, or when failing on optimistic locking is undesirable. When patching complex types, arrays and maps, how the patch is applied is defined on a per-field basis and may either replace the field's current value, or merge the contents into the current value.

  ## Examples

      iex>  deployment = %{
      ...>    "apiVersion" => "apps/v1",
      ...>    "kind" => "Deployment",
      ...>    "metadata" => %{
      ...>      "labels" => %{
      ...>        "app" => "nginx"
      ...>      },
      ...>      "name" => "nginx",
      ...>      "namespace" => "test"
      ...>    },
      ...>    "spec" => %{
      ...>      "replicas" => 2,
      ...>      "selector" => %{
      ...>        "matchLabels" => %{
      ...>          "app" => "nginx"
      ...>        }
      ...>      },
      ...>      "template" => %{
      ...>        "metadata" => %{
      ...>          "labels" => %{
      ...>            "app" => "nginx"
      ...>          }
      ...>        },
      ...>        "spec" => %{
      ...>          "containers" => %{
      ...>            "image" => "nginx",
      ...>            "name" => "nginx"
      ...>          }
      ...>        }
      ...>      }
      ...>    }
      ...>  }
      ...> K8s.Client.patch(deployment)
      %K8s.Client.Operation{
        method: :patch,
        path: "/apis/apps/v1/namespaces/test/deployments/nginx",
        resource: %{
          "apiVersion" => "apps/v1",
          "kind" => "Deployment",
          "metadata" => %{
            "labels" => %{
              "app" => "nginx"
            },
            "name" => "nginx",
            "namespace" => "test"
          },
          "spec" => %{
            "replicas" => 2,
            "selector" => %{
                "matchLabels" => %{
                  "app" => "nginx"
                }
            },
            "template" => %{
              "metadata" => %{
                "labels" => %{
                  "app" => "nginx"
                }
              },
              "spec" => %{
                "containers" => %{
                  "image" => "nginx",
                  "name" => "nginx"
                }
              }
            }
          }
        }
      }
  """
  @spec patch(map()) :: operation_or_error
  def patch(resource = %{}) do
    path = Router.path_for(:patch, resource)
    operation_or_error(path, :patch, resource)
  end

  @doc """
  Returns a `PUT` operation to replace/update the given resource.

  [K8s Docs](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.13/):

  > Replacing a resource object will update the resource by replacing the existing spec with the provided one. For read-then-write operations this is safe because an optimistic lock failure will occur if the resource was modified between the read and write. Note: The ResourceStatus will be ignored by the system and will not be updated. To update the status, one must invoke the specific status update operation.
  > Note: Replacing a resource object may not result immediately in changes being propagated to downstream objects. For instance replacing a ConfigMap or Secret resource will not result in all Pods seeing the changes unless the Pods are restarted out of band.

  ## Examples

      iex>  deployment = %{
      ...>    "apiVersion" => "apps/v1",
      ...>    "kind" => "Deployment",
      ...>    "metadata" => %{
      ...>      "labels" => %{
      ...>        "app" => "nginx"
      ...>      },
      ...>      "name" => "nginx",
      ...>      "namespace" => "test"
      ...>    },
      ...>    "spec" => %{
      ...>      "replicas" => 2,
      ...>      "selector" => %{
      ...>        "matchLabels" => %{
      ...>          "app" => "nginx"
      ...>        }
      ...>      },
      ...>      "template" => %{
      ...>        "metadata" => %{
      ...>          "labels" => %{
      ...>            "app" => "nginx"
      ...>          }
      ...>        },
      ...>        "spec" => %{
      ...>          "containers" => %{
      ...>            "image" => "nginx",
      ...>            "name" => "nginx"
      ...>          }
      ...>        }
      ...>      }
      ...>    }
      ...>  }
      ...> K8s.Client.replace(deployment)
      %K8s.Client.Operation{
        method: :put,
        path: "/apis/apps/v1/namespaces/test/deployments/nginx",
        resource: %{
          "apiVersion" => "apps/v1",
          "kind" => "Deployment",
          "metadata" => %{
            "labels" => %{
              "app" => "nginx"
            },
            "name" => "nginx",
            "namespace" => "test"
          },
          "spec" => %{
            "replicas" => 2,
            "selector" => %{
                "matchLabels" => %{
                  "app" => "nginx"
                }
            },
            "template" => %{
              "metadata" => %{
                "labels" => %{
                  "app" => "nginx"
                }
              },
              "spec" => %{
                "containers" => %{
                  "image" => "nginx",
                  "name" => "nginx"
                }
              }
            }
          }
        }
      }
  """
  @spec replace(map()) :: operation_or_error
  def replace(resource = %{}) do
    path = Router.path_for(:put, resource)
    operation_or_error(path, :put, resource)
  end

  @doc """
  Returns a `DELETE` operation for a resource by manifest. May be a partial manifest as long as it contains:

  * apiVersion
  * kind
  * metadata.name
  * metadata.namespace (if applicable)

  [K8s Docs](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.13/):

  > Delete will delete a resource. Depending on the specific resource, child objects may or may not be garbage collected by the server. See notes on specific resource objects for details.

  ## Examples

      iex>  deployment = %{
      ...>    "apiVersion" => "apps/v1",
      ...>    "kind" => "Deployment",
      ...>    "metadata" => %{
      ...>      "labels" => %{
      ...>        "app" => "nginx"
      ...>      },
      ...>      "name" => "nginx",
      ...>      "namespace" => "test"
      ...>    },
      ...>    "spec" => %{
      ...>      "replicas" => 2,
      ...>      "selector" => %{
      ...>        "matchLabels" => %{
      ...>          "app" => "nginx"
      ...>        }
      ...>      },
      ...>      "template" => %{
      ...>        "metadata" => %{
      ...>          "labels" => %{
      ...>            "app" => "nginx"
      ...>          }
      ...>        },
      ...>        "spec" => %{
      ...>          "containers" => %{
      ...>            "image" => "nginx",
      ...>            "name" => "nginx"
      ...>          }
      ...>        }
      ...>      }
      ...>    }
      ...>  }
      ...> K8s.Client.delete(deployment)
      %K8s.Client.Operation{
        method: :delete,
        path: "/apis/apps/v1/namespaces/test/deployments/nginx"
      }

  """
  @spec delete(map()) :: operation_or_error
  def delete(resource = %{}) do
    path = Router.path_for(:delete, resource)
    operation_or_error(path, :delete, resource)
  end

  @doc """
  Returns a `DELETE` operation for a resource by version, kind, name, and optionally namespace.

  ## Examples

      iex> K8s.Client.delete("apps/v1", "Deployment", namespace: "test", name: "nginx")
      %K8s.Client.Operation{
        method: :delete,
        path: "/apis/apps/v1/namespaces/test/deployments/nginx"
      }

  """
  @spec delete(binary, binary, options | nil) :: operation_or_error
  def delete(api_version, kind, opts) do
    path = Router.path_for(:delete, api_version, kind, opts)
    operation_or_error(path, :delete)
  end

  @doc """
  Returns a `DELETE` collection operation for all instances of a cluster scoped resource kind.

  ## Examples

      iex> K8s.Client.delete_all("extensions/v1beta1", "PodSecurityPolicy")
      %K8s.Client.Operation{
        method: :delete,
        path: "/apis/extensions/v1beta1/podsecuritypolicies"
      }

      iex> K8s.Client.delete_all("storage.k8s.io/v1", "StorageClass")
      %K8s.Client.Operation{
        method: :delete,
        path: "/apis/storage.k8s.io/v1/storageclasses"
      }
  """
  @spec delete_all(binary(), binary()) :: operation_or_error
  def delete_all(api_version, kind) do
    path = Router.path_for(:delete_collection, api_version, kind)
    operation_or_error(path, :delete)
  end

  @doc """
  Returns a `DELETE` collection operation for all instances of a resource kind in a specific namespace.

  ## Examples

      iex> Client.delete_all("apps/v1beta1", "ControllerRevision", namespace: "default")
      %K8s.Client.Operation{
        method: :delete,
        path: "/apis/apps/v1beta1/namespaces/default/controllerrevisions"
      }

      iex> Client.delete_all("apps/v1", "Deployment", namespace: "staging")
      %K8s.Client.Operation{
        method: :delete,
        path: "/apis/apps/v1/namespaces/staging/deployments"
      }
  """
  @spec delete_all(binary(), binary(), namespace: binary()) :: operation_or_error
  def delete_all(api_version, kind, namespace: namespace) do
    path = Router.path_for(:delete_collection, api_version, kind, namespace: namespace)
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
        path: "/api/v1/namespaces/test/pods/nginx-pod/log"
      }
  """
  @spec get_log(map()) :: operation_or_error
  def get_log(resource = %{}) do
    path = Router.path_for(:get_log, resource)
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
    path = Router.path_for(:get_log, api_version, kind, opts)
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
        path: "/api/v1/namespaces/test/pods/nginx-pod/status"
      }
  """
  @spec get_status(map()) :: operation_or_error
  def get_status(resource = %{}) do
    path = Router.path_for(:get_status, resource)
    operation_or_error(path, :get, resource)
  end

  @doc """
  Returns a `GET` operation for a resource's status by version, kind, name, and optionally namespace.

  ## Examples

      iex> K8s.Client.get_status("apps/v1", "Deployment", namespace: "test", name: "nginx")
      %K8s.Client.Operation{
        method: :get,
        path: "/apis/apps/v1/namespaces/test/deployments/nginx/status"
      }

  """
  @spec get_status(binary, binary, options | nil) :: operation_or_error
  def get_status(api_version, kind, opts \\ []) do
    path = Router.path_for(:get_status, api_version, kind, opts)
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
    path = Router.path_for(:patch_status, resource)
    operation_or_error(path, :patch, resource)
  end

  @doc """
  Returns a `PATCH` operation for a resource's status by version, kind, name, and optionally namespace.

  ## Examples
      iex> K8s.Client.patch_status("apps/v1", "Deployment", namespace: "test", name: "nginx")
      %K8s.Client.Operation{
        method: :patch,
        path: "/apis/apps/v1/namespaces/test/deployments/nginx/status"
      }

  """
  @spec patch_status(binary, binary, options | nil) :: operation_or_error
  def patch_status(api_version, kind, opts \\ []) do
    path = Router.path_for(:patch_status, api_version, kind, opts)
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
    path = Router.path_for(:put_status, resource)
    operation_or_error(path, :put, resource)
  end

  @doc """
  Returns a `PUT` operation for a resource's status by version, kind, name, and optionally namespace.

  ## Examples
      iex> K8s.Client.put_status("apps/v1", "Deployment", namespace: "test", name: "nginx")
      %K8s.Client.Operation{
        method: :put,
        path: "/apis/apps/v1/namespaces/test/deployments/nginx/status"
      }

  """
  @spec put_status(binary, binary, options | nil) :: operation_or_error
  def put_status(api_version, kind, opts \\ []) do
    path = Router.path_for(:put_status, api_version, kind, opts)
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
    |> Enum.map(&Task.async(fn -> run(&1, conf) end))
    |> Enum.map(&Task.await/1)
  end

  @doc """
  Runs a `K8s.Client.Operation`.

  ## Examples

  Running a list pods operation:

  ```elixir
  conf = K8s.Conf.from_file "~/.kube/config"
  operation = K8s.Client.list("v1", "Pod", namespace: :all)
  {:ok, %{"items" => pods}} = K8s.Client.run(operation, conf)
  ```

  Running a dry-run of a create deployment operation:

  ```elixir
  conf = K8s.Conf.from_file "~/.kube/config"
  deployment = %{
    "apiVersion" => "apps/v1",
    "kind" => "Deployment",
    "metadata" => %{
      "labels" => %{
        "app" => "nginx"
      },
      "name" => "nginx",
      "namespace" => "test"
    },
    "spec" => %{
      "replicas" => 2,
      "selector" => %{
        "matchLabels" => %{
          "app" => "nginx"
        }
      },
      "template" => %{
        "metadata" => %{
          "labels" => %{
            "app" => "nginx"
          }
        },
        "spec" => %{
          "containers" => %{
            "image" => "nginx",
            "name" => "nginx"
          }
        }
      }
    }
  }
  operation = K8s.Client.create(deployment)

  # opts is passed to HTTPoison as opts.
  opts = [params: %{"dryRun" => "all"}]
  :ok = K8s.Client.run(operation, conf, opts)
  ```
  """
  @spec run(Operation.t(), Conf.t()) :: result
  def run(request = %{}, config = %{}), do: run(request, config, [])

  @doc """
  See `run/2`
  """
  @spec run(Operation.t(), Conf.t(), keyword()) :: result
  def run(request = %{}, config = %{}, opts) when is_list(opts) do
    request
    |> build_http_req(config, request.resource, opts)
    |> handle_response
  end

  @doc """
  See `run/2`
  """
  @spec run(Operation.t(), Conf.t(), map(), keyword() | nil) :: result
  def run(request = %{}, config = %{}, body = %{}, opts \\ []) do
    request
    |> build_http_req(config, body, opts)
    |> handle_response
  end

  @spec build_http_req(Operation.t(), Conf.t(), map(), keyword()) ::
          {:ok, HTTPoison.Response.t() | HTTPoison.AsyncResponse.t()}
          | {:error, HTTPoison.Error.t()}
  defp build_http_req(request, config, body, opts) do
    request_options = Conf.RequestOptions.generate(config)

    url = Path.join(config.url, request.path)
    http_headers = headers(request_options)
    http_opts = Keyword.merge([ssl: request_options.ssl_options], opts)

    case http_body(body, request.method) do
      {:ok, http_body} ->
        HTTPoison.request(request.method, url, http_body, http_headers, http_opts)

      error ->
        error
    end
  end

  @spec http_body(any(), atom()) :: {:ok, binary} | {:error, binary}
  defp http_body(body, _) when not is_map(body), do: {:ok, ""}

  defp http_body(body = %{}, http_method) when http_method in @allow_http_body do
    Jason.encode(body)
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
    operation_resource =
      case method do
        method when method in @allow_http_body -> resource
        _ -> nil
      end

    case path do
      {:error, msg} ->
        {:error, msg}

      path ->
        %Operation{
          path: path,
          method: method,
          resource: operation_resource
        }
    end
  end
end
