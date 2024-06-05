defmodule IbEx.ClientTest do
  use ExUnit.Case, async: true

  alias IbEx.Client

  describe "handle_cast/2 when processing an incoming message" do
    test "updates the client's state with the server version, the connection timestamp and continues to validate the server version" do
      initial_state = %{status: :connecting}

      str = "178\x0020240605 17:25:52 Central European Standard Time\x00"

      assert {:noreply, new_state, continuation} = Client.handle_cast({:process_message, str}, initial_state)

      assert new_state.server_version == 178
      assert new_state.connection_timestamp == ~N[2024-06-05 17:25:52]
      assert new_state.status == :connected

      assert continuation == {:continue, :validate_server_version}
    end
  end
end
