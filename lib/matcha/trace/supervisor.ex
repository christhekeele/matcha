defmodule Matcha.Trace.Supervisor do
  alias Matcha.Trace

  @type on_start_child :: DynamicSupervisor.on_start_child()

  defmodule Partition do
    use DynamicSupervisor

    def start_link(init_arg) do
      DynamicSupervisor.start_link(__MODULE__, init_arg)
    end

    @impl true
    def init(options) do
      DynamicSupervisor.init([strategy: :one_for_one] ++ options)
    end
  end

  def child_spec(options) do
    # {partitions, options} = Keyword.pop_lazy(options, :partitions, &System.schedulers_online/0)
    # {strategy, options} = Keyword.pop(options, :strategy, :one_for_one)
    # {max_restarts, options} = Keyword.pop(options, :max_restarts, 3)
    # {max_seconds, options} = Keyword.pop(options, :max_seconds, 5)

    options
    |> Keyword.put_new(:child_spec, __MODULE__.Partition)
    |> PartitionSupervisor.child_spec()
  end

  @spec start_tracer(Trace.t(), keyword()) :: on_start_child()
  def start_tracer(trace = %Trace{}, options \\ []) do
    {tracer_options, options} = Trace.Tracer.options(options)

    if options != [] do
      problems =
        for option <- options do
          {:error,
           "unexpected option `#{inspect(option)}` provided to `#{inspect(__MODULE__)}.start_tracer/2`"}
        end

      raise Trace.Error, source: trace, details: "when starting tracer", problems: problems
    else
      DynamicSupervisor.start_child(
        {:via, PartitionSupervisor,
         {Trace.Tracer.Supervisor, Keyword.get(tracer_options, :caller, self())}},
        {Trace.Tracer, [{:trace, trace} | tracer_options]}
      )
    end
  end

  @spec start_handler(Trace.Tracer.t(), keyword()) :: on_start_child()
  def start_handler(tracer = %Trace.Tracer{}, options \\ []) do
    {handler_options, options} = Trace.Handler.options(options)

    if options != [] do
      problems =
        for option <- options do
          {:error,
           "unexpected option `#{inspect(option)}` provided to `#{inspect(__MODULE__)}.start_handler/2`"}
        end

      raise Trace.Error,
        source: tracer.trace,
        details: "when starting handler",
        problems: problems
    else
      DynamicSupervisor.start_child(
        {:via, PartitionSupervisor, {Trace.Handler.Supervisor, tracer.caller || self()}},
        {Trace.Handler, [{:trace, tracer.trace} | handler_options]}
      )
    end
  end
end
