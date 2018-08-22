using Random
using Base64

struct HTTPHandshakeLogic
    rng::AbstractRNG
end

getrequestheaders(h::HTTPHandshakeLogic) = [
    "Sec-WebSocket-Version" => "13",
    "Upgrade" => "websocket",
    "Connection" => "Upgrade",
    "Sec-WebSocket-Key" => base64encode(rand(h.rng, UInt8, 16))]