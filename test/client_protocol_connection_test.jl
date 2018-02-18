using Base.Test
using DandelionWebSockets: STATE_CLOSING_SOCKET, CloseRequest, SocketClosed
using DandelionWebSockets: PongMissed

function closeframe_from_server(; payload::Vector{UInt8} = b"")
    Frame(true, OPCODE_CLOSE, false, length(payload), 0, Vector{UInt8}(), payload)
end

@testset "Connection management  " begin
    @testset "the server initiates a closing handshake" begin
        @testset "state is CLOSING_SOCKET" begin
            logic, handler, writer = makeclientlogic(state=STATE_OPEN)

            close_frame = closeframe_from_server()
            handle(logic, FrameFromServer(close_frame))

            # TODO This is no longer true
            # TODO Use protocolstate() instead
            @test logic.state == STATE_CLOSING_SOCKET
        end

        @testset "handler is notified of state change" begin
            logic, handler, writer = makeclientlogic(state=STATE_OPEN)

            close_frame = closeframe_from_server()
            handle(logic, FrameFromServer(close_frame))

            @test handler.state == STATE_CLOSING
        end

        @testset "a close frame is sent in reply" begin
            logic, handler, writer = makeclientlogic(state=STATE_OPEN)

            close_frame = closeframe_from_server()
            handle(logic, FrameFromServer(close_frame))

            frame = getframe(writer, 1)
            @test frame.opcode == OPCODE_CLOSE
        end
    end

    @testset "the client initiates a closing handshake" begin
        @testset "state is CLOSING" begin
            # Requirement
            # @7_1_2-1 Start the closing handshake

            logic, handler, writer = makeclientlogic(state=STATE_OPEN)

            handle(logic, CloseRequest())

            # TODO Use protocolstate() instead
            @test logic.state == STATE_CLOSING
        end

        @testset "handler is notified of state change" begin
            logic, handler, writer = makeclientlogic(state=STATE_OPEN)

            handle(logic, CloseRequest())

            @test handler.state == STATE_CLOSING
        end

        @testset "a close frame is sent" begin
            logic, handler, writer = makeclientlogic(state=STATE_OPEN)

            handle(logic, CloseRequest())

            frame = getframe(writer, 1)
            @test frame.opcode == OPCODE_CLOSE
        end
    end

    @testset "the server replies to a client initiated closing handshake" begin
        @testset "state is CLOSING_SOCKET" begin
            # TODO Rewrite to put in correct closing state
            logic, handler, writer = makeclientlogic(state=STATE_CLOSING)

            close_frame = closeframe_from_server()
            handle(logic, FrameFromServer(close_frame))

            # TODO Use protocolstate() instead
            # TODO State is CLOSING
            @test logic.state == STATE_CLOSING_SOCKET
        end
    end

    @testset "the socket is closed cleanly" begin
        @testset "the state is CLOSED" begin
            # TODO Rewrite to put in correct closing state
            logic, handler, writer = makeclientlogic(state=STATE_CLOSING_SOCKET)

            handle(logic, SocketClosed())

            @test logic.state == STATE_CLOSED
        end

        @testset "the handler is notified of the state change" begin
            # TODO Rewrite to put in correct closing state
            logic, handler, writer = makeclientlogic(state=STATE_CLOSING_SOCKET)

            handle(logic, SocketClosed())

            @test handler.state == STATE_CLOSED
        end

        @testset "the client cleanup function is called" begin
            was_client_cleanup_called = false
            client_cleanup = () -> was_client_cleanup_called = true
            # TODO Rewrite to put in correct closing state
            logic, handler, writer = makeclientlogic(state=STATE_CLOSING_SOCKET,
                                                     client_cleanup=client_cleanup)

            handle(logic, SocketClosed())

            @test was_client_cleanup_called == true
        end
    end

    @testset "close connection if enough pongs have been missed" begin
        @testset "state is closed" begin
            logic, handler, writer = makeclientlogic(state=STATE_OPEN)

            handle(logic, PongMissed())

            @test logic.state == STATE_CLOSED
        end

        @testset "handler is notified of the state change" begin
            logic, handler, writer = makeclientlogic(state=STATE_OPEN)

            handle(logic, PongMissed())

            @test handler.state == STATE_CLOSED
        end
    end
end
