defmodule K8s.Client.Codegen do
  @moduledoc false
  alias K8s.Client.Swagger
  @operations Swagger.build(Swagger.spec())

  defmacro __using__(_opts) do
    quote do
      import K8s.Client.Codegen
      @before_compile K8s.Client.Codegen
    end
  end

  @doc false
  defmacro __before_compile__(_env) do
    func_names =
      @operations
      |> Enum.map(fn {_name, metadata} -> Swagger.gen_action_name(metadata) end)
      |> Enum.uniq()

    header_funcs = make_header_functions(func_names)
    funcs = make_functions(@operations)
    base_case_funcs = make_base_case_functions(func_names)

    header_funcs ++ funcs ++ base_case_funcs
  end

  # Make "header" functions that destructure maps into argument lists.
  defp make_header_functions(func_names) do
    for header_func <- func_names do
      quote do
        def unquote(:"#{header_func}")(%{
              "apiVersion" => v,
              "kind" => k,
              "metadata" => %{"name" => name, "namespace" => ns}
            }) do
          unquote(:"#{header_func}")(v, k, namespace: ns, name: name)
        end

        def unquote(:"#{header_func}")(%{
              "apiVersion" => v,
              "kind" => k,
              "metadata" => %{"name" => name}
            }) do
          unquote(:"#{header_func}")(v, k, name: name)
        end

        def unquote(:"#{header_func}")(%{
              "apiVersion" => v,
              "kind" => k,
              "metadata" => %{"namespace" => ns}
            }) do
          unquote(:"#{header_func}")(v, k, namespace: ns)
        end

        def unquote(:"#{header_func}")(%{"apiVersion" => v, "kind" => k}) do
          unquote(:"#{header_func}")(v, k, [])
        end
      end
    end
  end

  # Make route/path interpolation functions
  defp make_functions(operations) do
    for {_name, metadata} <- operations do
      path_with_args = metadata["path"]
      kind = metadata["kind"]
      api_version = metadata["api_version"]
      func_name = Swagger.gen_action_name(metadata)
      arg_names = Swagger.find_args(path_with_args)

      quote do
        def unquote(:"#{func_name}")(
              api_version = unquote(api_version),
              kind = unquote(kind),
              opts
            ) do
          case valid_opts?(unquote(arg_names), opts) do
            :ok -> Swagger.replace_path_vars(unquote(path_with_args), opts)
            error -> error
          end
        end
      end
    end
  end

  # failure case functions for unsupported operations
  def make_base_case_functions(func_names) do
    for base_case_func <- func_names do
      quote do
        def unquote(:"#{base_case_func}")(api_version, kind, opts) do
          {:error,
           "No kubernetes operation for #{kind}(#{api_version}); Options: #{inspect(opts)}"}
        end
      end
    end
  end

  @doc """
  Validates path options

  ## Examples

      iex> K8s.Client.Codegen.valid_opts?([:name], name: "bar")
      :ok

      iex> K8s.Client.Codegen.valid_opts?([:name], foo: "bar")
      {:error, "Missing required parameter: name}

  """
  @spec valid_opts?([atom()], keyword(atom())) :: :ok | {:error, binary()}
  def valid_opts?(expected, opts) do
    actual = Keyword.keys(opts)

    case expected -- actual do
      [] -> :ok
      missing -> {:error, "Missing required parameter: #{Enum.join(missing, ", ")}"}
    end
  end
end
