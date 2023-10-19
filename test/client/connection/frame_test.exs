defmodule IbEx.Client.Connection.FrameTest do
  use ExUnit.Case

  alias IbEx.Client.Connection.Frame

  test "pack/1 packs the string for serialization" do
    msg = "foo\0"

    assert Frame.pack(msg) == <<0, 0, 0, 4, 102, 111, 111, 0>>
  end
end
