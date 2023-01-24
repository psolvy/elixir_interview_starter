defmodule ElixirInterviewStarter.Devices.Genserver do
  @moduledoc """
  genserver for calibration process
  """

  use GenServer

  alias ElixirInterviewStarter.CalibrationSession
  alias ElixirInterviewStarter.DeviceMessages

  # Client

  @precheck_timeout 30 * 1000
  @calibration_timeout 100 * 1000

  @spec start_link(String.t()) :: {:ok, pid()} | {:error, any()}
  def start_link(email),
    do: GenServer.start_link(__MODULE__, email, name: via_tuple(email))

  @spec start_precheck_1(String.t()) :: CalibrationSession.t()
  def start_precheck_1(email) do
    email
    |> via_tuple()
    |> GenServer.call(:start_precheck_1)
  end

  @spec start_precheck_2(String.t()) :: {:ok | :error, CalibrationSession.t()}
  def start_precheck_2(email) do
    email
    |> via_tuple()
    |> GenServer.call(:start_precheck_2)
  end

  @spec get_device(String.t()) :: CalibrationSession.t()
  def get_device(email) do
    email
    |> via_tuple()
    |> GenServer.call(:get_device)
  end

  @spec via_tuple(String.t()) :: {:via, module(), {module(), String.t()}}
  defp via_tuple(email),
    do: {:via, Registry, {ElixirInterviewStarter.Devices.Registry, email}}

  # # Server

  @impl true
  def init(email),
    do: {:ok, %CalibrationSession{email: email, state: :initial}}

  @impl true
  def handle_call(:start_precheck_1, _from, %{email: email} = session) do
    :ok = DeviceMessages.send(email, "startPrecheck1")
    session = %{session | state: :precheck_1_started}

    {:reply, session, session, @precheck_timeout}
  end

  def handle_call(
        :start_precheck_2,
        _from,
        %{email: email, state: :precheck_1_finished_with_success} = session
      ) do
    :ok = DeviceMessages.send(email, "startPrecheck2")
    session = %{session | state: :precheck_2_started}

    {:reply, {:ok, session}, session, @precheck_timeout}
  end

  def handle_call(:start_precheck_2, _from, session), do: {:reply, {:error, session}, session}

  def handle_call(:get_device, _from, session), do: {:reply, session, session}

  @impl true
  def handle_continue(:calibrate, %{email: email} = session) do
    :ok = DeviceMessages.send(email, "calibrate")

    {:noreply, %{session | state: :calibration_started}, @calibration_timeout}
  end

  @impl true
  def handle_info(%{"precheck1" => true}, %{state: :precheck_1_started} = session),
    do: {:noreply, %{session | state: :precheck_1_finished_with_success}}

  def handle_info(%{"precheck1" => _}, %{state: :precheck_1_started} = session),
    do: {:noreply, %{session | state: :precheck_1_finished_with_failure}}

  def handle_info(%{"precheck1" => _}, session), do: {:noreply, session}

  def handle_info(%{"cartridgeStatus" => true}, %{state: :precheck_2_started} = session) do
    if session.submerged_in_water do
      {:noreply, %{session | state: :precheck_2_finished_with_success, cartridge_status: true},
       {:continue, :calibrate}}
    else
      {:noreply, %{session | cartridge_status: true}, @precheck_timeout}
    end
  end

  def handle_info(%{"cartridgeStatus" => _}, %{state: :precheck_2_started} = session),
    do: {:noreply, %{session | state: :precheck_2_finished_with_failure}}

  def handle_info(%{"cartridgeStatus" => _}, session), do: {:noreply, session}

  def handle_info(%{"submergedInWater" => true}, %{state: :precheck_2_started} = session) do
    if session.cartridge_status do
      {:noreply, %{session | state: :precheck_2_finished_with_success, submerged_in_water: true},
       {:continue, :calibrate}}
    else
      {:noreply, %{session | submerged_in_water: true}, @precheck_timeout}
    end
  end

  def handle_info(%{"submergedInWater" => _}, %{state: :precheck_2_started} = session),
    do: {:noreply, %{session | state: :precheck_2_finished_with_failure}}

  def handle_info(%{"submergedInWater" => _}, session), do: {:noreply, session}

  def handle_info(%{"calibrated" => true}, %{state: :calibration_started} = session),
    do: {:noreply, %{session | state: :calibration_finished_with_success}}

  def handle_info(%{"calibrated" => _}, %{state: :calibration_started} = session),
    do: {:noreply, %{session | state: :calibration_finished_with_failure}}

  def handle_info(%{"calibrated" => _}, session), do: {:noreply, session}

  def handle_info(:timeout, %{state: :precheck_1_started} = session),
    do: {:noreply, %{session | state: :precheck_1_finished_with_timeout}}

  def handle_info(:timeout, %{state: :precheck_2_started} = session),
    do: {:noreply, %{session | state: :precheck_2_finished_with_timeout}}

  def handle_info(:timeout, %{state: :calibration_started} = session),
    do: {:noreply, %{session | state: :calibration_finished_with_timeout}}
end
