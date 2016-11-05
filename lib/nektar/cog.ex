defmodule Nektar.Cog do
    alias Nektar.PolarCoordinate, as: Polar
    @enforce_keys [:id, :x, :y, :theta, :state, :pid]
    defstruct [:id, :x, :y, :theta, :state, :pid]
    
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
            :id        -> send pid, id
            {:new, postions} -> 
                delta = behavior(postions)
                send pid, {:update, delta}
        end
    end

    def behavior(postions) do
        Enum.reduce(postions, {0,0, 0},
            fn(pc = %Polar{}, {angle_sum, distance_sum, acc}) -> 
                {angle_sum + pc.theta, distance_sum + pc.r, acc + 1} 
            end)
        |>(fn({angle_sum, _distance_sum, count}) -> %Polar{r: 1, theta: angle_sum/count} end).()
    end
end

#:TODO 
#1. give cog actually good 'swarm' behavior, 
#2. figure out how to make behaviors more flexable ..
#3. think how to represent the space they will acutally be in 

#make a cog
cog = Nektar.Cog.init(self, 1, 0, 0)

others_pos = [{1,1}, {5,5}, {-1, -3}]
polar_coordinates = Nektar.PolarCoordinate.relative_coordinates(Nektar.Cog.postion(cog), others_pos)

#send new postions to cog
send cog.pid, {:new, polar_coordinates}

#get new polar coordinate, which represents the change of
#postion of the cog
answer = receive do
            {:update, delta} -> delta
        end

#update cog postion 
new_pos_cog = Nektar.Cog.update_postion(cog, answer)

IO.inspect cog
IO.inspect new_pos_cog
