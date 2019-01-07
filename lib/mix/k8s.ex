defmodule Mix.K8s do
  @moduledoc """
  Mix task helpers
  """

  @doc "Parse CLI input"
  def parse_args(args, defaults, cli_opts \\ []) do
    {opts, parsed, invalid} = OptionParser.parse(args, cli_opts)
    merged_opts = Keyword.merge(defaults, opts)

    {merged_opts, parsed, invalid}
  end
end
