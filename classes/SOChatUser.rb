# SO Chat User Class
# 
# This class represents a Stack Overflow Chat Room User

class SOChatUser
  attr_reader :user_id
  attr_reader :user_name
  
  def initialize(user_id, user_name)
    @user_id = user_id
    @user_name = user_name
  end
end
