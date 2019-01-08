defmodule K8s.Client.Codegen do
  @doc false
  alias K8s.Client.RouteData

  defmacro __using__(_opts) do
    quote do
      import K8s.Client.Codegen
      @before_compile K8s.Client.Codegen
    end
  end

  @doc false
  defmacro __before_compile__(_env) do
    operations = Enum.reduce(RouteData.specs(), %{}, fn spec, acc ->
      Map.merge(acc, RouteData.build(spec))
    end)

    for {name, metadata} <- operations do
      path_with_args = metadata["path"]
      _method = metadata["method"]
      kind = metadata["kind"]
      api_version = metadata["api_version"]

      matches = Regex.scan(~r/{([a-z]+)}/, path_with_args)
      arg_names =
        Enum.map(matches, fn match ->
          match |> List.last() |> String.to_atom()
          # |> Macro.var(__MODULE__)
        end)

      func_name = gen_func_name(metadata)

      quote do
        def unquote(:"#{func_name}")(api_version = unquote(api_version), kind = unquote(kind), opts) do
          case valid_opts?(unquote(arg_names), opts) do
            :ok -> unquote(:"op_path_#{name}")() |> replace_path_vars(opts)
            error -> error
          end
        end

        # Private operation/path method
        defp unquote(:"op_path_#{name}")() do
          unquote(path_with_args)
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
      {:error, "Missing required option: name}

  """
  @spec valid_opts?([atom()], keyword(atom())) :: :ok | {:error, binary()}
  def valid_opts?(expected, opts) do
    actual = Keyword.keys(opts)
    case expected -- actual do
      [] -> :ok
      missing -> {:error, "Missing required option: #{Enum.join(missing, ",")}"}
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
    Regex.replace(~r/\{(\w+?)\}/, path_template, fn _, var -> opts[String.to_existing_atom(var)] end)
  end
end
