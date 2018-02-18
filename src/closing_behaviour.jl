"""
CloseStatusCode indicates a reason for closing the connection.
It is optionally sent as the first two bytes of a Close frames payload.
"""
struct CloseStatus
    code::UInt16
end

const CLOSE_STATUS_NORMAL                     = CloseStatus(1000)
const CLOSE_STATUS_GOING_AWAY                 = CloseStatus(1001)
const CLOSE_STATUS_PROTOCOL_ERROR             = CloseStatus(1002)
const CLOSE_STATUS_UNACCEPTABLE_DATA          = CloseStatus(1003)
const CLOSE_STATUS_RESERVED_1004              = CloseStatus(1004)
const CLOSE_STATUS_NO_STATUS                  = CloseStatus(1005)
const CLOSE_STATUS_ABNORMAL_CLOSE             = CloseStatus(1006)
const CLOSE_STATUS_INCONSISTENT_DATA          = CloseStatus(1007)
const CLOSE_STATUS_POLICY_VIOLATION           = CloseStatus(1008)
const CLOSE_STATUS_MESSAGE_TOO_BIG            = CloseStatus(1009)
const CLOSE_STATUS_EXPECTED_EXTENSION         = CloseStatus(1010)
const CLOSE_STATUS_FATAL_UNEXPECTED_CONDITION = CloseStatus(1011)
const CLOSE_STATUS_TLS_HANDSHAKE_FAILURE      = CloseStatus(1015)

"""
Failing the WebSocket connection is an action taken at certain points in the protocol specification,
in response to error conditions.

The closing behaviour is to optionally send a Close frame, with an appropriate status code, and then
close the socket.
"""
struct FailTheConnectionBehaviour <: ClosingBehaviour
    framewriter::AbstractFrameWriter
    handler::WebSocketHandler
    status::CloseStatus
    issocketprobablyup::Bool
    reason::String

    FailTheConnectionBehaviour(w::AbstractFrameWriter,
                               handler::WebSocketHandler,
                               status::CloseStatus;
                               issocketprobablyup=true,
                               reason::String = "") = new(w, handler, status, issocketprobablyup, reason)
end

function closetheconnection(fail::FailTheConnectionBehaviour)
    if fail.issocketprobablyup
        sendcloseframe(fail.framewriter, fail.status; reason=fail.reason)
    end
    closesocket(fail.framewriter)
    state_closed(fail.handler)
end

clientprotocolinput(::FailTheConnectionBehaviour, ::ClientProtocolInput) = nothing

protocolstate(::FailTheConnectionBehaviour) = STATE_CLOSED

"""
Closing the WebSocket connection is a procedure for closing the connection during the normal course
the protocol lifetime.
"""
mutable struct ClientInitiatedCloseBehaviour <: ClosingBehaviour
    framewriter::AbstractFrameWriter
    handler::WebSocketHandler
    status::CloseStatus
    reason::String
    state::SocketState

    function ClientInitiatedCloseBehaviour(w::AbstractFrameWriter, handler::WebSocketHandler;
                                           status::CloseStatus = CLOSE_STATUS_NORMAL,
                                           reason::String = "")
        new(w, handler, status, reason, STATE_CLOSING)
    end
end

protocolstate(normal::ClientInitiatedCloseBehaviour) = normal.state

function closetheconnection(normal::ClientInitiatedCloseBehaviour)
    sendcloseframe(normal.framewriter, normal.status; reason = normal.reason)
    state_closing(normal.handler)
end

function clientprotocolinput(normal::ClientInitiatedCloseBehaviour, frame::FrameFromServer)
    if frame.frame.opcode == OPCODE_CLOSE
        if normal.state == STATE_CLOSING
            # FIXME State isn't closed until the socket has been closed.
            # This is a substate of CLOSING
            normal.state = STATE_CLOSED
            state_closed(normal.handler)
        end
    end
end

function clientprotocolinput(normal::ClientInitiatedCloseBehaviour, ::AbnormalNoCloseResponseReceived)
    closesocket(normal.framewriter)
end

clientprotocolinput(::ClientInitiatedCloseBehaviour, ::ClientProtocolInput) = nothing

"""
The server can initiate a Close, in which case this behaviour ensures a proper close.
"""
mutable struct ServerInitiatedCloseBehaviour <: ClosingBehaviour
    framewriter::AbstractFrameWriter
    handler::WebSocketHandler
    status::CloseStatus
    state::SocketState

    function ServerInitiatedCloseBehaviour(w::AbstractFrameWriter, h::WebSocketHandler, status::CloseStatus)
        new(w, h, status, STATE_CLOSING)
    end
end

protocolstate(b::ServerInitiatedCloseBehaviour) = b.state

function closetheconnection(behaviour::ServerInitiatedCloseBehaviour)
    state_closing(behaviour.handler)
    sendcloseframe(behaviour.framewriter, behaviour.status; reason = "")
end

function clientprotocolinput(behaviour::ServerInitiatedCloseBehaviour, ::SocketClosed)
    behaviour.state = STATE_CLOSED
    state_closed(behaviour.handler)
end

clientprotocolinput(::ServerInitiatedCloseBehaviour, ::ClientProtocolInput) = nothing

function clientprotocolinput(b::ServerInitiatedCloseBehaviour, ::AbnormalSocketNotClosedByServer)
    b.state = STATE_CLOSED
    state_closed(b.handler)
    closesocket(b.framewriter)
end
