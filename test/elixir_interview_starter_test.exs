defmodule ElixirInterviewStarterTest do
  use ExUnit.Case

  alias ElixirInterviewStarter.CalibrationSession

  setup do
    on_exit(fn ->
      ElixirInterviewStarter.Devices.Supervisor.terminate_all()
      # this one for give registry some time to clear trminated processes names
      Process.sleep(1)
    end)

    {:ok, %{email: Faker.Internet.email()}}
  end

  test "can successfuly calibrate device", %{email: email} do
    assert {:ok,
            %CalibrationSession{
              email: ^email,
              state: :precheck_1_started,
              cartridge_status: nil,
              submerged_in_water: nil
            }} = ElixirInterviewStarter.start(email)

    [{pid, _}] = Registry.lookup(ElixirInterviewStarter.Devices.Registry, email)
    Process.send(pid, %{"precheck1" => true}, [:noconnect])

    assert {:ok,
            %ElixirInterviewStarter.CalibrationSession{
              email: ^email,
              cartridge_status: nil,
              submerged_in_water: nil,
              state: :precheck_1_finished_with_success
            }} = ElixirInterviewStarter.get_current_session(email)

    assert {:ok,
            %CalibrationSession{
              email: ^email,
              state: :precheck_2_started,
              cartridge_status: nil,
              submerged_in_water: nil
            }} = ElixirInterviewStarter.start_precheck_2(email)

    Process.send(pid, %{"cartridgeStatus" => true}, [:noconnect])

    assert {:ok,
            %ElixirInterviewStarter.CalibrationSession{
              email: ^email,
              cartridge_status: true,
              submerged_in_water: nil,
              state: :precheck_2_started
            }} = ElixirInterviewStarter.get_current_session(email)

    Process.send(pid, %{"submergedInWater" => true}, [:noconnect])

    assert {:ok,
            %ElixirInterviewStarter.CalibrationSession{
              email: ^email,
              cartridge_status: true,
              submerged_in_water: true,
              state: :calibration_started
            }} = ElixirInterviewStarter.get_current_session(email)

    Process.send(pid, %{"calibrated" => true}, [:noconnect])

    assert {:ok,
            %ElixirInterviewStarter.CalibrationSession{
              email: ^email,
              cartridge_status: true,
              submerged_in_water: true,
              state: :calibration_finished_with_success
            }} = ElixirInterviewStarter.get_current_session(email)
  end
end
