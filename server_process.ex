defmodule ServerProcess do
  @moduledoc """
  Defines a generic server process.
  """

  @spec start(atom()) :: pid()
  def start(callback_module) do
    spawn(fn ->
      initial_state = callback_module.init
      loop(callback_module, initial_state)
    end)
  end

  @spec call(pid(), any()) :: any()
  def call(server_pid, request) do
    send(server_pid, {:call, request, self()})

    receive do
      {:response, response} -> response
    end
  end

  @spec cast(pid(), any()) :: none()
  def cast(server_pid, request) do
    send(server_pid, {:cast, request})
  end

  @spec loop(atom(), any()) :: atom()
  defp loop(callback_module, current_state) do
    receive do
      {:call, request, caller} ->
        {response, new_state} = callback_module.handle_call(request, current_state)
        send(caller, {:response, response})
        loop(callback_module, new_state)

      {:cast, request} ->
        new_state = callback_module.handle_cast(request, current_state)
        loop(callback_module, new_state)
    end
  end
end

defmodule KeyValueStore do
  @moduledoc """
  Implements a simple key-value store.
  """

  @doc """
  Interface function to start the module's generic server process.
  """
  @spec start() :: pid()
  def start do
    ServerProcess.start(KeyValueStore)
  end

  @doc """
  Interface function to put values in a key.
  """
  @spec put(pid(), atom(), atom()) :: none()
  def put(pid, key, value) do
    ServerProcess.cast(pid, {:put, key, value})
  end

  @doc """
  Interface function to fetch values from a key.
  """
  @spec get(pid, atom()) :: tuple()
  def get(pid, key) do
    ServerProcess.call(pid, {:get, key})
  end

  @spec init() :: map()
  def init do
    Map.new()
  end

  @spec handle_cast(tuple(), map()) :: none()
  def handle_cast({:put, key, value}, state) do
    Map.put(state, key, value)
  end

  @spec handle_call(tuple(), map()) :: tuple()
  def handle_call({:put, key, value}, state) do
    {:ok, Map.put(state, key, value)}
  end

  @spec handle_call(tuple(), map()) :: tuple()
  def handle_call({:get, key}, state) do
    {Map.get(state, key), state}
  end
end
