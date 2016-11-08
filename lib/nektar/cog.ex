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
    """
    def update_postion(cog = %__MODULE__{}, pc = %Polar{}) do
        {x, y} = Polar.as_cartesian pc
        
        new_theta = case {cog.theta, pc.theta} do
                     {theta, delta} when theta + delta > 359 -> theta + delta - 359
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

    def behavior(postions) do
        Enum.reduce(postions, {0,0, 0},
            fn(pc = %Polar{}, {angle_sum, distance_sum, acc}) -> 
                {angle_sum + pc.theta, distance_sum + pc.r, acc + 1} 
            end)
        |>(fn({angle_sum, _distance_sum, count}) -> %Polar{r: 1, theta: angle_sum/count} end).()
    end
end
