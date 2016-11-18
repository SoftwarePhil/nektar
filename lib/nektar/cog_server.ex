defmodule Nektar.CogServer do
    use GenServer
    alias Nektar.Cog, as: Cog
    alias Nektar.PolarCoordinate, as: Polar
    @name {:global, __MODULE__}

    require IEx

    def handle_call({:add_cog, cog = %Cog{}}, _from , {cog_list, count, size, num_done}) do
        {:reply, :ok, {[cog | cog_list], count, size + 1, num_done}}
    end

    def handle_call(:list, _from, {cog_list, count, size, num_done}) do
        {:reply, cog_list, {cog_list, count, size, num_done}}
    end

    def handle_call({:update, id, delta}, _from, {cog_list, count, size, num_done}) do
        new_cog_list = Enum.map(cog_list, fn(is_cog?) -> 
                            case cog = is_cog? do
                                %Cog{id: this_id} when this_id == id -> 
                                    :ets.insert(:history, {"cog#{cog.id}", "id: #{cog.id} \t count: #{count} \t x: #{cog.x} \t y: #{cog.y} \t angle: #{cog.theta} \t delta: #{inspect(delta)}\n"})
                                    Cog.update_postion(is_cog?, delta)
                                _-> is_cog?
                            end
                        end)
        {:reply, [], {new_cog_list, count, size, num_done}}
    end

    def handle_call({:relative_polarcoordinates, id}, _from, {cog_list, count, size, num_done}) do
        cog = Enum.find(cog_list, fn(%Cog{id: id_match?}) -> id_match?==id end)
        send cog.pid, {:new_postions, relative_polarcoordinates(cog_list, cog)}

        if size == num_done + 1 do
            Enum.each(cog_list, fn(cog = %Cog{}) -> 
                send cog.pid, :move 
            end)

             if count < 100 do
                    {:ok, file} = File.open "history/#{count}points.csv", [:write]
                    
                     point_str = Enum.reduce(cog_list, "\"X\",Y\"\n",
                                    fn (%Cog{x: x, y: y}, acc) -> acc<>"#{x},#{y}\n"
                            end)
            
                    IO.binwrite file, point_str
            end

            {:reply, [], {cog_list, count + 1, size, 0}}
        else
            {:reply, [], {cog_list, count, size, num_done + 1}}
        end
    end

    def start_link(number_of_cogs) do
        :ets.new(:history, [:duplicate_bag, :public, :named_table])
        pid = GenServer.start_link(__MODULE__, {[], 0, 0, 0}, name: @name)

        1..number_of_cogs
        |>Enum.each(fn(n) -> 
                        Cog.init(pid, n, n*4, n*7)  #pid, id, x, y
                        |>add_cog
                    end)
        
        #this should send a message with the postion of the other cogs around it,
        #making, which should continually send messages to the spin process
        #it is sending it's own positon thought, maybe this is okay because
        #there postion is 0,0
       
        Enum.each(list, 
                  fn(cog) -> 
                        relative_postions(cog.id)
                  end)
    end

    @doc """
        this function given a cog list and a cog, returns the relative polar coordinates
        of the other cogs around it.  This list of polar coordinates needs to be sent to
        a cog for it to caculaute how much it is going to move
        
        problem is cog and cog in cog list are not the same! ##FIXED
    """
     def relative_polarcoordinates(cog_list, cog) do
        other_pos = Enum.reject(cog_list, 
                        fn(%Cog{id: other_id}) -> cog.id == other_id end)
                    |>Enum.map(fn(some_cog) -> Cog.postion(some_cog) end)
                    |>Polar.relative_coordinates({{cog.x, cog.y}, cog.theta})
        s = other_pos
        #IEx.pry
        s
    end

    def add_cog(cog = %Cog{}) do
        :ok = GenServer.call(@name, {:add_cog, cog})
    end

    def list do
        GenServer.call(@name, :list)
    end

    def count_runs do
        list
        |>Enum.map(fn(cog = %Cog{}) ->
                        my_pid = spawn(fn -> 
                                receive do
                                    count->IO.puts count
                                end
                            end)
                            send cog.pid, {:count, my_pid}
                    end)
    end

    def update(delta, id) do
        GenServer.call(@name, {:update, id, delta})
    end


    def relative_postions(id) do
        GenServer.call(@name, {:relative_polarcoordinates, id})
    end

    def write_to_file do
        {:ok, file} = File.open "points.txt", [:write]
        
       point_str = Enum.reduce(list, "",
                        fn (%Cog{x: x, y: y}, acc) -> acc<>"#{x}\t#{y}\n"
                   end)
        
        IO.binwrite file, point_str
    end

    def cog_history do
        {:ok, file} = File.open "history/history.txt", [:write]
        ets_list = Enum.reduce(list, [],
                        fn(%Cog{id: id}, acc) -> 
                            acc++[:ets.lookup(:history, "cog#{id}")] 
                  end)
        
        str = List.flatten(ets_list)
              |>Enum.reduce("",  fn({_key, str}, acc) 
                                            -> acc<>str
                                         end)
        IO.binwrite file, str
    end
end

#:TODO 

#1. figure out how to make behaviors more flexable ..
#2. think how to represent the space they will acutally be in 
#3. Environment
#4. distrubed like gameOfLife example?
#5. make javascript 'viewer'