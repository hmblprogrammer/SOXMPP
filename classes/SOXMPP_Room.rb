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
  attr_reader :bridge
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
  
  def get_soxmpp_user_by_jid(jid)
    user = nil
    each_element('soxmppobject') { |t|
      user = t if t.jid == jid
    }
    user
  end
  
  def send_message(fromresource, text, subject=nil, html=nil)
    puts "DEBUG: Sending message to room #{@name}: #{text}"
        
    each_element('soxmppobject') { |t|
      # Broadcast message to room
      unless t.presence.nil?
        msg = Jabber::Message.new(t.jid, text)
        msg.type = :groupchat
        msg.subject = subject unless subject.nil?
        
        unless html.nil?
          #puts "DEBUG: This message contains HTML."
          # Create the html part
          h = REXML::Element::new("html")
          h.add_namespace('http://jabber.org/protocol/xhtml-im')
          
          # The body part with the correct namespace
          b = REXML::Element::new("body")
          b.add_namespace('http://www.w3.org/1999/xhtml')
          
          # The html itself
          txt = REXML::Text.new(html, false, nil, true, nil, %r/.^/ )
          
          # Add the html text to the body, and the body to the html element
          b.add(txt)
          h.add(b)
          
          #puts "DEBUG: Adding the HTML to the message"
          # Add the html element to the message
          msg.add_element(h)
        end
        
        #puts "DEBUG: Sending message to user #{t.jid}: #{msg}"
        
        send(fromresource, msg)
      end
    }
  end
  
  def send_message_to_user(user,fromresource, text, subject=nil, html=nil)
    puts "DEBUG: Sending message from room #{@name} to #{user}: #{text}"

    msg = Jabber::Message.new(user, text)
    msg.type = :groupchat
    msg.subject = subject unless subject.nil?
    
    unless html.nil?
      #puts "DEBUG: This message contains HTML."
      # Create the html part
      h = REXML::Element::new("html")
      h.add_namespace('http://jabber.org/protocol/xhtml-im')
      
      # The body part with the correct namespace
      b = REXML::Element::new("body")
      b.add_namespace('http://www.w3.org/1999/xhtml')
      
      # The html itself
      txt = REXML::Text.new(html, false, nil, true, nil, %r/.^/ )
      
      # Add the html text to the body, and the body to the html element
      b.add(txt)
      h.add(b)
      
      #puts "DEBUG: Adding the HTML to the message"
      # Add the html element to the message
      msg.add_element(h)
    end
    
    #puts "DEBUG: Sending message to user #{user}: #{msg}"
    
    send(fromresource, msg)
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
      user = add(@bridge.get_soxmpp_logged_in_user(pres.to.resource, pres.from))
      user.presence = pres
      #move_thing(player, attributes['start'])
      add_to_room(user)
      user.send_message(self, 'Help!', 'Send "/help" or "/?" to get a list of available commands any time.')
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
    puts "DEBUG: Room \"#{@name}\" handling message: #{msg}"
    puts "DEBUG: message: from #{msg.from} type #{msg.type} to #{msg.to}: #{msg.body.inspect}"
    
    event = nil
    
    if msg.body =~ /^\/me.*/
      event = SOXMPPMessageToRoom.new(msg)
    elsif msg.body =~ /^\/reddot.*/
      eventr = SOChatMessage.new(self,@name,'A Red Dot')
      eventr.encoded_body = '<img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAABGdBTUEAALGPC/xhBQAAAAlwSFlzAAALEwAACxMBAJqcGAAAAAd0SU1FB9YGARc5KB0XV+IAAAAddEVYdENvbW1lbnQAQ3JlYXRlZCB3aXRoIFRoZSBHSU1Q72QlbgAAAF1JREFUGNO9zL0NglAAxPEfdLTs4BZM4DIO4C7OwQg2JoQ9LE1exdlYvBBeZ7jqch9//q1uH4TLzw4d6+ErXMMcXuHWxId3KOETnnXXV6MJpcq2MLaI97CER3N0vr4MkhoXe0rZigAAAABJRU5ErkJggg==" alt="Red dot" />'
      handle_event eventr
    elsif msg.body =~ /^\/.*/
      event = SOXMPPUserCommand.new(msg)
    else
      event = SOXMPPMessageToRoom.new(msg)
    end
    
    if !event.nil?
      event.user = get_soxmpp_user_by_jid event.from
      handle_event event
    end
  end
  
  def handle_event the_event
    puts "DEBUG: Room #{self} handling event: #{the_event}"
    
    case the_event
      when SOChatMessageEdit
        send_message(the_event.from, "**EDIT**: #{the_event.body}", nil, "<span style='color:#999;'><b>Edit: </b></span><span>#{the_event.xhtml_body}</span>")
      when SOChatMessage
        send_message(the_event.from, the_event.body, nil, the_event.xhtml_body)
      when SOXMPPUserCommand
        send_message_to_user(the_event.from, @name, the_event.execute)
      when SOXMPPMessageToRoom
        if the_event.user.authenticated?
          the_event.post_to @mySORoom
        else
          send_message_to_user(the_event.from, @name, 'Error: You must be logged in to post messages.')
        end
      when SOChatUserJoinRoom
        #puts "DEBUG: #{self} handling SOChatUserJoinRoom event #{the_event}"
        user = self.add(@bridge.get_soxmpp_chat_user(the_event.user))
        #puts "DEBUG: added the user"
        #add(user)
        broadcast_enter(user)
        #puts "DEBUG: added the user to the room"
    end
  end
  
  def add_to_room(user)
    each_element('soxmppobject') { |t|
      # Broadcast availability presence to enterer
      unless t.presence.nil?
        #puts "Broadcast availability presence to enterer for #{t}"
        pres = Jabber::Presence.import(t.presence)
        pres.to = user.jid
        #puts "  send(#{t.iname}, #{pres})"
        send(t.iname, pres)
      end
	
      # Broadcast availability presence to all who are here
      unless user.presence.nil?
        #puts "Broadcast availability presence to all who are here"
        pres = Jabber::Presence.import(user.presence)
        pres.to = t.jid
        #puts "  send(#{t.iname}, #{pres})"
        send(user.iname, pres)
      end
    }

    user.send_message(self, nil, " ")
    subject = @name
    subject[0] = subject[0,1].upcase
    user.send_message(self, nil, "Entering #{@name}", subject)
    user.send_message(self, nil, " ")
    user.join(self)
  end
  
  def broadcast_enter(user)
    puts "DEBUG: broadcast_enter called for #{user}"
    #puts "user presence is: #{user.presence}"
    each_element('soxmppobject') { |t|
      # Broadcast availability presence to all who are here
      unless user.presence.nil?
        #puts "Broadcast availability presence of #{user} to all who are here"
        pres = Jabber::Presence.import(user.presence)
        pres.to = t.jid
        #puts "  send(#{t.iname}, #{pres})"
        send(user.iname, pres)
      end
    }
  end
end





