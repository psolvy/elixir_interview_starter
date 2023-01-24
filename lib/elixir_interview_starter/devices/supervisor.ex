defmodule ElixirInterviewStarter.Devices.Supervisor do
  @moduledoc """
  dynamic supervisor for ElixirInterviewStarter.Devices.Genserver
  """

  use DynamicSupervisor

  def create(email),
    do:
      DynamicSupervisor.start_child(__MODULE__, {ElixirInterviewStarter.Devices.Genserver, email})

  def terminate_all() do
    DynamicSupervisor.which_children(__MODULE__)
    |> Enum.map(fn {_, pid, _, _} -> DynamicSupervisor.terminate_child(__MODULE__, pid) end)
  end

  @impl true
  def init(_arg),
    do: DynamicSupervisor.init(strategy: :one_for_one)

  def start_link(arg),
    do: DynamicSupervisor.start_link(__MODULE__, arg, name: __MODULE__)
end
