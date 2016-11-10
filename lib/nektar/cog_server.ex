defmodule Nektar.CogServer do
    use GenServer
    alias Nektar.Cog, as: Cog
    alias Nektar.PolarCoordinate, as: Polar
    @name {:global, __MODULE__}

    def handle_call({:add_cog, cog = %Cog{}}, _from ,{cog_list, count}) do
        {:reply, :ok, {[cog | cog_list], count}}
    end

    def handle_call(:list, _from, {cog_list, count}) do
        {:reply, cog_list, {cog_list, count}}
    end

    @doc """
        this function takes the id of a Cog, updates it's postion with
        the delta value and sends back the other postions of the cogs
        around it 
    """
    def handle_call({:update, id, delta}, _from, {cog_list, count}) do
         {new_cog_list, cog} = Enum.map_reduce(cog_list, {}, fn(is_cog?, acc) -> 
                            case is_cog? do
                                %Cog{id: this_id} when this_id == id -> 
                                    {Cog.update_postion(is_cog?, delta), is_cog?}
                                _-> {is_cog?, acc}
                            end
                        end)
            #sending cog others postion after it's own postion is updated            
            send cog.pid, {:new, __MODULE__.relative_polarcoordinates(new_cog_list, cog)}
            {:reply, __MODULE__.relative_polarcoordinates(new_cog_list, cog), {new_cog_list, count + 1}}
    end

    def start_link(number_of_cogs) do
        pid = GenServer.start_link(__MODULE__, {[], 0}, name: @name)

        0..number_of_cogs
        |>Enum.each(fn(n) -> 
                        Cog.init(pid, n, 0, n)
                        |>__MODULE__.add_cog
                    end)
        
        #this should send a message with the postion of the other cogs around it,
        #making, which should continually send messages to the spin process
        #it is sending it's own positon thought, maybe this is okay because
        #there postion is 0,0
        Enum.each(__MODULE__.list, 
                  fn(cog) -> 
                        send cog.pid, {:new, __MODULE__.relative_polarcoordinates(__MODULE__.list, cog)} 
                  end)
    end
    
    @doc """
        This function returns all the other cogs who are not the cog passed in
        ie
            [cog1, cog2, cog3], cog3
            returns [cog1, cog2] 
    """
    def other_cogs(cog_list, cog) do
        Enum.reject(cog_list, fn(other_cog = %Cog{}) -> cog.id == other_cog.id end)
    end

    @doc """
        this function given a cog list and a cog, returns the relative polar coordinates
        of the other cogs around it.  This list of polar coordinates needs to be sent to
        a cog for it to caculaute how much it is going to move
    """
     def relative_polarcoordinates(cog_list, cog) do
        other_pos = Enum.reject(cog_list, 
                        fn(other_cog = %Cog{}) -> cog.id == other_cog.id end)
                    |>Enum.map(fn(some_cog) -> Cog.postion(some_cog) end)
                    |>Polar.relative_coordinates({cog.x, cog.y})
        other_pos
    end

    def add_cog(cog = %Cog{}) do
        :ok = GenServer.call(@name, {:add_cog, cog})
    end

    def list do
        GenServer.call(@name, :get_list)
    end

    def update(delta, id) do
        GenServer.call(@name, {:update, id, delta})
    end
end

#:TODO 
#1. give cog actually good 'swarm' behavior, 
#2. figure out how to make behaviors more flexable ..
#3. think how to represent the space they will acutally be in 
#4. sync all Cogs?  some move more, not sure how big of a deal this is?
    #they seem to be moving super fast, 100s per second
#7. Environment
#6. distrubed like gameOfLife example?
"""
Nektar.CogServer.start_link 4
list = Nektar.CogServer.cog_list 
[cog1] = Enum.take(list, 1) 
other_pos = Nektar.CogServer.relative_polarcoordinates list, cog1
delta = Nektar.Cog.behavior(other_pos)

Nektar.CogServer.update cog1.id, delta

IO.inspect Nektar.CogServer.cog_list
"""