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

# Base class for all events initiated by XMPP (e.g. messages sent via XMPP to the system)
class SOXMPPEvent < SOChatEvent
  attr_accessor :from
  attr_accessor :to
  
  def initialize()
    
  end
end

# Base class for all messages sent via XMPP to the system via an XMPP user
class SOXMPPMessage < SOXMPPEvent
  attr_accessor :body
  attr_accessor :user
  
  def initialize(xmpp_message)
    @from = xmpp_message.from
    @to = xmpp_message.to
    @body = xmpp_message.body
  end
end

# Class for all messages sent via XMPP to a room via an XMPP user
class SOXMPPMessageToRoom < SOXMPPMessage
  def post_to(room)
    room.post_message(@body,@user.fkey,@user.cookie)
  end
end

# Class for "slash commands" sent from a user, that is, messages starting with "/"
class SOXMPPUserCommand < SOXMPPMessage
  def execute
    case @body
      when "/help"
        "Available topics are: help auth /fkey /cookie\n\nFor information on a topic, send: /help <topic>"
      when "/help auth"
        "To use this system, you must send your StackOverflow chat cookie and fkey to the system. To do this, use the /fkey and /cookie commands"
      when "/help /fkey"
        "Usage: /fkey <fkey>. Displays or sets your fkey, used for authentication. Send '/fkey' alone to display your current fkey, send '/fkey <something>' to set your fkey to <something>. You can obtain your fkey via the URL: javascript:alert(fkey().fkey)"
      when "/help /cookie"
        "Usage: /cookie <cookie>. Displays or sets your cookie, used for authentication. Send '/cookie' alone to display your current fkey, send '/cookie <something>' to set your cookie to <something>"
      when /\/fkey( .*)?/
        if $1.nil?
          "Your fkey is \"#{@user.fkey}\""
        else
          @user.fkey = $1.strip
          if @user.authenticated?
            "fkey set to \"#{@user.fkey}\". You are now logged in and can send messages to the chat"
          else
            "fkey set to \"#{@user.fkey}\". You must also send your cookie with /cookie before you can chat"
          end
        end
      when /\/cookie( .*)?/
        if $1.nil?
          "Your cookie is: \"#{@user.cookie}\""
        else
          if $1 == " chocolate chip"
            "You get a chocolate chip cookie!"
          else
            @user.cookie = $1.strip
            if @user.authenticated?
              "cookie set to \"#{@user.cookie}\". You are now logged in and can send messages to the chat"
            else
              "cookie set to \"#{@user.cookie}\". You must also send your fkey with /fkey before you can chat"
            end
          end
        end
      else
        "Unknown Command \"#{@body}\""
    end
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
  
  def initialize(room=nil,from=nil,body='')
    @room = room
    @from = from
   @html_body = @body = body
  end
  
  def xhtml_body
    html = @html_body
    xml = Tidy.open(:show_warnings=>true) do |tidy|
      tidy.options.output_xhtml = true
      tidy.options.show_body_only = true
      tidy.options.wrap = 0
      tidy.options.char_encoding = 'utf8'
      tidy.options.input_encoding = 'utf8'
      xml = tidy.clean(html)
      xml
    end
  end
  
  def encoded_body=(encoded_html)
    @body = CGI.unescapeHTML(encoded_html)
    
    @html_body = encoded_html.gsub(/<code>(.*?)<\/code>/im,'<span class="code" style="font-family:Consolas,Menlo,Monaco,\'Lucida Console\',\'Liberation Mono\',\'DejaVu Sans Mono\',\'Bitstream Vera Sans Mono\',\'Courier New\',monospace,serif;white-space:pre-wrap;word-wrap:normal;">\1</span>')
    
    @html_body.gsub!(/&nbsp;/,' ')
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
