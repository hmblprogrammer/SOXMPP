# SO Chat Event Class
# 
# This class represents a Stack Overflow Chat Room Event.
# 
# It's purpose is to represent events that occur in a chat room, for example
# messages being sent, users logging in/out, edits, deletions, etc.

# Base class for all chat events
class SOChatEvent
  attr_accessor :server
  
  def initialize(server=nil)
    @server = server
  end
end

# Base class for all chat events tied to a room (for now, this is every event)
class SOChatRoomEvent < SOChatEvent
  attr_accessor :room
  
  def initialize(server=nil,room=nil)
    @server = server
    @room = room
  end
end

# Class for messages sent to a chat room
class SOChatMessage < SOChatRoomEvent
  attr_accessor :from, :body
  
  def initialize(room=nil,from=nil,body=nil)
    @room = room
    @from = from
    @body = body
  end
end

# Class for message edits sent to a chat room
class SOChatMessageEdit < SOChatMessage
  
end

# Base class for all events which relate to users
class SOChatUserEvent < SOChatRoomEvent
  attr_accessor :user
  
  def initialize(user=nil)
    @user = user
  end
end

# Class for event of a user joining a room
class SOChatUserJoinRoom < SOChatUserEvent
  attr_accessor :room
  
  def initialize(user=nil, room=nil)
    @user = user
    @room = room
  end
end

# Class for event of a user leaving a room
class SOChatUserLeaveRoom < SOChatUserEvent
  attr_accessor :room
  
  def initialize(user=nil, room=nil)
    @user = user
    @room = room
  end
end

# Base class for event of a user changing state, going idle, away, etc
class SOChatUserStateChange < SOChatUserEvent

end

# Class for event of a user going idle
class SOChatUserGoIdle < SOChatUserStateChange

end

# Class for event of a user going "away" (Via XMPP Presence)
class SOChatUserGoAway< SOChatUserStateChange

end

# Class for event of a user returning from idle
class SOChatUserReturnFromIdle < SOChatUserStateChange

end

# Class for event of a user returning from away (Via XMPP Presence)
class SOChatUserReturnFromAway < SOChatUserStateChange

end
