defmodule Nektar.Cog do
    @enforce_keys [:id, :x, :y, :theta, :state]
    defstruct [:id, :x, :y, :theta, :state]
    
    def move(id, pid) do
        receive do
            :id        -> send pid, id
            {:new, postions} -> 
                delta = behavior(postions)
                send pid, {:update, delta}
        end
    end

    def behavior(postions) do
        Enum.reduce(postions, {0,0, 0},
            fn({angle, distance}, {angle_sum, distance_sum, acc}) -> 
                {angle_sum + angle, distance_sum + distance, acc + 1} 
            end)
        |>(fn({angle_sum, distance_sum, count}) -> {angle_sum/count, distance_sum/count} end).()
    end
end

#make a cog
cog = spawn(Nektar.Cog, :move, [1, self])

#postion = 0,0  #others = {1,1}, {5,5}, {-1, -3}
cog_pos = {2,-7}
others_pos = [{1,1}, {5,5}, {-1, -3}]

polar_coordinates = Nektar.PolarCoordinate.relative_coordinates(cog_pos, others_pos)

send cog, {:new, polar_coordinates}

answer = receive do
            {:update, delta} -> delta
        end

#hhave to take this angle and distance and turn it back into
# an amount that can be added to the postion
IO.inspect answer

