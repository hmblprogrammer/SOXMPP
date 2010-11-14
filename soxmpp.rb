#!/usr/bin/ruby
#  
#   ____   _____  ____  __ ____  ____  
#  / ___| / _ \ \/ /  \/  |  _ \|  _ \ 
#  \___ \| | | \  /| |\/| | |_) | |_) |
#   ___) | |_| /  \| |  | |  __/|  __/ 
#  |____/ \___/_/\_\_|  |_|_|   |_|    
#                                      
#  
#                    ____       _     _            
#                   | __ ) _ __(_) __| | __ _  ___ 
#                   |  _ \| '__| |/ _` |/ _` |/ _ \
#                   | |_) | |  | | (_| | (_| |  __/
#                   |____/|_|  |_|\__,_|\__, |\___|
#                                       |___/      
#                   
#
#
# @author Joshua Gitlin <josh -at- digitalfruition -dot- com>
# @requires xmpp4r <http://home.gna.org/xmpp4r/>
# @see http://trac.digitalfruition.com/soxmpp/
# @see http://chat.meta.stackoverflow.com/rooms/241/xmpp
# @see http://meta.stackoverflow.com/questions/57316/offer-an-xmpp-method-for-chat
# 
# This project aims to build an open source method of accessing the Stack 
# Overflow chat system via XMPP/Jabber/Google Messaging.
# 
# This script is a very, very, very early alpha. It is by no means complete.
# Please see the Trac wiki for more information about current progress.
# 
# Currently thete is *no* write support, users don't work, there's a lot of bugs
# and only two rooms work (because they're hard-coded in): The tavern and XMPP
# on chat.meta.stackoverflow.com
# 
# To use this script, you'll need access to an XMPP server on which you can
# create components. For a great, free open source XMPP server, check out
# Ignite Realtime's Openfire: http://www.igniterealtime.org/projects/openfire/
#
# Please note, this project/site is in no way endorsed or maintained by Stack
# Overflow Inc, or by the XMPP Standards Foundation. The logos associated with
# Stack Overflow Inc. and any Stack Exchange site are a trademark and are 
# copyrighted. The XMPP logo is released under an MIT license.

require 'rubygems'
require 'erb'
require 'json'
require 'net/http'
require 'uri'
require 'cgi'
require 'tidy'
require 'xmpp4r'
require 'xmpp4r/discovery'
require 'xmpp4r/muc/x/muc'

require 'classes/SOChatEvents.rb'
require 'classes/SOChatEventCollection.rb'
require 'classes/SOChatFeed.rb'
require 'classes/SOChatUser.rb'
require 'classes/SOChatRoom.rb'
require 'classes/SOXMPP_Object.rb'
require 'classes/SOXMPP_ChatUser.rb'
require 'classes/SOXMPP_LoggedInUser.rb'
require 'classes/SOXMPP_Room.rb'
require 'classes/SOXMPP_Bridge.rb'

$:.unshift '../../lib'



#Jabber::debug = true


# Parse our arguments:

if ARGV.size != 3
  puts "Syntax: #{ARGV[0]} <JID> <Password> <Host>"
  puts "See README for further help"
  exit
end

# Create the XMPP bridge:
bridge = SOChat_XMPP_Bridge.new(Jabber::JID.new(ARGV[0]),ARGV[1], ARGV[2])

# Add some rooms:
bridge.add_room('xmpp','chat.meta.stackoverflow.com',241);
bridge.add_room('the_tavern','chat.meta.stackoverflow.com',89);

# And awwwwway we go!
Thread.stop
