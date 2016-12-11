defmodule Profile do
  import ExProf.Macro

  def go do
    profile do
       run_sim(100, 500)
    end
  end 

    def run_sim(cogs, times) do
        pid = Nektar.CogServer.start_link(cogs, times)

        Process.link(pid)
        Process.flag(:trap_exit, true)
    
        receive do
            _msg -> :ok
        end
    end  
end