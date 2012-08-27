# SO Chat Feed Class
# 
# This class represents a Stack Overflow Chat Room Event Feed.
# 
# It's purpose is to provide a method for other objects to query for events,
# and this class will act as a translation device between the JSON feed of chat
# events and Ruby objects which represent those events

class SOChatFeed
  def initialize(server)
    @server = server
    @last_update = 0
  end
  
  def get_messages_for_room_id(room_id)
    res = Net::HTTP.post_form(URI.parse("http://@server/room/#{room_id}/events"),{'mode'=>'Messages', 'since'=> @last_update})
    data = JSON.parse(res.body)
  end
  
  def get_new_messages_for_rooms(room_list)
    #puts "DEBUG: get_new_messages_for_rooms(#{room_list}) called"
    room_ids = room_list.collect {|r| r.room_id}
    #puts "DEBUG: room_ids: #{room_ids}"
    get_new_messages_for_room_ids(room_ids)
  end
  
  def get_new_events_for_rooms(rooms)
     
    #puts "DEBUG: get_new_messages_for_room_ids(#{rooms}) called"
    
    request = {}
    rooms.each do |room|
      request["r"+"#{room.room_id}"] = @last_update
    end
    
    #puts "DEBUG: sending request: #{request.inspect}"
    
    
    res = Net::HTTP.post_form(URI.parse("http://#{@server}/events"),request)
    data = JSON.parse(res.body)
    
    #puts "DEBUG: received data: #{data.inspect}"
    
    events = SOChatEventCollection.new
    
    rooms.each do |room|
      rid = "r"+"#{room.room_id}"
      if !data[rid].nil?
        @last_update = data[rid]['t'] if data[rid]['t']
        
        if data[rid]["e"]
          #puts "DEBUG: Found events for room #{rid}"
          data[rid]["e"].each do |e|
            #puts "DEBUG: found an event: #{e.inspect}"
            case e["event_type"]
              when 1
                event = SOChatMessage.new(room,e['user_name'])
                event.encoded_body = e['content']
                event.server = @server
                events.push event
              when 2
                event = SOChatMessageEdit.new(room,e['user_name'])
                event.encoded_body = e['content']
                event.server = @server
                events.push event
              when 3
                user = room.bridge.get_so_chat_user(e['user_id'], e['user_name'])
                event = SOChatUserJoinRoom.new(room,user)
                event.server = @server
                events.push event
              when 4
                user = room.bridge.get_so_chat_user(e['user_id'], e['user_name'])
                event = SOChatUserLeaveRoom.new(room,user)
                event.server = @server
                events.push event
            end
          end
        end
      end
    end
    
    events
  end
  
  def get_new_messages_for_room_ids(rooms)
     
    #puts "DEBUG: get_new_messages_for_room_ids(#{rooms}) called"
    
    request = {}
    rooms.each do |r|
      request["r"+"#{r}"] = @last_update
    end
    
    #puts "DEBUG: sending request: #{request.inspect}"
    
    
    res = Net::HTTP.post_form(URI.parse("http://#{@server}/events"),request)
    data = JSON.parse(res.body)
    
    #puts "DEBUG: received data: #{data.inspect}"
    
    messages = {}
    
    data.each do |rid,rdata|
      @last_update = rdata['t'] if rdata['t']
      
      messages[rid] = []
      
      if rdata["e"]
        #puts "DEBUG: Found events for room #{rid}"
        rdata["e"].each do |e|
          #puts "DEBUG: found an event: #{e.inspect}"
          if e["event_type"] == 1
            #puts "DEBUG: found a message!"
            msg = CGI.unescapeHTML( e['content'] )
            messages[rid].push [e['user_name'],msg]
          end
        end
      end
    end
    
    messages
  end
end
