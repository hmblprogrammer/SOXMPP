# SO Chat Feed Class
# 
# This class represents an XMPP Object for the SOXMPP Project
# 
# This is the parent class for any object which resides on the XMPP Server. For
# example, users in a MUC conference room are all XMPP objects. This class 
# provides a parent where methods common to all XMPP objects will reside.
# 
# I'm following the design from the xmpp4r package's "adventure" example... so
# this may not be the best design, but I think I see the reasoning behind it.


class SOXMPP_Object < REXML::Element
  def initialize(room)
    super('soxmppobject')
    @room = room
  end

  def add(xmlelement)
    if xmlelement.kind_of?(REXML::Element) && (xmlelement.name == 'presence')
      super(Jabber::Presence.import(xmlelement))
    else
      super(xmlelement)
    end
  end

  def iname
    attributes['name']
  end

  def command_name
    attributes['command-name'].nil? ? iname : attributes['command-name']
  end

  def place
    "not implemented"
  end

  def place=(p)
    print "Error: place= used on an SOXMPP_Object"
    "not implemented"
  end

  def jid
    nil
  end

  def presence
    xe = nil
    each_element('presence') { |pres|
      xe = Jabber::Presence.import(pres)
    }
    xe = Jabber::Presence.new if xe.nil?
    if self.kind_of?(SOXMPP_ChatUser)
      xe.add(Jabber::MUC::XMUCUser.new).add(Jabber::MUC::XMUCUserItem.new(:none, :participant))
    else
      xe.add(Jabber::MUC::XMUCUser.new).add(Jabber::MUC::XMUCUserItem.new(:owner, :moderator))
    end
    xe
  end

  def presence=(pres)
    delete_elements('presence')
    add(pres)
  end

  def see(place)
  end

  def send_message(fromresource, text, subject=nil)
  end

  def send_message_to_place(fromresource, text)
    print "ERROR: unimplemented send_message_to_place() called\n"
  end

  def on_enter(thing, from)
    print "ERROR: unimplemented on_enter() called\n"
  end

  def on_leave(thing, to)
    print "ERROR: unimplemented on_leave() called\n"
  end

  def command(source, command, arguments)
    command.each_element { |action|
      text = action.text.nil? ? "" : action.text.dup
      text.gsub!('%self%', iname)
      text.gsub!('%actor%', source.iname)
      text.gsub!('%place%', place)
      if action.name == 'say' || action.name == 'tell'
        sender = nil
        sender = iname if action.name == 'say'
        if action.attributes['to'] == 'all'
          print "send_message_to_place(#{sender}, #{text})\n"
        else
          source.send_message(sender, text)
        end
      end
    }
  end
end
