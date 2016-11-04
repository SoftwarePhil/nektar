defmodule Nektar.Cog do
    @enforce_keys [:id, :x, :y, :theta, :state]
    defstruct [:id, :x, :y, :theta, :state]
    
    def move(id, pid) do
        receive do
            :id        -> send pid, id
            {postions} -> 
                behavior(postions)
                #|>new_state
        end
    end

    def behavior(postions) do
        Enum.reduce(postions, {0,0,0},
            fn({x, y}, {x_sum, y_sum, acc}) -> 
                {x + x_sum, y + y_sum, acc + 1} 
            end)
        |>(fn({x_sum, y_sum, count}) -> {x_sum/count, y_sum/count} end).()
    end

    def angle({x, y}) do
        #0,1 -> 0/360 degrees
        #1,0 -> 90 degrees
        #0,-1 -> 180 degrees
        #-1,0 -> 270 degrees

    end
end
