defmodule Profile do
    import ExProf.Macro
    alias Nektar.CogServer2, as: Server

    def go do
        profile do
            run_sim(3, 10_000)
        end
    end 

    def run_sim(cogs, times) do
        pid = Server.start_link(cogs, times)

        Process.link(pid)
        Process.flag(:trap_exit, true)

        receive do
            _msg -> :ok
        end
    end  
end