defmodule Nektar.CogServer do
    use GenServer
    alias Nektar.Cog, as: Cog
    alias Nektar.PolarCoordinate, as: Polar
    @name {:global, __MODULE__}

    require IEx

    def handle_call({:add_cog, cog = %Cog{}}, _from, {cog_list, count, size, num_done}) do
        send cog.pid, :link
        {:reply, :ok, {Map.put(cog_list, cog.id, cog), count, size + 1, num_done}}
    end

    def handle_call(:list, _from, {cog_list, count, size, num_done}) do
        {:reply, cog_list, {cog_list, count, size, num_done}}
    end

    def handle_cast({:relative_polarcoordinates, id}, {cog_list, count, size, num_done}) do
        cog = Map.get(cog_list, id)
        send cog.pid, {:new_postions, relative_polarcoordinates(cog_list, cog)}

        if size == num_done + 1 do
            Enum.each(cog_list, fn({_id, cog}) -> 
                send cog.pid, :move 
            end)

            if count < 100 do
                    {:ok, file} = File.open "history/#{count}points.csv", [:write]
                    
                     point_str = Enum.reduce(cog_list, "\"X\",\"Y\"\n",
                                    fn ({_id, %Cog{x: x, y: y}}, acc) -> acc<>"#{x},#{y}\n"
                            end)
            
                    IO.binwrite file, point_str
            end

            {:noreply, {cog_list, count + 1, size, 0}}
        else
            {:noreply, {cog_list, count, size, num_done + 1}}
        end
    end

    def handle_cast({:update, id, delta}, {cog_list, count, size, num_done}) do
        cog = Map.get(cog_list, id)
              |>Cog.update_postion(delta)

        cog_map = Map.update!(cog_list, id, fn _ -> cog end)

        :ets.insert(:history, {"cog#{cog.id}", "id: #{cog.id} \t count: #{count} \t x: #{cog.x} \t y: #{cog.y} \t angle: #{cog.theta} \t delta: #{inspect(delta)}\n"}) 
                     
        {:noreply, {cog_map, count, size, num_done}}
    end

    def handle_info(msg, state) do
        IO.puts "error: #{msg}"
        {:noreply, state}
    end

    def start_link(number_of_cogs) do
        :ets.new(:history, [:duplicate_bag, :public, :named_table])
        {:ok, pid} = GenServer.start_link(__MODULE__, {Map.new, 0, 0, 0}, name: @name)

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
                  fn({_id, cog}) -> 
                        relative_postions(cog.id)
                  end)
      
      pid
    end

    @doc """
        this function given a cog list and a cog, returns the relative polar coordinates
        of the other cogs around it.  This list of polar coordinates needs to be sent to
        a cog for it to caculaute how much it is going to moveS
    """
     def relative_polarcoordinates(cog_list, cog) do
        other_pos = Map.delete(cog_list, cog.id)
                    |>Map.to_list
                    |>Enum.map(fn({_id, some_cog}) -> Cog.postion(some_cog) end)
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
        |>Enum.map(fn({_id, cog}) ->
                        my_pid = spawn(fn -> 
                                receive do
                                    count->IO.puts count
                                end
                            end)
                            send cog.pid, {:count, my_pid}
                    end)
    end

    def update(delta, id) do
        GenServer.cast(@name, {:update, id, delta})
    end


    def relative_postions(id) do
        GenServer.cast(@name, {:relative_polarcoordinates, id})
    end

    def write_to_file do
        {:ok, file} = File.open "history/my_points.csv", [:write]
                    
        point_str = Enum.reduce(list, "\"X\",Y\"\n",
                                    fn ({_id, %Cog{x: x, y: y}}, acc) -> acc<>"#{x},#{y}\n"
                                end)
            
        IO.binwrite file, point_str
    end

    def cog_history do
        {:ok, file} = File.open "history/history.txt", [:write]
        ets_list = Enum.reduce(list, [],
                        fn({id, _cog}, acc) -> 
                            acc++[:ets.lookup(:history, "cog#{id}")] 
                  end)
        
        str = List.flatten(ets_list)
              |>Enum.reduce("",  fn({_key, str}, acc) 
                                            -> acc<>str
                                         end)
        IO.binwrite file, str
    end
end
#Nektar.CogServer2.start_link 3
#:TODO 
    #0.1 maybe go back to using no sync? 
    #increase efficency by keeping all angles in raidans? 
#1. figure out how to make behaviors more flexable ..
#2. think how to represent the space they will acutally be in 
#3. Environment
#4. distrubed like gameOfLife example?
#5. make javascript 'viewer'

#CogServer 1 | 3 cogs | 30 sec | 119_766
#CogServer 2 | 3 cogs | 30 sec | 140_786

#CogServer 1 | 100 cogs | 30 sec | 1_175
#CogServer 2 | 100 cogs | 30 sec | 1_267