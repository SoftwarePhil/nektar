 defmodule Profile do
    import ExProf.Macro
    def go do
        profile do
            {:ok, pid} = Nektar.ServerSupervisor.start_link 100
            runner = spawn(__MODULE__, :run, [])
            Enum.each 1.. 500, fn _ -> send runner, :go end
            send runner, {:exit, self}
            receive do
                :done -> :ok
            end
        end
    end

    def run do
        receive do
            :go ->
                Nektar.CogServer.send_all()
                Nektar.CogServer.action_all()
                run()
            {:exit, pid} -> send pid, :done
        end
    end
end