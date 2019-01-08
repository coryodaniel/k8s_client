defmodule K8s.Codegen.Client do
  @doc false
  defmacro __using__(_opts) do
    quote do
      import K8s.Codegen.Client
      @before_compile K8s.Codegen.Client
    end
  end

  @doc false
  defmacro __before_compile__(_env) do
    operations = Enum.reduce(K8s.Config.specs(), %{}, fn spec, acc ->
      Map.merge(acc, K8s.Client.Routes.build(spec))
    end)

    for {name, metadata} <- operations do
      path_with_args = metadata["path"]
      method = metadata["method"]
      kind = metadata["kind"]
      api_version = metadata["api_version"]
      action = metadata["action"]

      matches = Regex.scan(~r/{([a-z]+)}/, path_with_args)

      arg_names =
        Enum.map(matches, fn match ->
          match |> List.last() |> String.to_atom() |> Macro.var(__MODULE__)
        end)

      # if length(arg_names) > 0 do
      #   quote do
      #     def unquote(:"#{action}")(api_version = unquote(api_version), kind = unquote(kind), unquote_splicing(arg_names)) do
      #       IO.puts "HTTP: #{unquote(method)}"
      #       unquote(:"op_path_#{name}")()
      #       |> replace_path_vars([namespace: "default"])
      #     end
      #   end
      # end

      quote do
        def unquote(:"#{action}")(api_version = unquote(api_version), kind = unquote(kind), unquote_splicing(arg_names)) do
          IO.puts "HTTP: #{unquote(method)}"
          unquote(:"op_path_#{name}")()
          |> replace_path_vars([namespace: "default"])
        end

        defp unquote(:"op_path_#{name}")() do
          unquote(path_with_args)
        end
      end
    end
  end

  @doc """
  Replaces path variables with options.

  ## Examples

      iex> K8s.Codegen.Client.replace_path_vars("/foo/{name}", name: "bar")
      "/foo/bar"

  """
  @spec replace_path_vars(binary(), keyword(atom())) :: binary()
  def replace_path_vars(path_template, opts) do
    Regex.replace(~r/\{(\w+?)\}/, path_template, fn _, var -> opts[String.to_existing_atom(var)] end)
  end
end
