# SO Chat Room Class
# 
# This class represents a Stack Overflow Chat Room

class SOChatRoom
  def initialize(domain,room_id)
    @domain = domain
    @id = room_id
    @feeds = []
    
  end
  
  def url
    "http://#{@domain}/chats/#{@id}"
  end
end