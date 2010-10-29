# SO - XMPP Bridge Class
# 
# The heart and soul of the SOXMPP project, this class acts as a bridge between
# a Stack Overflow, LLC chat server and an XMPP (Jabber) server.
# 
# It's purpose is to connect to an XMPP server and act as an XMPP "Component"
# (See: http://xmpp.org/extensions/xep-0114.html). Objects of this class will
# activate on a subdomain of the XMPP server, and will then provide MUCs on that
# subdomain


class SOChat_XMPP_Bridge
  def initialize(jid, secret, addr, port=5275)
    # Initialize private variables
    @rooms = {}
    
    # Create our component. This does the bulk of the work, it connects to the
    # XMPP server and is the vehiclue through which we provide all functionality
    @component = Jabber::Component.new(jid)
    @component.connect(addr, port)
    @component.auth(secret)
    @component.on_exception { |e,|
      puts "#{e.class}: #{e}\n#{e.backtrace.join("\n")}"
    }
    
    # Add callbacks, so when stuff happens on the XMPP server, methods of this
    # object get called:
    @component.add_iq_callback { |iq|
      handle_iq(iq)
    }
    @component.add_presence_callback { |pres|
      handle_presence(pres)
    }
    @component.add_message_callback { |msg|
      handle_message(msg)
    }
    
    puts "Bridge component up and running"
  end
  
  # Add a Stack Overflow Chat Room to this bridge by room name, server and ID
  def add_room(name,server,room_id)
    print "Adding XMPP room \"#{name}\" connected to room ID #{room_id} on #{server}...\n"
    begin
      room = SOXMPP_Room.new(self, name, server, room_id)
      #room = SOXMPP_Room.new(name, server, room_id)
    rescue Exception => e
      puts " #{e.to_s}"
      exit
    end
    #@rooms[room.node] = room
    @rooms[name] = room
    puts " #{room.iname}"
  end
  
  # Add a Stack Overflow Chat Room to this bridge from an XML file. This doesn't work yet.
  # TODO: Make this work
  def add_room_from_file(file)
    print "Adding room from #{file}..."
    begin
      room = SOXMPP_Room.new_from_file(self, file)
    rescue Exception => e
      puts " #{e.to_s}"
      exit
    end
    @rooms[room.node] = room
    puts " #{room.iname}"
  end

  def send(roomnode, roomresource, stanza)
    #puts "Bridge sending node=#{roomnode}, roomresource=#{roomresource}, stanza=#{stanza}"
    stanza.from = Jabber::JID.new(roomnode, @component.jid.domain, roomresource)
    @component.send(stanza)
  end
  
  # I'm not sure exactly what this does, it was in the example and it's necessary.
  # Don't mess with it unless you understand this project better than I do.
  def handle_iq(iq)
    puts "iq: from #{iq.from} type #{iq.type} to #{iq.to}: #{iq.queryns}"

    if iq.query.kind_of?(Jabber::Discovery::IqQueryDiscoInfo)
      handle_disco_info(iq)
      true
    elsif iq.query.kind_of?(Jabber::Discovery::IqQueryDiscoItems)
      handle_disco_items(iq)
      true
    else
      false
    end
  end
  
  # I understand this even less well than handle_iq. Again, I know things break
  # horribly without it. Again, don't mess with it unless you understand XMPP or
  # you want this project to fail.
  def handle_disco_info(iq)
    if iq.type != :get
      answer = iq.answer
      answer.type = :error
      answer.add(Jabber::ErrorResponse.new('bad-request'))
      @component.send(answer) if iq.type != :error
      return
    end
    answer = iq.answer
    answer.type = :result
    if iq.to.node == nil
      answer.query.add(Jabber::Discovery::Identity.new('conference', 'Adventure component', 'text'))
      answer.query.add(Jabber::Discovery::Feature.new(Jabber::Discovery::IqQueryDiscoInfo.new.namespace))
      answer.query.add(Jabber::Discovery::Feature.new(Jabber::Discovery::IqQueryDiscoItems.new.namespace))
    else
      room = @rooms[iq.to.node]
      if room.nil?
        answer.type = :error
        answer.query.add(Jabber::ErrorResponse.new('item-not-found', 'The room you are trying to reach is currently unavailable.'))
      else
        answer.query.add(Jabber::Discovery::Identity.new('conference', room.iname, 'text'))
        answer.query.add(Jabber::Discovery::Feature.new(Jabber::Discovery::IqQueryDiscoInfo.new.namespace))
        answer.query.add(Jabber::Discovery::Feature.new(Jabber::Discovery::IqQueryDiscoItems.new.namespace))
        answer.query.add(Jabber::Discovery::Feature.new(Jabber::MUC::XMUC.new.namespace))
        answer.query.add(Jabber::Discovery::Feature.new(Jabber::MUC::XMUCUser.new.namespace))
      end
    end
    @component.send(answer)
  end
  
  # No comment. See handle_disco_info
  def handle_disco_items(iq)
    
    puts "DEBUG: handle disco items: #{iq}"
    
    if iq.type != :get
      answer = iq.answer
      answer.add(Jabber::ErrorResponse.new('bad-request'))
      @component.send(answer)
      return
    end
    answer = iq.answer
    answer.type = :result
    if iq.to.node == nil
      @rooms.each { |node,room|
        domain = @component.jid.domain
        room_name = room.iname
        answer.query.add(Jabber::Discovery::Item.new(Jabber::JID.new(node, domain), room_name))
      }
    end
    @component.send(answer)
  end
  
  # This handler is called when an XMPP user's "presence" changes, that is, when
  # a user goes "away", "available", signs on or signs off. Essentially, this
  # simply forwards the presence to the SOXMPP_Rooms the user is in
  def handle_presence(pres)
    puts "presence: from #{pres.from} type #{pres.type} to #{pres.to}"

    room = @rooms[pres.to.node]
    if room.nil?
      answer = pres.answer
      answer.type = :error
      answer.add(Jabber::ErrorResponse.new('item-not-found', 'The room you are trying to reach is currently unavailable.'))
      @component.send(answer)
    else
      room.handle_presence(pres)
    end

    true
  end
  
  # This handler is called when an XMPP user sends a message to the XMPP
  # component. It essentially just forwards the message on to the rooms the user
  # is trying to send to
  def handle_message(msg)
    puts "message: from #{msg.from} type #{msg.type} to #{msg.to}: #{msg.body.inspect}"

    room = @rooms[msg.to.node]
    if room.nil?
      answer = msg.answer
      answer.type = :error
      answer.add(Jabber::ErrorResponse.new('item-not-found', 'The room you are trying to reach is currently unavailable.'))
      @component.send(answer)
    else
      room.handle_message(msg)
    end

    true
  end
end