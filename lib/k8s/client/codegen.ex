defmodule K8s.Client.Codegen do
  @moduledoc false
  alias K8s.Client.Swagger

  defmacro __using__(_opts) do
    quote do
      import K8s.Client.Codegen
      @before_compile K8s.Client.Codegen
    end
  end

  @doc false
  defmacro __before_compile__(_env) do
    operations =
      Enum.reduce(Swagger.specs(), %{}, fn spec, acc ->
        Map.merge(acc, Swagger.build(spec))
      end)

    func_names =
      operations
      |> Enum.map(fn {_name, metadata} -> gen_func_name(metadata) end)
      |> Enum.uniq()

    header_funcs = make_header_functions(func_names)
    funcs = make_functions(operations)
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
      func_name = gen_func_name(metadata)

      arg_names =
        ~r/{([a-z]+)}/
        |> Regex.scan(path_with_args)
        |> Enum.map(fn match -> match |> List.last() |> String.to_atom() end)

      quote do
        def unquote(:"#{func_name}")(
              api_version = unquote(api_version),
              kind = unquote(kind),
              opts
            ) do
          case valid_opts?(unquote(arg_names), opts) do
            :ok -> replace_path_vars(unquote(path_with_args), opts)
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
  Generate a `K8s.Client` function name
  """
  @spec gen_func_name(map()) :: binary()
  @spec gen_func_name(map(), binary()) :: binary()
  def gen_func_name(metadata = %{"action" => name}), do: gen_func_name(metadata, name)
  def gen_func_name(%{"all_namespaces" => true}, name), do: "#{name}_all_namespaces"
  def gen_func_name(_, "deletecollection"), do: "delete_collection"
  def gen_func_name(_, name), do: name

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

  @doc """
  Replaces path variables with options.

  ## Examples

      iex> K8s.Client.Codegen.replace_path_vars("/foo/{name}", name: "bar")
      "/foo/bar"

  """
  @spec replace_path_vars(binary(), keyword(atom())) :: binary()
  def replace_path_vars(path_template, opts) do
    Regex.replace(~r/\{(\w+?)\}/, path_template, fn _, var ->
      opts[String.to_existing_atom(var)]
    end)
  end
end
