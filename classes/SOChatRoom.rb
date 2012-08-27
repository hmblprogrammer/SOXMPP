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
  
  def post_message(message, fkey, cookie)
    puts "DEBUG: post_message(message, fkey, cookie)"
    
    request = {
      'fkey' => fkey,
      'text' => message
    }
    
    headers = {
       'Cookie' => cookie
    }
    
    
    #url = URI.parse("http://#{@domain}/chats/#{@id}/messages/new")
    #req = Net::HTTP::Post.new(url.path)
    #req.headers = headers
    #req.set_form_data(request)
    #res = Net::HTTP.new(url.host, url.port).start {|http| http.request(req) }
    #case res
    #  when Net::HTTPSuccess, Net::HTTPRedirection
    #    puts "DEBUG: Successfully posted a message, response was: #{res.body}"
    #    res.body
    #  else
    #    puts "ERROR: Failed to post a message!"
    #    res.error!
    #end
    
    puts "DEBUG: posting to #{@domain} port 80"
    
    http = Net::HTTP.new(@domain, 80)
    
    data = "fkey=#{ERB::Util.url_encode(fkey)}&text=#{ERB::Util.url_encode(message)}"
    headers = {
      'Cookie' => cookie,
      'Content-Type' => 'application/x-www-form-urlencoded'
    }
    
    puts "DEBUG: postdata: #{data}"
    puts "DEBUG: cookie: #{cookie}"
    
    resp, data = http.post("/chats/#{@id}/messages/new", data, headers)
    
    puts "DEBUG: posted a message, response was: #{resp}, data was: #{data}"
    
    # Output on the screen -> we should get either a 302 redirect (after a successful login) or an error page
    #puts 'Code = ' + resp.code
    #puts 'Message = ' + resp.message
    #resp.each {|key, val| puts key + ' = ' + val}
    #puts data
    
    
  end
end
