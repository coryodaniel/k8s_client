ExUnit.start()
Application.ensure_all_started(:bypass)
spec = System.get_env("K8S_SPEC") || "priv/swagger/1.13.json"
K8s.Client.Router.start_link(spec)
