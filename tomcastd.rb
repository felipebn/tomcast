require 'rubygems'
require 'carrier'
require 'json'
require 'thread'


module Tomcast
    class TomcastDaemon
        def initialize( tomcastapp )
            puts "Daemon inicializado..."
            @carrier = Tomcast::Carrier.new( "224.0.0.13" , 38987 )
            @evts = Queue.new
            @tomcastapp = tomcastapp
            @my_ip = nil
        end

        def start
            wait_kill = true

            exec = lambda{|msg,info|
                puts "Info: " + info.inspect
                puts "Msg received: " + msg 
                
                sender_ip = info.last
                #simula uma conexao no google pra pegar o ip da maquina
                UDPSocket.open {|s| s.connect('64.233.187.99', 1); @my_ip = s.addr.last ; s.close }
                if sender_ip == @my_ip 
                    return
                end

                begin
                    payload = JSON.parse( msg )
                    unless payload["PING"].nil?
                        evt = payload["PING"]
                        # se o evento for esperado, vamos dar ACK
                        if @tomcastapp.is_expected? evt
                            @carrier.send( {"ACK" => evt}.to_json )
                        end
                    end
                    unless payload["ASK"].nil?
                        evt = payload["ASK"]
                        # se o evento for esperado, vamos incluir na queue de eventos para o usuario responder
                        if @tomcastapp.is_expected? evt
                            @evts << evt
                        end
                    end
                rescue
                    puts "msg não tratada"
                end

            }
            @carrier.listen( exec , lambda{|| wait_kill} )
            puts "Daemon terminado..."
        end

        def next_evt
            @evts.pop(true)
        end

        #envia a resposta do evento
        def answer(evt , vote)
            puts "Eviando dados ..."
            payload = "{\"ANS\":\"%s\",\"VOTE\":%d }" % [evt,vote]
            puts "PAYLOAD: " + payload
            @carrier.send( payload )
        end

    end
end




