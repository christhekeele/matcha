defmodule Matcha.Trace.Handler.Registry do
  @moduledoc false

  alias Matcha.Trace

  def child_spec(opts) do
    %{
      id: Keyword.get(opts, :name, __MODULE__),
      start: {__MODULE__, :start_link, [opts]},
      type: :supervisor
    }
  end

  def start_link(opts \\ []) do
    Registry.start_link(
      name: Keyword.get(opts, :name, __MODULE__),
      keys: :unique,
      partitions: System.schedulers_online()
    )
  end

  def name(registry \\ __MODULE__, %Trace{} = trace) do
    {:via, Registry, {registry, trace.ref}}
  end

  def lookup(registry \\ __MODULE__, %Trace{} = trace) do
    Registry.lookup(registry, trace.ref)
  end
end
