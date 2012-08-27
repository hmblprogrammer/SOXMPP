SOXMPP
======

Stack Overflow XMPP Bridge


This is a project to allow users of the Stack Exchange chat system to send and receive messages to chat rooms using Jabber / XMPP clients. It is designed as an XMPP "component", meaning it hooks in to a running XMPP server.

It is written in Ruby and requires the following gems to run:

 * json
 * xmpp4r
 * tidy

To use the script, set up an XMPP server (Openfire is known to work) and allow external components. Then execute the script as follows:

    ./soxmpp.rb somedomain.yourdomain.com somePasswordYouSetInYourServer hostnameOfYourServer

Then, you can join rooms @somedomain.yourdomain.com, for example the_tavern@somedomain.yourdomain.com

For more information, see [the MSO post](http://meta.stackoverflow.com/questions/57316/offer-an-xmpp-method-for-chat/63420#63420).
