# SO XMPP Logged In Chat User Class
# 
# This class represents a "real" XMPP user (that is, logged in to an XMPP server
# via a client) who is also a Stack Overflow Chat Room User.
# 
# If you're using the SOXMPP bridge, you're a SOXMPP_LoggedInUser :-)
# 
# It's purpose is to provide a proxy between the XMPP users and their Stack
# Overflow Chat User. Because they are XMPP Stack Overflow Chat Users, these
# objects are descendents 
# from the SOXMPP_Object class -- they are XMPP objects. Each one contains an
# SOChatUser object which represents the cuat user on the Stack Overflow side.

class SOXMPP_LoggedInUser < SOXMPP_ChatUser
  attr_accessor :fkey
  attr_accessor :cookie
  
  def initialize(room, iname, jid)
    super(room, iname, jid, nil)
    
    @feed = nil
    @rooms = {}
    
    @fkey = nil
    @cookie = nil
    
    @poll_interval = 2
    
    @poll_thread = nil
  end

  def jid
    attributes['jid'].nil? ? nil : Jabber::JID.new(attributes['jid'])
  end
  
  def authenticated?
    !(@fkey.nil? or @cookie.nil?)
  end
  
  def see(place)
    print "ERROR: unimplemented see()"
  end

  def send_message(fromresource, text, subject=nil)
    msg = Jabber::Message.new(jid, text)
    msg.type = :groupchat
    msg.subject = subject unless subject.nil?
    
    puts "Sending message to user #{jid}: #{msg}"
    
    @room.send(fromresource, msg)
  end

  def on_enter(thing, from)
    print "ERROR: unimplemented on_enter()\n"
  end

  def on_leave(thing, to)
    print "ERROR: unimplemented on_leave()\n"
  end
  
  def in_room?(soxmpp_room)
    puts "WARNING: unimplemented in_room? called!"
    false
  end
  
  def join(soxmpp_room)
    if !(in_room? soxmpp_room)
      
    end
    
    if @feed.nil?
      @feed = SOChatFeed.new(soxmpp_room.server)
    end
    
    @rooms[soxmpp_room.room_id] = soxmpp_room
    
    # Disabled because of #11: Moving poll function to the bridge
    # begin_polling
  end
  
  def begin_polling
    if @poll_thread.nil?
      @poll_thread = Thread.new do 
        while true
          poll
          sleep @poll_interval
        end
      end
    end
  end
  
  def poll
    #puts "poll called for #{self}"
    
    messages = @feed.get_new_messages_for_rooms @rooms.values
    messages.each do |room,room_messages|
      room_messages.each do |message|
        send_message(message[0],message[1])
      end
    end
  end
end
