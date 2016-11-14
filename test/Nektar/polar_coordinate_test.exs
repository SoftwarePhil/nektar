defmodule Nektar.PolarCoordinateTest do
    use ExUnit.Case
    alias Nektar.PolarCoordinate, as: Polar
    alias Nektar.Cog, as: Cog
    alias Nektar.CogServer, as: Server

    test "the correct angle is being found" do
        pc = Polar.create_polarcoordinate({1,0})
        assert Float.round(pc.theta)  == 90
        
        pc = Polar.create_polarcoordinate({1,1})
        assert Float.round(pc.theta)  == 45
     
        pc = Polar.create_polarcoordinate({0,1})
        assert Float.round(pc.theta)  == 0

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

    test "relative polar coordinates test and postion update" do
        cog1 = %Cog{id: 0, x: 0, y: 0, theta: 0, state: [], pid: 0}
        cog2 = %Cog{id: 1, x: 0, y: 11, theta: 0, state: [], pid: 0}
        list = [cog1, cog2]
        
        relative_other_polarcoordinates = Server.relative_polarcoordinates(list, cog1)
        assert relative_other_polarcoordinates == [%Polar{r: 11, theta: 0}]
        new_cog1 = Cog.update_postion(cog1, Cog.behavior(relative_other_polarcoordinates))
        assert new_cog1 == %Cog{id: 0, x: 0, y: 1, theta: 0, state: [], pid: 0}


        relative_other_polarcoordinates2 = Server.relative_polarcoordinates(list, cog2)
        assert relative_other_polarcoordinates2 ==[%Polar{r: 11, theta: 180}]
        new_cog2 = Cog.update_postion(cog2, Cog.behavior(relative_other_polarcoordinates2))
        assert new_cog2 == %Cog{id: 1, x: 0, y: 10, theta: 180.0, state: [], pid: 0}
    end

end