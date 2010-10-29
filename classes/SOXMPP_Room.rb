# SO XMPP Chat Room Class
# 
# This class represents an XMPP Multi User Conference (MUC) Room for a given
# Stack Overflow Chat Room. This is the primary class for SOXMPP integration
# 
# It's purpose is to provide a representation of every Stack Overflow Chat Room
# as an XMPP MUC which any XMPP user can join. Upon joining, the XMPP user will
# be represented as an SOXMPP_LoggedInUser.


class SOXMPP_Room < REXML::Element
  attr_reader :name
  attr_reader :server
  attr_reader :room_id
  
  def initialize(bridge, name, server, room_id)
    super('soroom')
      
    @bridge = bridge
    @name = name
    @server = server
    @room_id = room_id
    
    @mySORoom = SOChatRoom.new(@server,@room_id)
  end
  
  def send(resource, stanza)
    # Avoid sending to things without JID
    if stanza.to != nil
      @bridge.send(node, resource, stanza)
    end
  end
  
  def node
    @name
  end

  def iname
    @name
  end
  
  def handle_presence(pres)
    
    print "Room \"#{@name}\" handling #{pres.type} presence: #{pres}\n"
    
    # A help for the irritated first:
    if pres.type == :subscribe
      msg = Jabber::Message.new(pres.from)
      msg.type = :normal
      msg.subject = "SO Chat Room help"
      msg.body = "You don't need to subscribe to my presence. Simply use your Jabber client to join the MUC or conference at #{pres.to.strip}"
      send(nil, msg)
      return(true)
    end
    
    # Look if user is already known
    user = nil
    each_element('soxmppobject') { |thing|
      if thing.kind_of?(SOXMPP_LoggedInUser) && pres.to.resource == thing.iname
      	print "found the user in our list of existing users"
        user = thing
      end

      # Disallow nick changes
      if thing.kind_of?(SOXMPP_LoggedInUser) && (pres.from == thing.jid) && (user != thing)
        print "user trying to change nick, disalloewed"
        answer = pres.answer(false)
        answer.type = :error
        answer.add(Jabber::ErrorResponse.new('not-acceptable', 'Nickchange not allowed'))
        send(thing.iname, answer)
        return(true)
      end
    }
    
    # Either nick-collission or empty nick
    unless (user.nil? || pres.from == user.jid) && (pres.to.resource.to_s.size > 1)
      print "Either nick-collission or empty nick\n"
      answer = pres.answer
      answer.type = :error
      if (pres.to.resource.to_s.size > 1)
        answer.add(Jabber::ErrorResponse.new('conflict', 'Nickname already used'))
      else
        answer.add(Jabber::ErrorResponse.new('not-acceptable', 'Please use a nickname'))
      end
      send(nil, answer)
      return(true)
    end

    # Add the valid user
    if user.nil?
      print "User is a new user, adding valid user.\n"
      user = add(SOXMPP_LoggedInUser.new(self, pres.to.resource, pres.from, -1))
      user.presence = pres
      #move_thing(player, attributes['start'])
      add_to_room(user)
      user.send_message('Help!', 'Send "/help" or "/?" to get a list of available commands any time.')
    # Or broadcast updated presence
    else
      print "User is an existing user, updating presence.\n"
      user.presence = pres

      each_element('soxmppobject') { |thing|
        # Broadcast presence to all who are here
        pres = Jabber::Presence.import(user.presence)
        pres.to = thing.jid
        send(user.iname, pres)
      }
    end

    # Remove the player instantly
    if pres.type == :error || pres.type == :unavailable
      print "User is unavailable, removing user.\n"
      #move_thing(player, nil)
      delete_element(user)
    end
  end

  def handle_message(msg)
    puts "Room \"#{@name}\" handling #message: #{msg}"
  end
  
  def add_to_room(user)
    each_element('soxmppobject') { |t|
      # Broadcast availability presence to enterer
      unless t.presence.nil?
        puts "Broadcast availability presence to enterer for #{t}"
        pres = Jabber::Presence.import(t.presence)
        pres.to = user.jid
        puts "  send(#{t.iname}, #{pres})"
        send(t.iname, pres)
      end
	
      # Broadcast availability presence to all who are here
      unless user.presence.nil?
        puts "Broadcast availability presence to all who are here"
        pres = Jabber::Presence.import(user.presence)
        pres.to = t.jid
        puts "  send(#{t.iname}, #{pres})"
        send(user.iname, pres)
      end
    }

    user.send_message(nil, " ")
    subject = @name
    subject[0] = subject[0,1].upcase
    user.send_message(nil, "Entering #{@name}", subject)
    user.send_message(nil, " ")
    user.join(self)
  end
end





