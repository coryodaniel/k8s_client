defmodule K8s.ClientTest do
  use ExUnit.Case, async: true
  alias K8s.Client
  doctest K8s.Client

  setup do
    bypass = Bypass.open()
    conf = K8s.Conf.from_file("test/support/k8s_conf.yaml")
    conf = %{conf | url: "http://localhost:#{bypass.port}/"}

    {:ok, bypass: bypass, conf: conf}
  end

  def namespace_manifest() do
    %{
      "apiVersion" => "v1",
      "metadata" => %{"name" => "test"},
      "kind" => "Namespace"
    }
  end

  def noop(), do: Jason.encode!(%{})

  describe "run/3" do
    test "running an operation without an HTTP body", %{conf: conf, bypass: bypass} do
      Bypass.expect_once(bypass, fn conn ->
        assert conn.method == "GET"
        assert conn.request_path == "/api/v1/namespaces/test"
        Plug.Conn.resp(conn, 200, noop())
      end)

      operation = Client.get(namespace_manifest())
      assert {:ok, _} = Client.run(operation, conf)
    end

    test "running an operation with an HTTP body", %{conf: conf, bypass: bypass} do
      Bypass.expect_once(bypass, fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/api/v1/namespaces"
        Plug.Conn.resp(conn, 200, noop())
      end)

      operation = Client.create(namespace_manifest())
      assert {:ok, _} = Client.run(operation, conf)
    end

    test "running an operation with options", %{conf: conf, bypass: bypass} do
      Bypass.expect_once(bypass, fn conn ->
        assert conn.method == "GET"
        assert conn.request_path == "/api/v1/namespaces/test"
        assert conn.query_string == "watch=true"
        Plug.Conn.resp(conn, 200, noop())
      end)

      operation = Client.get(namespace_manifest())
      opts = [params: %{"watch" => "true"}]
      assert {:ok, _} = Client.run(operation, conf, opts)
    end
  end

  describe "run/4" do
    test "running an operation with a custom HTTP body", %{conf: conf, bypass: bypass} do
      Bypass.expect_once(bypass, fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/api/v1/namespaces"

        {:ok, json, _} = Plug.Conn.read_body(conn)
        body = Jason.decode!(json)
        assert body["metadata"]["labels"]["env"] == "test"
        Plug.Conn.resp(conn, 200, noop())
      end)

      # This is a silly example.
      operation = Client.create(namespace_manifest())
      labels = %{"env" => "test"}
      body = put_in(namespace_manifest(), ["metadata", "labels"], labels)

      assert {:ok, _} = Client.run(operation, conf, body)
    end

    test "running an operation with a custom HTTP body and options", %{conf: conf, bypass: bypass} do
      Bypass.expect_once(bypass, fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/api/v1/namespaces"
        assert conn.query_string == "watch=true"

        {:ok, json, _} = Plug.Conn.read_body(conn)
        body = Jason.decode!(json)
        assert body["metadata"]["labels"]["env"] == "test"
        Plug.Conn.resp(conn, 200, noop())
      end)

      # This is a silly example.
      operation = Client.create(namespace_manifest())
      labels = %{"env" => "test"}
      body = put_in(namespace_manifest(), ["metadata", "labels"], labels)
      opts = [params: %{"watch" => "true"}]
      assert {:ok, _} = Client.run(operation, conf, body, opts)
    end
  end

  describe "run" do
    test "request with HTTP 201 response", %{conf: conf, bypass: bypass} do
      Bypass.expect(bypass, fn conn ->
        Plug.Conn.resp(conn, 201, "")
      end)

      operation = Client.list("v1", "Pod", namespace: :all)
      assert :ok = Client.run(operation, conf)
    end

    test "request with HTTP 404 response", %{conf: conf, bypass: bypass} do
      Bypass.expect(bypass, fn conn ->
        Plug.Conn.resp(conn, 404, "File not found.")
      end)

      operation = Client.list("v1", "Pod", namespace: :all)
      assert {:error, "HTTP Error: 404; File not found."} = Client.run(operation, conf)
    end
  end
end
