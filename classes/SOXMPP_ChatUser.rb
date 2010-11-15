# SO XMPP Chat User Class
# 
# This class represents a Stack Overflow Chat Room User, represented in the XMPP
# MUC user list
# 
# It's purpose is to provide a representation of every Stack Overflow Chat User
# inside the conference room on the XMPP server. These objects are descendents 
# from the SOXMPP_Object class -- they are XMPP objects. Each one contains an
# SOChatUser object which represents the cuat user on the Stack Overflow side.

class SOXMPP_ChatUser < SOXMPP_Object
  attr_reader :sochatuser
  
  def initialize(room, iname, jid, sochatuser)
    super(room)
    attributes['name'] = iname
    attributes['jid'] = jid.to_s
    
    #puts "DEBUG: #{attributes.inspect}"
    #
    #attributes['presence'] = {:show => 'chat',  :status => ''}
    
    @sochatuser = sochatuser
  end
end
