defmodule Nektar do
    use Application

    def start(_type, _args) do
        {:ok, pid} = Nektar.ServerSupervisor.start_link 13
        runner = spawn(__MODULE__, :run, [])
        Enum.each 1.. 750, fn _ -> send runner, :go end
        {:ok, pid}
    end

    def run do
        receive do
            :go ->
                Nektar.CogServer.send_all()
                Nektar.CogServer.action_all()
                run()
            :exit -> IO.puts "end"
        end
    end
end
