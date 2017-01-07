defmodule Nektar.CogSupervisor do
    use Supervisor

    def start_link do
        IO.puts "ran"
        Supervisor.start_link(__MODULE__, [])
    end 

    def init([]) do
        args = [restart: :permanent]
        children = [worker(Nektar.Cog, [], args)] #creating list of child processes, #args empty because they are passed in from the server

        opts = [strategy: :simple_one_for_one, max_restarts: 5, max_seconds: 5] #options for the new supervisor
        supervise(children, opts)
    end
end
"""
{:ok, pid} = Nektar.ServerSupervisor.start_link 5 
[{_,cog_sup, _,_}, _] = Supervisor.which_children pid
list = Supervisor.which_children cog_sup
{_,cog, _, _} = List.last list
send cog, :test


{:ok, cog_sup} = Nektar.CogSupervisor.start_link
Supervisor.start_child(cog_sup, [self, 1, 2])
{:ok, cog} = Supervisor.start_child(cog_sup, [self, 1, 3])
Supervisor.count_children cog_sup
"""