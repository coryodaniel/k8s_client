defmodule K8s.Client do
  use K8s.Codegen.Client

  # @path_opts [:name, :namespace]

  # @spec routes() :: map()
  # def routes(), do: @routes

  # @spec routes(binary) :: map()
  # def routes(key), do: @routes[key]

  # @spec routes(binary, binary) :: map()
  # def routes(key, item), do: @routes[key][item]

  # @doc """
  # ## Options
  #   #{Enum.join(@path_opts, ", ")}
  # """
  # def list_path(api_version, kind, opts) do
  #   key = Routes.route_key("list", api_version, kind, opts[:namespace])
  #   path_params = routes(key, "path_params")
  #   case validate_opts(opts, path_params) do
  #     {:ok, opts} ->
  #       key |> routes("path") |> replace_path_vars(opts)
  #     {:error, message} -> {:error, message}
  #   end
  # end

  # def post_path(api_version, kind, opts) do
  #   key = Routes.route_key("post", api_version, kind, opts[:namespace])
  #   path_params = routes(key, "path_params")
  #   case validate_opts(opts, path_params) do
  #     {:ok, opts} ->
  #       key |> routes("path") |> replace_path_vars(opts)
  #     {:error, message} -> {:error, message}
  #   end
  # end

  # def put_path(api_version, kind, opts) do
  #   key = Routes.route_key("put", api_version, kind, opts[:namespace])
  #   path_params = routes(key, "path_params")
  #   case validate_opts(opts, path_params) do
  #     {:ok, opts} ->
  #       key |> routes("path") |> replace_path_vars(opts)
  #     {:error, message} -> {:error, message}
  #   end
  # end

  # def patch_path(api_version, kind, opts) do
  #   key = Routes.route_key("patch", api_version, kind, opts[:namespace])
  #   path_params = routes(key, "path_params")
  #   case validate_opts(opts, path_params) do
  #     {:ok, opts} ->
  #       key |> routes("path") |> replace_path_vars(opts)
  #     {:error, message} -> {:error, message}
  #   end
  # end

  # def patch_status_path(api_version, kind, opts) do
  #   key = Routes.route_key("patch_status", api_version, kind, opts[:namespace])
  #   path_params = routes(key, "path_params")
  #   case validate_opts(opts, path_params) do
  #     {:ok, opts} ->
  #       key |> routes("path") |> replace_path_vars(opts)
  #     {:error, message} -> {:error, message}
  #   end
  # end

  # def put_status_path(api_version, kind, opts) do
  #   key = Routes.route_key("put_status", api_version, kind, opts[:namespace])
  #   path_params = routes(key, "path_params")
  #   case validate_opts(opts, path_params) do
  #     {:ok, opts} ->
  #       key |> routes("path") |> replace_path_vars(opts)
  #     {:error, message} -> {:error, message}
  #   end
  # end

  # def delete_path(api_version, kind, opts) do
  #   key = Routes.route_key("delete", api_version, kind, opts[:namespace])
  #   path_params = routes(key, "path_params")
  #   case validate_opts(opts, path_params) do
  #     {:ok, opts} ->
  #       key |> routes("path") |> replace_path_vars(opts)
  #     {:error, message} -> {:error, message}
  #   end
  # end

  # def delete_collection_path(api_version, kind, opts) do
  #   key = Routes.route_key("deletecollection", api_version, kind, opts[:namespace])
  #   path_params = routes(key, "path_params")
  #   case validate_opts(opts, path_params) do
  #     {:ok, opts} ->
  #       key |> routes("path") |> replace_path_vars(opts)
  #     {:error, message} -> {:error, message}
  #   end
  # end

  # def get_path(api_version, kind, opts) do
  #   key = Routes.route_key("get", api_version, kind, opts[:namespace])
  #   path_params = routes(key, "path_params")
  #   case validate_opts(opts, path_params) do
  #     {:ok, opts} ->
  #       key |> routes("path") |> replace_path_vars(opts)
  #     {:error, message} -> {:error, message}
  #   end
  # end

  # def get_log_path(api_version, kind, opts) do
  #   key = Routes.route_key("get_log", api_version, kind, opts[:namespace])
  #   path_params = routes(key, "path_params")
  #   case validate_opts(opts, path_params) do
  #     {:ok, opts} ->
  #       key |> routes("path") |> replace_path_vars(opts)
  #     {:error, message} -> {:error, message}
  #   end
  # end

  # def get_status_path(api_version, kind, opts) do
  #   key = Routes.route_key("get_status", api_version, kind, opts[:namespace])
  #   path_params = routes(key, "path_params")
  #   case validate_opts(opts, path_params) do
  #     {:ok, opts} ->
  #       key |> routes("path") |> replace_path_vars(opts)
  #     {:error, message} -> {:error, message}
  #   end
  # end

  # def validate_opts(opts, path_params) do
  #   # TODO: implement {:error} case
  #   # required_params(path_params)
  #   #   some of the path_params are query string and need to be removed
  #   # @path_opts
  #   {:ok, opts}
  # end

  # def required_params(path_params), do: path_params |> Enum.map(&( String.to_existing_atom(&1["name"])))

  # # Enum.each(~w(create list read connect patch replace delete), fn func_name ->
  # #   @doc """
  # #   #{func_name}_path
  # #
  # #   Options may include: #{inspect(@args)}
  # #   """
  # #   def unquote(:"#{func_name}_path")(api_version, kind, opts \\ []),
  # #     do: generate(unquote(func_name), api_version, kind, opts)
  # # end)

  # @spec replace_path_vars(binary, keyword(atom)) :: binary()
  # defp replace_path_vars(path_template, opts) do
  #   Regex.replace(~r/\{(\w+?)\}/, path_template, fn _, var -> opts[String.to_existing_atom(var)] end)
  # end
end
