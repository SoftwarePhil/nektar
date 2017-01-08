defmodule Nektar.Behavior do
    alias Nektar.PolarCoordinate, as: Polar
    use GenServer
    defstruct [:x, :y, :theta, :delta]
    #swarm parameters
    @l 0.99
    @alpha 1 - @l
    @x :math.sqrt(@l/@alpha)
    @d90 :math.pi/2
    @d180 @d90*2
    @d270 @d90*3
    @d360 @d90*4

    def start_link(args) do
        {x, y} = args
        GenServer.start_link(__MODULE__, %__MODULE__{x: x, y: y, theta: 0, delta: %Polar{r: 1, theta: @d90}})
    end

    def state(pid) do
        GenServer.call(pid, :state)
    end

    def new_states(pid, new_states) do
        GenServer.call(pid, {:new_states, new_states})
    end

    def action(pid) do
        GenServer.call(pid, :action)
    end

    def info(pid) do
        GenServer.call(pid, :info)
    end

    def handle_call(:state, _from, state) do
        {:reply, state, state}
    end

    def handle_call({:new_states, list}, _from, state) do
        delta = Enum.map(list, fn(%__MODULE__{x: x, y: y}) -> {x, y} end)
                |>Polar.relative_coordinates({{state.x, state.y}, state.theta})
        
        
        {:reply, :ok, %__MODULE__{state | delta: curve(delta)}}
    end

    def handle_call(:action, _from, state) do
        {:reply, :ok, update_postion(state)}
    end

    def handle_call(:info, _from, state) do
        {:reply, postion(state), state}
    end


    def postion(%__MODULE__{x: x, y: y, theta: theta}) do
        {x, y, theta * (180/:math.pi)}
    end

    def update_postion(cog = %__MODULE__{}) do
        #the new angle has to be converted into absolute terms ..
        #maybe this should happen sooner, ie we have on angle for its
        #'absolute angle', another for it's 'relative angle' and
        #another one for when we need to calculate the new direction
        pc = cog.delta
        stored_theta = 
            case {cog.theta, pc.theta} do
                {current, delta} when current + delta > @d360 -> (current + delta) - @d360
                {current, delta}                            ->  current + delta
            end 
        
        new_theta = 
                case stored_theta do
                        angle when angle <  @d90  -> @d90 - angle
                        angle when angle <  @d180 -> @d360 - (angle - @d90)
                        angle when angle <  @d270 -> @d180 + (@d90 - (angle - @d180))
                        angle when angle <= @d360 -> @d90 + (@d90 - (angle - @d270)) 
                    end
        {x, y} = Polar.as_cartesian_correct %Polar{pc | theta: new_theta}
        
        %__MODULE__{cog | x: cog.x + x, y: cog.y + y, theta: stored_theta}
    end
    
    @doc """
        the curve function takes a list of PolarCoordinates and outputs
        the new angle(relative) angle that the cog will go, if list is empty
        returns zero 
    """
    def curve(polar_list) do
        Enum.filter(polar_list, fn(%Polar{r: r}) -> r > 0 end)
        curve(polar_list, [], [])
    end
    
    #attraction
    defp curve([pc = %Polar{r: r} | polar_list], a_acc, r_acc) when r > @x do
        curve(polar_list, [pc] ++ a_acc, r_acc)
    end

    #repulsion 
    defp curve([pc = %Polar{r: r} | polar_list], a_acc, r_acc) when r <= @x and r > 0 do
        curve(polar_list, a_acc, [pc] ++ r_acc)
    end

    #repulsion, 0 distance case
    defp curve([%Polar{r: r} | polar_list], a_acc, r_acc) when r == 0 do
        curve(polar_list, a_acc, [%Polar{r: 0.01, theta: Enum.random(0..2)}] ++ r_acc)
    end

    #apply curve based on r, get and get scalling value, this is a way of weighing the vectors
    defp curve([], a_acc, r_acc) do
        a_vector = a_acc
                   |>Enum.reduce({0,0}, fn(pc = %Polar{}, acc) -> 
                        a = @alpha/@l * :math.pow(pc.r - :math.sqrt(@x), 2)
                        {x, y} = acc
                        {x + (a * :math.sin(pc.theta)), y + (a * :math.cos(pc.theta))}                     
                    end)
        
        r_vector = r_acc
                   |>Enum.reduce({0,0}, fn(pc = %Polar{}, acc) -> 
                        r = -1/:math.pow(pc.r, 2)
                        {x, y} = acc
                        {x + (r * :math.sin(pc.theta)), y + (r * :math.cos(pc.theta))}                     
                    end)
        
        theta = Polar.add(a_vector, r_vector)
                |>Polar.angle
        %Polar{r: 1, theta: theta}
    end 
end
