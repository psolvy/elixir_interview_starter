defmodule ElixirInterviewStarter do
  @moduledoc """
  See `README.md` for instructions on how to approach this technical challenge.
  """

  alias ElixirInterviewStarter.Devices

  defdelegate start(user_email), to: Devices
  defdelegate start_precheck_2(user_email), to: Devices
  defdelegate get_current_session(user_email), to: Devices
end
