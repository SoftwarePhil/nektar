defmodule Nektar.PolarCoordinate do
@moduledoc """
    This module will provide to deal with all vector/polar coordinate
    calculations
"""

    @doc """
        This method will take a point, and return the angle
        between that point and the line (1,0)

        This uses the fact that the angle between two vectors
        is acos((v1*v2)/length) where * is the dot product
    """
    def find_angle({x, y}) do
        {_, length} = normalize({x, y}) 
        
        angle = :math.acos(x/length)
                |>convert_to_degrees
        #above finds smallest angle, we want the 'whole' angle    
        result =  case  {x, y} do
                        {x, y} when x < 0 and y < 0 ->  angle + 180 #{-x , y}
                        {x, _} when x < 0 ->            angle + 90  #{-x , y}
                        {_, y} when y < 0 ->            angle + 90  #{ x ,-y}
                        {_, _}            ->            angle       #{ x , y}
                  end
        
        {result, length}
    end

    @doc """
        normalizes a vector, converts a given vector to a unit vector

        returns a tuple {{new_x, new_y}, length}
    """
    def normalize({x, y}) do
        length = :math.sqrt(abs(x*x) + abs(y*y))

        {{x/length, y/length}, length}
    end

    def convert_to_degrees(angle) do
        angle*180/:math.pi
    end
    
    @doc """
        finds the relative postion of others 
        ie 
            if postion is {5,5} and others are [{6,6}, {0,0}, {7,7}]
            then this will return [{1,1}, {-5,-5}, {2,2}]
    """
    def relative_coordinates({x,y}, other_positions) do
        Enum.map(other_positions, fn({other_x, other_y}) -> {other_x - x, other_y - y} end)
        |>Enum.map(fn(angle) -> find_angle(angle) end)
    end
end