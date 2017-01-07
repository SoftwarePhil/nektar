defmodule Nektar.ServerSupervisor do
    use Supervisor

    def start_link(num) do
        Supervisor.start_link(__MODULE__, num)
    end 

    def init(cog_args) do        
        children = [worker(Nektar.CogServer, [self(), cog_args])] #creating list of child processes

        opts = [strategy: :one_for_all]
        supervise(children, opts)
    end
end