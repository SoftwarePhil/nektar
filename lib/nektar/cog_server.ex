defmodule Nektar.CogServer do
    alias Nektar.Cog, as: Cog
    use GenServer

    def start_link(sup, config) do
        {:ok, pid} = GenServer.start_link(__MODULE__, [sup, config], name: __MODULE__)
        
        {:ok, pid}
    end

    def init([sup, config]) do
        send self(), {:init_done, {sup, config}}
        {:ok, {sup, config}}
    end

    def send_all do
        {cogs, _sup}  = pids()
        states = cog_states()

        Enum.each(cogs, fn(pid) -> Cog.new_states(pid, states) end)
    end

    def action_all do
        {cogs, _sup}  = pids()
        Enum.each(cogs, fn(pid) -> Cog.action(pid) end)
    end

    def cog_states do
        {cogs, _sup}  = pids()
        Enum.map(cogs, fn(pid) -> 
            Cog.state(pid) 
        end)
    end

    def pids do
        GenServer.call(__MODULE__, :get_pids)
    end

    def add_cog(x, y) do
        {_cogs, sup} = pids()
        {:ok, pid} = Supervisor.start_child(sup, [self(), {Nektar.Behavior, {x, y}}])
        GenServer.call(__MODULE__, {:add_cog, pid})
    end

    def handle_call(:get_pids, _from, state) do
        {:reply, state, state}
    end

    def handle_call({:add_cog, pid}, _from, cogs) do
        {cog_pids, sup} = cogs
        {:reply, {:ok, pid}, {cog_pids ++ pid, sup}}
    end

    def handle_info({:init_done, {sup, config}}, _) do
        spec = Supervisor.Spec.supervisor(Nektar.CogSupervisor, [], [restart: :temporary])
        {:ok, pid} = Supervisor.start_child(sup, spec)
        IO.inspect {pid, sup}
        {:noreply, {build_cogs(pid, config), pid}}
    end

    def build_cogs(sup, amount) do
        IO.inspect {sup, amount}
        IO.puts "building"
        Enum.map(0..amount, fn(x) ->
                {:ok, pid} = Supervisor.start_child(sup, [self(), {Nektar.Behavior, {x, x}}])
                pid
            end)
    end
end

"""

defmodule Nektar.CogServer do
    alias Nektar.Cog, as: Cog
    use GenServer
  

    def start_link(sup, config) do
        GenServer.start_link(__MODULE__, [sup, config], name: __MODULE__)
    end

    def init([sup, config]) do
        IO.inspect {sup, config}
        #IO.puts "hi"
     
        init(self, config, [])
    end
    
    def init(sup, amount, cogs) when amount == 0 do
        send self(), {:all_cogs, cogs, sup}
        {:ok, cogs}
    end

    def init(sup, amount, cogs) do
        IO.puts "cog {amount}"
        child = worker(Cog, [self(), amount, amount])
        {:ok, pid} = Supervisor.start_child(sup, child)
        init(sup, amount - 1, [Cog.start_link(sup, amount, amount) | cogs])
    end 
    
    def handle_info({:all_cogs, cogs, sup}, _state) do
        spec = Supervisor.Spec.supervisor(Nektar.CogSupervisor, [], [restart: :temporary])
        {:ok, pid} = Supervisor.start_child(sup, spec)
        {:noreply, cogs}
    end
end
"""