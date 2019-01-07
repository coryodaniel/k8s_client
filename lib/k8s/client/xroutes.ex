defmodule K8s.Codegen.Routes do
  @moduledoc false

  @doc false
  defmacro __using__(_opts) do
    quote do
      require Logger
      import K8s.Codegen.Routes
      @before_compile K8s.Codegen.Routes
    end
  end

  @doc false
  defmacro __before_compile__(_env) do
    operations =
      K8s.Config.specs()
      |> Enum.reduce(%{}, fn spec, acc -> Map.merge(acc, K8s.Codegen.route_info(spec)) end)

    for {operation_id, operation} <- operations do
      path_with_args = operation["path"]
      method = operation["method"]
      kind = operation["kind"]
      api_version = operation["api_version"]

      matches = Regex.scan(~r/{([a-z]+)}/, path_with_args)

      arg_names =
        Enum.map(matches, fn match ->
          match |> List.last() |> String.to_atom() |> Macro.var(__MODULE__)
        end)

      suffix = ~r/(status|scale)$/ |> Regex.scan(path_with_args) |> List.flatten |> List.last

      final_args = case suffix do
        nil -> []
        suffix -> [String.to_atom(suffix)]
      end

      quote do
        def unquote(:"#{method}")(
              api_version = unquote(api_version),
              kind = unquote(kind),
              unquote_splicing(arg_names),
              unquote_splicing(final_args)
            ) do
          Logger.info(fn -> "Generating route for: #{unquote(operation_id)}" end)
          positional = [unquote_splicing(arg_names)]
          path_template = unquote(path_with_args)

          Enum.reduce(positional, path_template, fn value, path ->
            String.replace(path, ~r/{[a-z]+}/, value, global: false)
          end)
        end
      end
    end
  end
end
