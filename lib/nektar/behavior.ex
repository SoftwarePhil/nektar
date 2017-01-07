defmodule Nektar.Behavior do
    alias Nektar.PolarCoordinate, as: Polar
    #swarm parameters
    @l 0.99
    @alpha 1 - @l
    @x :math.sqrt(@l/@alpha)

    @doc """
        the curve function takes a list of PolarCoordinates and outputs
        the new angle(relative) angle that the cog will go, if list is empty
        returns zero 
    """
    def curve(polar_list) do
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
