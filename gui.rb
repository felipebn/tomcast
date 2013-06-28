require 'rubygems'
require 'gtk2'
require 'json'
require 'etc'
require 'tomcastd'

THIS_FILE = File.symlink?(__FILE__) ? File.readlink(__FILE__) : __FILE__

class ObjInt
    def initialize(x)
        @i = x
    end
    def decrease
        puts "my i: @i: " + @i.to_s
        @i -= 1
        @i
    end
    def to_i
        @i
    end
end


class TomcastApp

    CFG_DIR=Etc.getpwuid.dir + "/.tomcast"
    CFG_FILE="config"

    HASH_EVTS={
        "RESTART_TOMCAT"=>"Restart Tomcat",
        "RESTART_TOMCAT3"=>"Restart Tomcat3",
        "RESTART_TOMCAT2"=>"Restart Tomcat2",
        "RESTART_TOMCAT4"=>"Restart Tomcat4",
        "BUILD_BASILEIA"=>"Build Basiléia",
        "BUILD_CREDITO"=>"Build Crédito",
        "BUILD_COMM"=> "Build Commodities",
        "BUILD_REP"=>"Build Reputação"
    }

    OPT_AUTO_RESPONSE = {
        "AUTO_RESP" => "Recusar todas as votações"
    }

    KEYS_CHKS_TOMCAT=["RESTART_TOMCAT","RESTART_TOMCAT3","RESTART_TOMCAT2","RESTART_TOMCAT4"]
    KEYS_CHKS_SISTEMAS=["BUILD_BASILEIA","BUILD_CREDITO","BUILD_COMM" , "BUILD_REP"]

    def initialize

        @checkboxes = []
        @config = {}
        windowlabel = Gtk::Label.new("")
        windowlabel.markup =  "<b>Selecione os eventos de interesse</b>"


        frameTomcats = build_frame( "Eventos do Tomcat" ,  KEYS_CHKS_TOMCAT )
        frameSistemas = build_frame( "Eventos dos Sistemas" ,  KEYS_CHKS_SISTEMAS )

        #vertical box para alocar os blocos da aplicação!
        vbox = Gtk::VBox.new(false,0)
        vbox.pack_start( windowlabel , false ,false , 5 )

        vbox.pack_start( frameTomcats , false , false , 20 )

        vbox.pack_start( frameSistemas , false , false , 20 )


        frameTempo = Gtk::Frame.new("Resposta automática")
        hbox = Gtk::HBox.new(false,0)
        check = Gtk::CheckButton.new(OPT_AUTO_RESPONSE["AUTO_RESP"])
        check.name = "AUTO_RESP"
        @checkboxes << check
        hbox.pack_start( check , false , false , 16 )
        frameTempo.add_child( Gtk::Builder.new , hbox )

        vbox.pack_start( frameTempo , false , false , 20 )


        @checkboxes.each do |cb|
            cb.signal_connect("clicked") { |target|
                action_check_option(target)
            }
        end

        window = Gtk::Window.new
        window.signal_connect("window_state_event") {|w,e|
            if e.changed_mask == Gdk::EventWindowState::WindowState::ICONIFIED
                hide_window
                w.deiconify
            end
        }

        window.signal_connect("destroy") {
            puts "destroy event occurred"
            store_state
        }

        #carrega o estado da configuracao
        load_state

        window.title = "Tomcast"
        window.deletable = false
        window.resizable = false
        window.icon = Gdk::Pixbuf.new(File.dirname( THIS_FILE ) +  '/tomcast.png')
        window.border_width = 10
        window.add(vbox)

        @daemon = Tomcast::TomcastDaemon.new( self )

        Thread.new( @daemon ) {|d| d.start}

        @this = window
    end

    def action_check_option(checkbox)
        puts checkbox.name + ": " + checkbox.active?.to_s
        @config[checkbox.name] = checkbox.active?
    end

    def build_frame( tituloFrame , keys )
        i = 0
        hbox = Gtk::HBox.new(false,10)
        tmpbox = Gtk::VBox.new( false , 0 )

        check = Gtk::CheckButton.new(HASH_EVTS[keys[i]])
        check.name = keys[i]
        tmpbox.pack_start( check , false , false , 16 )
        @checkboxes << check

        i = i.succ

        check = Gtk::CheckButton.new(HASH_EVTS[keys[i]])
        check.name = keys[i]
        tmpbox.pack_start( check , false , false , 16 )
        @checkboxes << check

        hbox.pack_start( tmpbox , false , false , 0)

        i = i.succ

        tmpbox = Gtk::VBox.new( false , 0 )

        check = Gtk::CheckButton.new(HASH_EVTS[keys[i]])
        check.name = keys[i]
        tmpbox.pack_start( check , false , false , 16 )
        @checkboxes << check

        i = i.succ

        check = Gtk::CheckButton.new(HASH_EVTS[keys[i]])
        check.name = keys[i]
        tmpbox.pack_start( check , false , false , 16 )
        @checkboxes << check

        hbox.pack_start( tmpbox , false , false , 0)

        frame = Gtk::Frame.new(tituloFrame)
        frame.add_child( Gtk::Builder.new , hbox )
        
        frame
    end

    def store_state
        settedup = File.exists?( CFG_DIR )
        puts "salvando config..." + CFG_DIR
        unless settedup
            begin
                Dir.mkdir( CFG_DIR )
                settedup = true
            rescue Exception => e
                puts "Error: Could not create config directory"
                puts "Exception raised: " + e
            end
        end
        if settedup 
            path = CFG_DIR + "/" + CFG_FILE
            out = File.new( path , "w" )
            out.syswrite( @config.to_json )
        end
    end

    def load_state
        path = CFG_DIR + "/" + CFG_FILE
        if File.exist?( path )
            json = IO.read( path )
            @config = JSON.parse( json )
            @checkboxes.each do |chk|
                chk.active = @config[chk.name]
            end
        else
            @checkboxes.each do |chk|
                @config[chk.name] = false
            end
        end

    end
    
    def display_window
        @this.show_all
    end

    def hide_window
        @this.hide_all
    end

    def destroy
        @this.destroy
    end

    def is_expected?( evt )
        !@config[evt].nil? && @config[evt]
    end 


    def check_evt
        begin
            evt = @daemon.next_evt
            vote = 0 if @config["AUTO_RESP"]
            if vote.nil? 
                vote = ask_user evt 
            end
            @daemon.answer( evt , vote )
        rescue
            #sem eventos
        end
        true
    end

    def ask_user( evt )
        descricao = HASH_EVTS[evt]
        dialog = Gtk::MessageDialog.new( nil , Gtk::Dialog::DESTROY_WITH_PARENT,Gtk::MessageDialog::QUESTION,Gtk::MessageDialog::BUTTONS_YES_NO, "" )
        dialog.icon = Gdk::Pixbuf.new(File.dirname( THIS_FILE ) +  '/tomcast.png')
        dialog.title = "Votação do evento %s" % descricao
        v = 0

        i = 5
        dialog.markup = "Votação para o evento <b>%s</b>. Qual o seu voto?" % [descricao]
        dialog.set_secondary_use_markup(true)

        timeout_id = Gtk.timeout_add(1000) do
            dialog.set_secondary_text("<b>Tempo restante: %d segundos</b>" % [i])
            if (i -= 1) < 0 
                dialog.response( Gtk::Dialog::RESPONSE_NONE )
                dialog.set_secondary_text("<b>Tempo restante: votação encerrada</b>")
                dialog.set_message_type(Gtk::MessageDialog::WARNING)
                dialog.vbox.remove( dialog.vbox.children.last )
            end
            true
        end

        dialog.run do |r|
            case r
            when Gtk::Dialog::RESPONSE_YES
                v = 1
            when Gtk::Dialog::RESPONSE_NONE
                v = 1
            else 
                puts r
                v = 0
            end
        end
        Gtk.timeout_remove( timeout_id )
        puts "Voto: " + v.to_s

        v
    end


end






#tomcast = TomcastApp.new


#Gtk.main
