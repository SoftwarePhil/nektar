defmodule Nektar.Cog do
    alias Nektar.PolarCoordinate, as: Polar
    alias Nektar.CogServer, as: Server
    @enforce_keys [:id, :x, :y, :theta, :state, :pid]
    defstruct [:id, :x, :y, :theta, :state, :pid]
    
    @doc """
        creates a new cog with the following
        takes in pid (the pid of the server), id (unique cog id), x (x position), y (y postion)
    """
    def init(other_pid, id, x, y) do
        pid = spawn(__MODULE__, :spin, [id, other_pid])
        %__MODULE__{id: id, x: x, y: y, theta: 0, state: [], pid: pid}
    end

    def postion(%__MODULE__{x: x, y: y}) do
        {x, y}
    end

    @doc """
        takes a cog and a polar coordinate(representing the change in postions)
        and returns a cog with a new postion and angle

        TODO: think of new name for this function
        TODO: this crashes when a cog is send the same postion is is already in
    """
    def update_postion(cog = %__MODULE__{}, pc = %Polar{}) do
        {x, y} = Polar.as_cartesian pc
        
        new_theta = case {cog.theta, pc.theta} do
                     {theta, delta} when theta + delta > 359 -> theta + delta - 360
                     {theta, delta}                   -> theta + delta  
                    end
        
        %__MODULE__{cog | x: cog.x + x, y: cog.y + y, theta: new_theta}
    end
    
    def spin(id, pid) do
        receive do
            :id              -> send pid, id
            {:new, postions} -> 
                behavior(postions)
                |>Server.update(id)
                
        end
        spin(id, pid)
    end

    @doc """
        this function takes a list of polar coordinates, which are the 
        relative postions of the other cogs around it, and a function
        that maps the polar coordinates to an angle.  It returns a polar
        coordinate with radius 1 and the new angle of the cog

        does not work right now as planned because curve does all
        the reducing right now
    """
    def behavior(postions, action \\&curve/1) do
        %Polar{r: 1, theta: action.(postions)}
    end

    #swarm parameters
    @l 0.9
    @alpha 1 - @l
    @x :math.sqrt @l/@alpha

    @doc """
        the curve function takes a list of PolarCoordinates and outputs
        the new angle(relative) angle that the cog will go 
    """
    def curve(polar_list) do
        curve(polar_list, [], [])
    end
    
    #attraction
    defp curve([pc = %Polar{r: r} | polar_list], a_acc, r_acc) when r >= @x do
        curve(polar_list, [pc] ++ a_acc, r_acc)
    end

    #repulsion 
    defp curve([pc = %Polar{r: r} | polar_list], a_acc, r_acc) when r < @x and r > 0 do
        curve(polar_list, a_acc, [pc] ++ r_acc)
    end

    #repulsion, 0 distance case
    defp curve([%Polar{r: r} | polar_list], a_acc, r_acc) when r == 0 do
        curve(polar_list, a_acc, [%Polar{r: 0.01, theta: Enum.random(0..359)}] ++ r_acc)
    end

    #apply curve based on r, get and get scalling value, this is a way of weighing the vectors
    defp curve([], a_acc, r_acc) do
        a_vector = a_acc
                   |>Enum.reduce({0,0}, fn(pc = %Polar{}, acc) -> 
                        a = @alpha/@l * :math.pow(pc.r - :math.sqrt(@x), 2)
                        {x, y} = acc
                        {x + (a * :math.sin(Polar.to_rad(pc.theta))), y + (a * :math.cos(Polar.to_rad(pc.theta)))}                     
                    end)
        
        r_vector = r_acc
                   |>Enum.reduce({0,0}, fn(pc = %Polar{}, acc) -> 
                        r = -1/:math.pow(pc.r, 2)
                        {x, y} = acc
                        {x + (r * :math.sin(Polar.to_rad(pc.theta))), y + (r * :math.cos(Polar.to_rad(pc.theta)))}                     
                    end)
        
        Polar.add(a_vector, r_vector)
        |>Polar.angle

    end 

 
end
