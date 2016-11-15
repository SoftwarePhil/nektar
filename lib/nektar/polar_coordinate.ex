defmodule Nektar.PolarCoordinate do
@moduledoc """
    This module will deal with all vector/polar coordinate
    calculations
"""

    @doc """
        This method will take a point, and return the angle
        between that point and the line (1,0), and the length
        of that line    

        {length, angle}

        This uses the fact that the angle between two vectors
        is acos((v1*v2)/length) where * is the dot product
    """
    @enforce_keys [:r, :theta]
    defstruct [:r, :theta]

    #zero distance case
    def create_polarcoordinate({x, y}) when x == 0 and y == 0 do
        %__MODULE__{r: 0, theta: 0}
    end
    
    def create_polarcoordinate({x, y}) do
        {_, length} = normalize({x, y}) 
        
        angle = :math.acos(y/length)
                |>to_degrees
        #above finds smallest angle, we want the 'whole' angle    
       
       final_angle =  case  {x, y} do
                        {x, y} when x >= 0 and y >= 0 -> angle       #{ x ,  y}
                        {x, y} when y <  0 and x >= 0 -> angle       #{ x , -y}
                        {_, _}                        -> 360 - angle #{-x ,  y}
                                                                     #{-x , -y}
                  end      
        %__MODULE__{r: length, theta: final_angle}
    end

    @doc """
        normalizes a vector, converts a given vector to a unit vector

        returns a tuple {{new_x, new_y}, length}
    """
    def normalize({x, y}) do
        length = :math.sqrt(abs(x*x) + abs(y*y))

        {{x/length, y/length}, length}
    end
#maybe just want everything in raidians ?
    def to_degrees(angle) do
        angle*180/:math.pi
    end

    def to_rad(angle) do
        angle*:math.pi/180
    end
    
    @doc """
        finds the relative postion of others 
        ie 
            if postion is {5,5}, and angle is 0 and others are [{6,6}, {0,0}, {7,7}]
            then this will return [{1,1}, {-5,-5}, {2,2}]

            this takes postion and angle to get realtive angle also
            TODO: change to just take a polarcoordinate maybe?
    """
    def relative_coordinates(other_positions, {{x, y}, current_angle}) do
            Enum.map(other_positions, fn({other_x, other_y}) -> {other_x - x, other_y - y} end)
            |>Enum.map(fn(x_y)-> 
                    pc = create_polarcoordinate(x_y)

                    angle = case pc.theta do
                                angle when current_angle - angle < 0 -> (current_angle - angle) + 360
                                angle                                ->  current_angle - angle
                            end 
                    
                    %__MODULE__{r: pc.r, theta: angle}
                end)        
    end

    @doc """
        transforms a polarcoordinate to a cartesian coordinate

        iex> Nektar.PolarCoordinate.as_cartesian {1, 180}
        {0, -1.0}  
    """
    def as_cartesian(pc = %Nektar.PolarCoordinate{}) do
        x = pc.r*:math.sin(to_rad(pc.theta))
        y = pc.r*:math.cos(to_rad(pc.theta))
        
        case {x, y} do
                {x, _y} when abs(x) < 0.001  -> {0, y}
                {_x, y} when abs(y) < 0.001  -> {x, 0}
                {x,  y}                      -> {x, y} 
        end
    end

    def angle({x,y}) do
       pc = create_polarcoordinate {x,y}
       pc.theta
    end

    def add({x,y}, {x2,y2}) do
        {x+x2, y+y2}
    end
end