defmodule Nektar.CogServerTest do
    use ExUnit.Case
    alias Nektar.CogServer, as: Server

    test "gets the other cogs" do
         Server.start_link 7
         
         cog_list = Server.cog_list
         [cog | acutal_other_cog_list] = cog_list         
         other_cog_list = Server.other_cogs(cog_list, cog)

         assert other_cog_list == acutal_other_cog_list

         [cog2 | actual_cog_list2] = acutal_other_cog_list
         other_cog_list2 = Server.other_cogs(cog_list, cog2)
         assert other_cog_list2 == [cog | actual_cog_list2]
    end 
end