defmodule K8s.Client.RouterTest do
  use ExUnit.Case
  alias K8s.Client.Router

  @default_k8s_spec System.get_env("K8S_SPECS") || "priv/swagger/1.13.json"
  @route_info K8s.Codegen.route_info(@default_k8s_spec)

  File.write!("./route_info.json", Jason.encode!(@route_info, pretty: true))

  # Interpolates path variables {path, namespace, name, logpath}
  def expected_path(path_template) do
    path_template
    |> String.replace("{namespace}", "foo")
    |> String.replace("{name}", "bar")
    |> String.replace("{path}", "pax")
    |> String.replace("{logpath}", "qux")
  end

  def build_arg_list(path_template) do
    matches = Regex.scan(~r/{([a-z]+)}/, path_template)

    arg_names =
      Enum.map(matches, fn match -> match |> List.last() |> String.to_existing_atom() end)

    arg_vals = %{
      namespace: "foo",
      name: "bar",
      path: "pax",
      logpath: "qux"
    }

    Enum.map(arg_names, fn arg -> arg_vals[arg] end)
  end

  Enum.each(@route_info, fn {http_method, apis} ->
    @http_method http_method
    Enum.each(apis, fn {api_version, kinds} ->
      @api_version api_version
      Enum.each(kinds, fn {kind, details} ->
        @kind kind
        @details details
        describe "#{@default_k8s_spec}: [#{@http_method}] #{@api_version} #{@kind}" do
          test "generates the path" do
            %{"method" => method, "path" => path_template} = @details
            %{"api_version" => api_version, "kind" => kind} = @details
            expected = expected_path(path_template)

            actual = apply(Router, String.to_atom(method), args)
            actual
            assert expected == actual
          end
        end
      end)
    end)
  end)

  # describe "#{@default_k8s_spec} #{@operation}" do
  #   test "path generated" do


  #     suffix = ~r/(status|scale)$/ |> Regex.scan(path_template) |> List.flatten |> List.last

  #     base_args = [api_version, kind] ++ build_arg_list(path_template)

  #     args = case suffix do
  #       nil -> base_args
  #       suffix -> base_args ++ [String.to_atom(suffix)]
  #     end

  #     # raises on missing body/queryparam required - NO, client cares about bodies, not router
  #     # allow query strings
  #     # supports_all_namespaces = Regex.match?(~r/AllNamespaces$/, operation_id)
  #     # # TODO: query string, body
  #     # # path (no, pathshould be a part of the func args)
  #     # # required params
  #     actual = apply(Router, String.to_atom(method), args)
  #     assert expected == actual
  #   end
  # end
end
