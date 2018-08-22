using DandelionWebSockets:
    HTTPHandshakeLogic, getrequestheaders, validateresponse, issuccessful
using Base64

defaulthandshakelogic() = HTTPHandshakeLogic(FakeRNG{UInt8}(b"\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c\x0d\x0e\x0f\x10"))

@testset "Handshake logic        " begin
    @testset "Requests" begin
        @testset "Sec-WebSocket-Version; Version is 13" begin
            h = defaulthandshakelogic()

            headers = getrequestheaders(h)
            headersdict = Dict(headers)

            @test headersdict["Sec-WebSocket-Version"] == "13"
        end

        @testset "Upgrade header; Upgrade header is 'websocket'" begin
            h = defaulthandshakelogic()

            headers = getrequestheaders(h)
            headersdict = Dict(headers)

            @test headersdict["Upgrade"] == "websocket"
        end

        @testset "Connection header; Has value 'Upgrade'" begin
            h = defaulthandshakelogic()

            headers = getrequestheaders(h)
            headersdict = Dict(headers)

            @test headersdict["Connection"] == "Upgrade"
        end

        @testset "Make two handshakes with different RNGs; Their Sec-WebSocket-Key are different" begin
            rng1 = FakeRNG{UInt8}(b"\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c\x0d\x0e\x0f\x10")
            h1 = HTTPHandshakeLogic(rng1)
            rng2 = FakeRNG{UInt8}(b"\x02\x03\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c\x0d\x0e\x0f\x10\x01")
            h2 = HTTPHandshakeLogic(rng2)

            headers1 = getrequestheaders(h1)
            headersdict1 = Dict(headers1)
            headers2 = getrequestheaders(h2)
            headersdict2 = Dict(headers2)

            @test headersdict1["Sec-WebSocket-Key"] != headersdict2["Sec-WebSocket-Key"]
        end

        @testset "Sec-WebSocket-Key; Is 16 bytes when base64 decoded" begin
            h = defaulthandshakelogic()

            headers = getrequestheaders(h)
            headersdict = Dict(headers)

            @test length(base64decode(headersdict["Sec-WebSocket-Key"])) == 16
        end

        # This is an example Sec-WebSocket-Key from the specification, section 4.1.
        @testset "Sec-WebSocket-Key uses nonce 0x01->0x10; Sec-WebSocket-Key is AQIDBAUGBwgJCgsMDQ4PEA==" begin
            h = defaulthandshakelogic()

            headers = getrequestheaders(h)
            headersdict = Dict(headers)

            @test headersdict["Sec-WebSocket-Key"] == "AQIDBAUGBwgJCgsMDQ4PEA=="
        end
    end

    @testset "Validation" begin
        @testset "Response status code is 101; Validation is successful" begin
            h = defaulthandshakelogic()

            result = validateresponse(h, 101, Pair{String, String}[])

            @test issuccessful(result)
        end

        @testset "Response status code is 200; Validation is not successful" begin
            h = defaulthandshakelogic()

            result = validateresponse(h, 200, Pair{String, String}[])

            @test !issuccessful(result)
        end
    end
end