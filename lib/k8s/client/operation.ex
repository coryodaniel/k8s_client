defmodule K8s.Client.Operation do
  @moduledoc """
  Encapsulates a k8s swagger operations
  """

  @type t :: %__MODULE__{
          method: atom(),
          path: String.t(),
          resource: map()
        }

  defstruct [:method, :path, :resource]
end
