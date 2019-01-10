defmodule K8s.Client.Request do
  @moduledoc """
  Encapsulates a k8s HTTP Request
  """
  @type t :: %__MODULE__{
          method: atom(),
          path: String.t(),
          resource: map()
        }

  defstruct [:method, :path, :resource]
end
