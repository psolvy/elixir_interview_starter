defmodule ElixirInterviewStarter.DevicesTest do
  use ExUnit.Case, async: true

  alias ElixirInterviewStarter.Devices
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

  describe "start/1" do
    test "when success returns session", %{email: email} do
      assert {:ok,
              %CalibrationSession{
                email: ^email,
                cartridge_status: nil,
                submerged_in_water: nil,
                state: :precheck_1_started
              }} = Devices.start(email)
    end

    test "when failure returns error", %{email: email} do
      {:ok, _} = Devices.start(email)

      assert {:error, _} = Devices.start(email)
    end
  end

  describe "start_precheck_2/1" do
    test "when process exists and precheck_1 finished with success returns session", %{
      email: email
    } do
      {:ok, pid} = Genserver.start_link(email)
      Genserver.start_precheck_1(email)
      Process.send(pid, %{"precheck1" => true}, [:noconnect])

      assert {:ok,
              %CalibrationSession{
                email: ^email,
                cartridge_status: nil,
                submerged_in_water: nil,
                state: :precheck_2_started
              }} = Devices.start_precheck_2(email)
    end

    test "when process exists and precheck_1 finished with failure returns error", %{email: email} do
      {:ok, pid} = Genserver.start_link(email)
      Genserver.start_precheck_1(email)
      Process.send(pid, %{"precheck1" => false}, [:noconnect])

      assert {:error, _} = Devices.start_precheck_2(email)
    end

    test "when process does not exist returns error" do
      assert {:error, _} = Faker.Internet.email() |> Devices.start_precheck_2()
    end
  end

  describe "get_current_session/1" do
    test "when process exists returns session", %{
      email: email
    } do
      {:ok, _} = Genserver.start_link(email)

      assert {:ok,
              %CalibrationSession{
                email: ^email,
                cartridge_status: nil,
                submerged_in_water: nil,
                state: :initial
              }} = Devices.get_current_session(email)
    end

    test "when process does not exist returns nil" do
      assert {:ok, nil} = Faker.Internet.email() |> Devices.get_current_session()
    end
  end
end
