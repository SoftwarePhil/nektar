defmodule Nektar.Cog do
    alias Nektar.PolarCoordinate, as: Polar
    alias Nektar.Behavior, as: Behavior
    #alias Nektar.CogServer, as: Server
    @enforce_keys [:x, :y, :theta, :delta, :state, :pid, :count]
    defstruct [:x, :y, :theta, :delta, :state, :pid, :count]
    require IEx
    use GenServer
    
    @doc """
        creates a new cog
        takes in pid (the pid of the server), id (unique cog id), x (x position), y (y postion)
        CogServer will not always have global name
    """
    def start_link(other_pid, x, y) do
        #{:ok, spawn(__MODULE__, :spin, [%__MODULE__{x: x, y: y, theta: 0, delta: %Polar{r: 1, theta: 90} ,state: [], pid: other_pid}])}
        GenServer.start_link(__MODULE__, [%__MODULE__{x: x, y: y, theta: 0, delta: %Polar{r: 1, theta: 90} ,state: [], pid: other_pid, count: 0}])
    end
  
    def postion(%__MODULE__{x: x, y: y}) do
        {x, y}
    end
##
    def count(pid) do
        GenServer.call(pid, :count)
    end

    def new_postion(pid, postions) do
        GenServer.call(pid, {:new_postions, postions})
    end

    def move(pid) do
        GenServer.call(pid, :move)
    end

    def info(pid) do
        GenServer.call(pid, :info)
    end

    def stop(pid) do
        GenServer.call(pid, :stop)
    end

  ##

    def handle_call(:count, _from, cog) do
        {:reply, cog.count, cog}
    end

    def handle_call({:new_postions, postions}, _from, cog) do
        delta = behavior(postions)
        cog = %__MODULE__{cog | delta: delta}
        {:reply, {:ok, delta}, cog}
    end

    def handle_call(:move, _from, cog) do
        updated = update_postion(cog)
        pos = {updated.x, updated.y}
        {:reply, {:ok, pos}, updated}
    end

    def handle_call(:info, _from, cog) do
        {:stop, cog, cog}
    end

    def handle_call(:stop, _from, cog) do
        {:stop, :normal, :ok, cog}
    end

    @doc """
        takes a cog and a polar coordinate(representing the change in postions)
        and returns a cog with a new postion and angle

        TODO: think of new name for this function
    """
    def update_postion(cog = %__MODULE__{}) do
        
        #the new angle has to be converted into absolute terms ..
        #maybe this should happen sooner, ie we have on angle for its
        #'absolute angle', another for it's 'relative angle' and
        #another one for when we need to calculate the new direction
        pc = cog.delta
        stored_theta = 
            case {cog.theta, pc.theta} do
                {current, delta} when current + delta > 360 -> (current + delta) - 360
                {current, delta}                            ->  current + delta
            end 
        
        new_theta = 
                case stored_theta do
                        angle when angle <  90  -> 90 - angle
                        angle when angle <  180 -> 360 - (angle - 90)
                        angle when angle <  270 -> 180 + (90 - (angle - 180))
                        angle when angle <= 360 -> 90 + (90 - (angle - 270)) 
                    end
        {x, y} = Polar.as_cartesian_correct %Polar{pc | theta: new_theta}
        
        %__MODULE__{cog | x: cog.x + x, y: cog.y + y, theta: stored_theta, count: cog.count + 1}
    end
    
    @doc """
        this function takes a list of polar coordinates, which are the 
        relative postions of the other cogs around it, and a function
        that maps the polar coordinates to an angle.  It returns a polar
        coordinate with radius 1 and the new angle of the cog

        does not work right now as planned because curve does all
        the reducing right now
    """
    def behavior(postions, action \\&Behavior.curve/1) do
        %Polar{r: 1, theta: action.(postions)}
    end
end
##working on
#pid = Nektar.Cog.init self(), 1,2
#send pid, {:new_postions, [Nektar.PolarCoordinate.create_polarcoordinate({1,1}), Nektar.PolarCoordinate.create_polarcoordinate({6,2})]}  
