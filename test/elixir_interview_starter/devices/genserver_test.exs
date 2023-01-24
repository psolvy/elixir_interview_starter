defmodule ElixirInterviewStarter.Devices.GenserverTest do
  use ExUnit.Case, async: true

  alias ElixirInterviewStarter.Devices.Genserver
  alias ElixirInterviewStarter.CalibrationSession

  setup do
    on_exit(fn ->
      ElixirInterviewStarter.Devices.Supervisor.terminate_all()
      # this one for give registry some time to clear trminated processes names
      Process.sleep(1)
    end)

    {:ok, %{email: Faker.Internet.email()}}
  end

  describe "start_link/1" do
    test "returns success when process name does not exist", %{email: email} do
      assert {:ok, _} = Genserver.start_link(email)
    end

    test "returns error when process name exists", %{email: email} do
      assert {:ok, _} = Genserver.start_link(email)
      assert {:error, {:already_started, _}} = Genserver.start_link(email)
    end
  end

  describe "start_precheck_1/1" do
    test "returns session with new state", %{email: email} do
      {:ok, _} = Genserver.start_link(email)

      assert %CalibrationSession{
               email: ^email,
               state: :precheck_1_started,
               cartridge_status: nil,
               submerged_in_water: nil
             } = Genserver.start_precheck_1(email)
    end
  end

  describe "start_precheck_2/1" do
    setup %{email: email} do
      {:ok, pid} = Genserver.start_link(email)
      Genserver.start_precheck_1(email)

      {:ok, %{email: email, pid: pid}}
    end

    test "returns success with updated state when precheck_1 finished with success", %{
      email: email,
      pid: pid
    } do
      Process.send(pid, %{"precheck1" => true}, [:noconnect])

      assert {:ok,
              %CalibrationSession{
                email: ^email,
                state: :precheck_2_started,
                cartridge_status: nil,
                submerged_in_water: nil
              }} = Genserver.start_precheck_2(email)
    end

    test "returns error when precheck_1 does not finished with success", %{
      email: email
    } do
      assert {:error,
              %CalibrationSession{
                email: ^email,
                state: :precheck_1_started,
                cartridge_status: nil,
                submerged_in_water: nil
              }} = Genserver.start_precheck_2(email)
    end
  end

  describe "get_device/1" do
    test "returns session", %{email: email} do
      {:ok, _} = Genserver.start_link(email)

      assert %CalibrationSession{
               email: ^email,
               state: :initial,
               cartridge_status: nil,
               submerged_in_water: nil
             } = Genserver.get_device(email)
    end
  end

  describe "handle_info/2" do
    setup %{email: email} do
      {:ok, pid} = Genserver.start_link(email)

      {:ok, %{email: email, pid: pid}}
    end

    test "with precheck1 => true in state precheck_1_started update state to successed", %{
      email: email,
      pid: pid
    } do
      Genserver.start_precheck_1(email)
      Process.send(pid, %{"precheck1" => true}, [:noconnect])

      assert %CalibrationSession{
               email: ^email,
               state: :precheck_1_finished_with_success,
               cartridge_status: nil,
               submerged_in_water: nil
             } = Genserver.get_device(email)
    end

    test "with precheck1 => false in state precheck_1_started update state to successed", %{
      email: email,
      pid: pid
    } do
      Genserver.start_precheck_1(email)
      Process.send(pid, %{"precheck1" => false}, [:noconnect])

      assert %CalibrationSession{
               email: ^email,
               state: :precheck_1_finished_with_failure,
               cartridge_status: nil,
               submerged_in_water: nil
             } = Genserver.get_device(email)
    end

    test "precheck1 in other states does not update state", %{
      email: email,
      pid: pid
    } do
      Process.send(pid, %{"precheck1" => true}, [:noconnect])
      Process.send(pid, %{"precheck1" => false}, [:noconnect])

      assert %CalibrationSession{
               email: ^email,
               state: :initial,
               cartridge_status: nil,
               submerged_in_water: nil
             } = Genserver.get_device(email)
    end

    test "with cartridgeStatus => true and when submerged_in_water in state precheck_2_started starts calibration",
         %{
           email: email,
           pid: pid
         } do
      Genserver.start_precheck_1(email)
      Process.send(pid, %{"precheck1" => true}, [:noconnect])
      {:ok, _} = Genserver.start_precheck_2(email)
      Process.send(pid, %{"submergedInWater" => true}, [:noconnect])
      Process.send(pid, %{"cartridgeStatus" => true}, [:noconnect])

      assert %CalibrationSession{
               email: ^email,
               state: :calibration_started,
               cartridge_status: true,
               submerged_in_water: true
             } = Genserver.get_device(email)
    end

    test "with cartridgeStatus => true and when not submerged_in_water in state precheck_2_started updates session",
         %{
           email: email,
           pid: pid
         } do
      Genserver.start_precheck_1(email)
      Process.send(pid, %{"precheck1" => true}, [:noconnect])
      {:ok, _} = Genserver.start_precheck_2(email)
      Process.send(pid, %{"cartridgeStatus" => true}, [:noconnect])

      assert %CalibrationSession{
               email: ^email,
               state: :precheck_2_started,
               cartridge_status: true,
               submerged_in_water: nil
             } = Genserver.get_device(email)
    end

    test "with cartridgeStatus => false in state precheck_2_started updates session", %{
      email: email,
      pid: pid
    } do
      Genserver.start_precheck_1(email)
      Process.send(pid, %{"precheck1" => true}, [:noconnect])
      {:ok, _} = Genserver.start_precheck_2(email)
      Process.send(pid, %{"cartridgeStatus" => false}, [:noconnect])

      assert %CalibrationSession{
               email: ^email,
               state: :precheck_2_finished_with_failure,
               cartridge_status: nil,
               submerged_in_water: nil
             } = Genserver.get_device(email)
    end

    test "cartridgeStatus in other states does not update state", %{email: email, pid: pid} do
      Genserver.start_precheck_1(email)
      Process.send(pid, %{"precheck1" => true}, [:noconnect])
      Process.send(pid, %{"cartridgeStatus" => true}, [:noconnect])
      Process.send(pid, %{"cartridgeStatus" => false}, [:noconnect])

      assert %CalibrationSession{
               email: ^email,
               state: :precheck_1_finished_with_success,
               cartridge_status: nil,
               submerged_in_water: nil
             } = Genserver.get_device(email)
    end

    test "with submergedInWater => true and when cartridge_status in state precheck_2_started starts calibration",
         %{
           email: email,
           pid: pid
         } do
      Genserver.start_precheck_1(email)
      Process.send(pid, %{"precheck1" => true}, [:noconnect])
      {:ok, _} = Genserver.start_precheck_2(email)
      Process.send(pid, %{"cartridgeStatus" => true}, [:noconnect])
      Process.send(pid, %{"submergedInWater" => true}, [:noconnect])

      assert %CalibrationSession{
               email: ^email,
               state: :calibration_started,
               cartridge_status: true,
               submerged_in_water: true
             } = Genserver.get_device(email)
    end

    test "with submergedInWater => true and when not submerged_in_water in state precheck_2_started updates session",
         %{
           email: email,
           pid: pid
         } do
      Genserver.start_precheck_1(email)
      Process.send(pid, %{"precheck1" => true}, [:noconnect])
      {:ok, _} = Genserver.start_precheck_2(email)
      Process.send(pid, %{"submergedInWater" => true}, [:noconnect])

      assert %CalibrationSession{
               email: ^email,
               state: :precheck_2_started,
               cartridge_status: nil,
               submerged_in_water: true
             } = Genserver.get_device(email)
    end

    test "with submergedInWater => false in state precheck_2_started updates session", %{
      email: email,
      pid: pid
    } do
      Genserver.start_precheck_1(email)
      Process.send(pid, %{"precheck1" => true}, [:noconnect])
      {:ok, _} = Genserver.start_precheck_2(email)
      Process.send(pid, %{"submergedInWater" => false}, [:noconnect])

      assert %CalibrationSession{
               email: ^email,
               state: :precheck_2_finished_with_failure,
               cartridge_status: nil,
               submerged_in_water: nil
             } = Genserver.get_device(email)
    end

    test "submergedInWater in other states does not update state", %{email: email, pid: pid} do
      Genserver.start_precheck_1(email)
      Process.send(pid, %{"precheck1" => true}, [:noconnect])
      Process.send(pid, %{"submergedInWater" => true}, [:noconnect])
      Process.send(pid, %{"submergedInWater" => false}, [:noconnect])

      assert %CalibrationSession{
               email: ^email,
               state: :precheck_1_finished_with_success,
               cartridge_status: nil,
               submerged_in_water: nil
             } = Genserver.get_device(email)
    end

    test "with calibrated => true in state calibration_started updates to final state",
         %{email: email, pid: pid} do
      Genserver.start_precheck_1(email)
      Process.send(pid, %{"precheck1" => true}, [:noconnect])
      {:ok, _} = Genserver.start_precheck_2(email)
      Process.send(pid, %{"cartridgeStatus" => true}, [:noconnect])
      Process.send(pid, %{"submergedInWater" => true}, [:noconnect])
      Process.send(pid, %{"calibrated" => true}, [:noconnect])

      assert %CalibrationSession{
               email: ^email,
               state: :calibration_finished_with_success,
               cartridge_status: true,
               submerged_in_water: true
             } = Genserver.get_device(email)
    end

    test "with calibrated => false in state calibration_started updates to error state",
         %{email: email, pid: pid} do
      Genserver.start_precheck_1(email)
      Process.send(pid, %{"precheck1" => true}, [:noconnect])
      {:ok, _} = Genserver.start_precheck_2(email)
      Process.send(pid, %{"cartridgeStatus" => true}, [:noconnect])
      Process.send(pid, %{"submergedInWater" => true}, [:noconnect])
      Process.send(pid, %{"calibrated" => false}, [:noconnect])

      assert %CalibrationSession{
               email: ^email,
               state: :calibration_finished_with_failure,
               cartridge_status: true,
               submerged_in_water: true
             } = Genserver.get_device(email)
    end

    test "calibrated in other states does not update state", %{email: email, pid: pid} do
      Genserver.start_precheck_1(email)
      Process.send(pid, %{"precheck1" => true}, [:noconnect])
      {:ok, _} = Genserver.start_precheck_2(email)
      Process.send(pid, %{"calibrated" => true}, [:noconnect])
      Process.send(pid, %{"calibrated" => false}, [:noconnect])

      assert %CalibrationSession{
               email: ^email,
               state: :precheck_2_started,
               cartridge_status: nil,
               submerged_in_water: nil
             } = Genserver.get_device(email)
    end
  end
end
