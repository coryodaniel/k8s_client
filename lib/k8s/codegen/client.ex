defmodule K8s.Codegen.Client do
  @doc false
  defmacro __using__(_opts) do
    quote do
      @before_compile K8s.Codegen.Client
    end
  end

  @doc false
  defmacro __before_compile__(_env) do
    operations = Enum.reduce(K8s.Config.specs(), %{}, fn spec, acc ->
      Map.merge(acc, K8s.Client.Routes.build(spec))
    end)

    Enum.each(operations, fn {name, metadata} ->
      quote do
        def unquote(:"#{name}"), do: true
      end
    end)
  end
end
