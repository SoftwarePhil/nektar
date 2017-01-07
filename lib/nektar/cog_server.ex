defmodule Nektar.CogServer do
    alias Nektar.Cog, as: Cog
    use GenServer

    def start_link(sup, config) do
        {:ok, pid} = GenServer.start_link(__MODULE__, [sup, config], name: __MODULE__)
        
        {:ok, pid}
    end

    def init([sup, config]) do
        send self, {:init_done, {sup, config}}
        {:ok, {sup, config}}
    end

    
    def handle_info({:init_done, {sup, config}}, _) do
        spec = Supervisor.Spec.supervisor(Nektar.CogSupervisor, [], [restart: :temporary])
        {:ok, pid} = Supervisor.start_child(sup, spec)
        IO.inspect {pid, sup}
        {:noreply, {build_cogs(pid, config), sup}}
    end

    def build_cogs(sup, amount) do
        IO.inspect {sup, amount}
        IO.puts "building"
        Enum.map(0..amount, fn(x) ->
                Supervisor.start_child(sup, [self, x, x])
                |>IO.inspect 
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