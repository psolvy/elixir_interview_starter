defmodule ElixirInterviewStarter.Devices do
  @moduledoc false

  alias ElixirInterviewStarter.CalibrationSession
  alias ElixirInterviewStarter.Devices

  @spec start(String.t()) :: {:ok, CalibrationSession.t()} | {:error, String.t()}
  @doc """
  Creates a new `CalibrationSession` for the provided user, starts a `GenServer` process
  for the session, and starts precheck 1.

  If the user already has an ongoing `CalibrationSession`, returns an error.
  """
  def start(user_email) do
    case Devices.Supervisor.create(user_email) do
      {:ok, _pid} ->
        {:ok, Devices.Genserver.start_precheck_1(user_email)}

      {:error, {:already_started, _pid}} ->
        {:error, "Calibration process already started for device #{user_email}"}
    end
  end

  @spec start_precheck_2(String.t()) :: {:ok, CalibrationSession.t()} | {:error, String.t()}
  @doc """
  Starts the precheck 2 step of the ongoing `CalibrationSession` for the provided user.

  If the user has no ongoing `CalibrationSession`, their `CalibrationSession` is not done
  with precheck 1, or their calibration session has already completed precheck 2, returns
  an error.
  """
  def start_precheck_2(user_email) do
    with [{_pid, _}] <- Registry.lookup(ElixirInterviewStarter.Devices.Registry, user_email),
         {:ok, session} <- Devices.Genserver.start_precheck_2(user_email) do
      {:ok, session}
    else
      [] ->
        {:error, "Calibration process did not start for device #{user_email}"}

      {:error, %{state: state}} ->
        {:error, "Calibration process finished with failure on status #{state}"}
    end
  end

  @spec get_current_session(String.t()) :: {:ok, CalibrationSession.t() | nil}
  @doc """
  Retrieves the ongoing `CalibrationSession` for the provided user, if they have one
  """
  def get_current_session(user_email) do
    case Registry.lookup(ElixirInterviewStarter.Devices.Registry, user_email) do
      [{_pid, _}] ->
        {:ok, Devices.Genserver.get_device(user_email)}

      [] ->
        {:ok, nil}
    end
  end
end
