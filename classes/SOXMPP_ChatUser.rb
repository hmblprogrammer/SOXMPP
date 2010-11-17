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
  attr_accessor :fullname
  
  def initialize(sochatuser)
    super()
    attributes['name'] = sochatuser.user_name
    attributes['jid'] = nil
    
    #puts "DEBUG: #{attributes.inspect}"
    #
    #attributes['presence'] = {:show => 'chat',  :status => ''}
    
    @sochatuser = sochatuser
    
    @fullname = sochatuser.user_name
  end
  
  def set_vcard_info
    Thread.new do
      @vcard = Jabber::Vcard::IqVcard.new
      vcard['FN'] = @fullname
      vcard['NICKNAME'] = @sochatuser.user_name
      
      gravitar = Net::HTTP.get(Uri.parse(@sochatuser.gravitar_url))
      
      
    end
  end
end
