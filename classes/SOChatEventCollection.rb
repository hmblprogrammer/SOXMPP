# SO Chat Event Collection Class
# 
# This class represents a collection of Stack Overflow Chat Room Events.
# 
# It's purpose is to allow easy access to a list of chat room events, to find 
# all events by room, by server, etc.

class SOChatEventCollection
  def initialize
    @my_events_by_server = {}
  end
  
  def push(event)
    server = event.server
    room = event.room
    
    server = "n/a" if server.nil?
    room = -1 if room.nil?
    
    @my_events_by_server[server] = {} if @my_events_by_server[server].nil?
    @my_events_by_server[server][room.room_id] = [] if @my_events_by_server[server][room].nil?
    @my_events_by_server[server][room.room_id].push(event)
    
    #puts "DEBUG: Pushed an event #{event}. Events list: #{@my_events_by_server.inspect}"
  end
  
  def for_server(server)
    events = []
    
    if !@my_events_by_server[server].nil?
      @my_events_by_server[server].each do |room,room_events|
        room_events.each {|event| events.push(event) }
      end
    end
    
    events
  end
  
  def for_room(room)
    #puts "DEBUG: SOChatEventCollection.for_room #{room} called"
    if !@my_events_by_server[room.server].nil?
      #puts "DEBUG: found events for server #{room.server} in this collection"
      if !@my_events_by_server[room.server][room.room_id].nil?
        #puts "DEBUG: found events for room id #{room.room_id} in this collection"
        return  @my_events_by_server[room.server][room.room_id]
      else
        #puts "DEBUG: no events for room id #{room.room_id} in this collection"
        return []
      end
    end
    
    #puts "DEBUG: no events for server #{room.server}. Events list: #{@my_events_by_server.inspect}"
    
    []
  end
end
