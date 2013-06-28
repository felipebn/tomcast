require 'socket'
require 'ipaddr'

module Tomcast
=begin
    O valor de addr deve ser um endereço separado para multicasting como por exemplo: 224.0.0.13        
=end
    class Carrier
        def initialize( addr,port )
            @maddr = addr
            @port = port
            @iprecv =  IPAddr.new(@maddr).hton + IPAddr.new("0.0.0.0").hton
        end

        def send( msg )
            begin
                socket = UDPSocket.open
                socket.setsockopt(Socket::IPPROTO_IP, Socket::IP_TTL, [1].pack('i'))
                socket.send(msg, 0, @maddr, @port )
            ensure
                socket.close 
            end
        end

        def listen(executor,stopswitch)
            begin
                sock  = UDPSocket.new
                sock.setsockopt(Socket::SOL_SOCKET,Socket::SO_REUSEADDR,1)
                sock.bind(@maddr,@port)
                sock.setsockopt(Socket::IPPROTO_IP, Socket::IP_ADD_MEMBERSHIP,@iprecv)

                #define timeout:
                timeout = 5
                secs = Integer(timeout)
                usecs = Integer((timeout - secs) * 1_000_000)
                optval = [secs, usecs].pack("l_2")
                sock.setsockopt Socket::SOL_SOCKET, Socket::SO_RCVTIMEO, optval
                sock.setsockopt Socket::SOL_SOCKET, Socket::SO_SNDTIMEO, optval

                while stopswitch.call()
                    msg, info = sock.recvfrom(1024)
                    t = Thread.new(msg,info,executor){|m,i,prc|
                        prc.call( m , i )
                    }
                    #inicia a threa e volta pra espera de outras comunicações
                end
            ensure
                sock.close
            end
            return
        end
    end
end


