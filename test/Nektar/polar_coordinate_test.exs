defmodule Nektar.PolarCoordinateTest do
    use ExUnit.Case, async: true
    alias Nektar.PolarCoordinate, as: Polar

    test "the correct angle is being found" do
        {angle, _length} = Polar.find_angle({1,0})
        assert Float.round(angle)  == 0
        
        {angle, _length} = Polar.find_angle({1,1})
        assert Float.round(angle)  == 45
     
        {angle, _length} = Polar.find_angle({0,1})
        assert Float.round(angle)  == 90

        {angle, _length} = Polar.find_angle({0,-1})
        assert Float.round(angle)  == 180
       
        {angle, _length} = Polar.find_angle({-1,-1})
        assert Float.round(angle)  == 315
        
        {angle, _length} = Polar.find_angle({-1,0})
        assert Float.round(angle)  == 270

        {angle, _length} = Polar.find_angle({1000,1000})
        assert Float.round(angle)  == 45
        
        {angle, _length} = Polar.find_angle({1000000000,1000000000})
        assert Float.round(angle)  == 45
    end

    test "relative coordinates" do
        list = Polar.relative_coordinates({5,5}, [{6,6}, {0,0}, {7,7}])
        assert list == [{1, 1}, {-5, -5}, {2, 2}]
    end
end