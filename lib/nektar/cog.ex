defmodule Nektar.Cog do
    @enforce_keys [:mod, :state, :sup, :count]
    defstruct [:mod, :state, :sup, :count]
    require IEx
    use GenServer
    
    @doc """
    
    """
    def start_link(other_pid, {m,a}) do
        {:ok, state} = m.start_link(a) 
        GenServer.start_link(__MODULE__, %__MODULE__{mod: m, state: state, sup: other_pid, count: 0})
    end
  
##
    def count(pid) do
        GenServer.call(pid, :count)
    end

    def new_states(pid, content) do
        GenServer.call(pid, {:new_states, content})
    end

    def action(pid) do
        GenServer.call(pid, :action)
    end

    def state(pid) do
        GenServer.call(pid, :state)
    end

    def stop(pid) do
        GenServer.call(pid, :stop)
    end
  ##
    def handle_call(:count, _from, cog) do
        {:reply, cog.count, cog}
    end

    def handle_call({:new_states, content}, _from, cog) do
        cog.mod.new_states(cog.state, content)
        {:reply, :ok, cog}
    end

    def handle_call(:action, _from, cog) do
        
        {:reply, cog.mod.action(cog.state), %{cog | count: cog.count + 1}}
    end

    def handle_call(:state, _from, cog) do
        pid = cog.state
        {:reply, cog.mod.state(pid), cog}
    end

    def handle_call(:stop, _from, cog) do
        {:stop, :normal, :ok, cog}
    end

    @doc """
        takes a cog and a polar coordinate(representing the change in postions)
        and returns a cog with a new postion and angle

        TODO: think of new name for this function
    """

    
    @doc """
        this function takes a list of polar coordinates, which are the 
        relative postions of the other cogs around it, and a function
        that maps the polar coordinates to an angle.  It returns a polar
        coordinate with radius 1 and the new angle of the cog

        does not work right now as planned because curve does all
        the reducing right now
    """
    def behavior(data, action) do
        action.(data)
    end
end