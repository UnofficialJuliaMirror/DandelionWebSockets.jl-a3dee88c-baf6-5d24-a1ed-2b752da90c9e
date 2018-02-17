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

struct FailTheConnectionBehaviour
    framewriter::AbstractFrameWriter
    status::CloseStatus
    issocketprobablyup::Bool

    FailTheConnectionBehaviour(w::AbstractFrameWriter, status::CloseStatus;
                               issocketprobablyup=true) = new(w, status, issocketprobablyup)
end

function closetheconnection(fail::FailTheConnectionBehaviour)
    if fail.issocketprobablyup
        sendcloseframe(fail.framewriter, fail.status)
    end
    closesocket(fail.framewriter)
end