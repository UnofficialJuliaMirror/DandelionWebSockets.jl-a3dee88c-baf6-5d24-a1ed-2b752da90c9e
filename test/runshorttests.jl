using DandelionWebSockets
using DandelionWebSockets: STATE_OPEN, STATE_CONNECTING, STATE_CLOSING, STATE_CLOSED
using DandelionWebSockets: SocketState, AbstractPonger, SendTextFrame, FrameFromServer
using DandelionWebSockets: handle
import DandelionWebSockets: write
import DandelionWebSockets: on_text, on_binary
import DandelionWebSockets: state_connecting, state_open, state_closing, state_closed

include("stubs.jl")
include("issues_test.jl")
include("client_logic_base_test.jl")
