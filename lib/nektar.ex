defmodule Nektar do
    use Application

    def start(_type, _args) do
        Nektar.ServerSupervisor.start_link 5
    end
end
