defmodule ElixirInterviewStarter.CalibrationSession do
  @moduledoc """
  A struct representing an ongoing calibration session, used to identify who the session
  belongs to, what step the session is on, and any other information relevant to working
  with the session.
  """

  @type t() :: %__MODULE__{
          email: String.t() | nil,
          cartridge_status: boolean(),
          submerged_in_water: boolean(),
          state: atom()
        }

  defstruct ~w(email cartridge_status submerged_in_water state)a
end
