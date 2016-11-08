defmodule Nektar.PolarCoordinateTest do
    use ExUnit.Case, async: true
    alias Nektar.PolarCoordinate, as: Polar

    test "the correct angle is being found" do
        pc = Polar.create_polarcoordinate({1,0})
        assert Float.round(pc.theta)  == 0
        
        pc = Polar.create_polarcoordinate({1,1})
        assert Float.round(pc.theta)  == 45
     
        pc = Polar.create_polarcoordinate({0,1})
        assert Float.round(pc.theta)  == 90

        pc = Polar.create_polarcoordinate({0,-1})
        assert Float.round(pc.theta)  == 180
       
        pc = Polar.create_polarcoordinate({-1,-1})
        assert Float.round(pc.theta)  == 225
        
        pc = Polar.create_polarcoordinate({-1,0})
        assert Float.round(pc.theta)  == 270

        pc = Polar.create_polarcoordinate({1000,1000})
        assert Float.round(pc.theta)  == 45
        
        pc = Polar.create_polarcoordinate({1000000000,1000000000})
        assert Float.round(pc.theta)  == 45
    end

    test "relative coordinates and cartesian coordinates" do
        result = Polar.relative_coordinates([{6,6}, {0,0}, {7,7}], {5,5})
                 |>Enum.map(fn(pc) -> 
                    {x, y} = Polar.as_cartesian(pc)
                    {Float.round(x), Float.round(y)}
                    end)
        
        IO.inspect Polar.relative_coordinates([{6,6}, {0,0}, {7,7}], {5,5})
        assert result == [{1.0, 1.0}, {-5.0, -5.0}, {2.0, 2.0}]
    end
end