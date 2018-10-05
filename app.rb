require 'sinatra'
require "sinatra/reloader" if development?
require "time"
require "date"
require "twilio-ruby"
require "giphy"
require "httparty"

#app settings 
enable :sessions 
#samples
greetingsMorning  = ["Good Morning", "Hey there"]
greetingsAfternoon = ["Good Afternoon"]
greetings = ["Hey", "How are you?"]

configure :development do
    require 'dotenv'
    Dotenv.load
  end

time = Time.now

#secret
secret = "HarryPotter"

#read file
fileJoke = File.open("joke.txt", "r")
fileFacts = File.open("facts.txt", "r")




get '/' do
  "This is Sisi!!! woohoo the app is live"

end



get '/about' do
    session[:visits] ||= 0 
    session[:visits] += 1
    
    if session[:name].nil? 
        session[:name] = ""
        greetings.sample
    elsif time.hour > 12 
        greetingsAfternoon.sample + " " + session[:name] + " " + ",your total visits " + session[:visits].to_s + " times as of " + time.strftime("%A %B %d, %Y %H:%M")
    else 
        greetingsMorning.sample + " " + session[:name] + " " + ",your total visits " + session[:visits].to_s + " times as of " + time.strftime("%A %B %d, %Y %H:%M")
    end
end


get '/signup' do
    if params[:code]== secret 
       return erb :signup
    else 
        error 403 do 
            "Access Issue"
            end 
    end 
end

post '/signup' do 
    # code to check parameters 
    session[:name] = params[:name]
    session[:number]= params[:number]
    if  params[:name].nil? && params[:number].nil?
        "Fill in all information please"
    elsif !params[:code].nil? && params[:code]== secret 
        client = Twilio::REST::Client.new ENV["TWILIO_ACCOUNT_SID"], ENV["TWILIO_AUTH_TOKEN"]

        # message 
        message = "What's up " + params[:first_name] + ", I'm Dev Bot, I can search up your friends contacts and make food suggestions.
        If you are stuck, type help"

        # this will send message from any end point
        client.api.account.messages.create(
            from: ENV["TWILIO_FROM"],
            to: params[:number],
            body: message
        )
        # response if everything is OK 
            "You are signed up and you will receive a text in a few minutes from the bot"
    end
end 


get '/hello/:name' do
    session[:name] = params[:name] 
    "Hi there," +' '+ params[:name]
end

get '/sms/incoming' do

    
    count = session["counter"] || 1
    body = params[:Body] || "" 
    message = determine_response params[:Body]
    media = nil
    #     #Twilio response object
    twiml = Twilio::TwiML::MessagingResponse.new do |r|
        r.message do |m|
               
            m.body(message)
                #add media if it is defined
            unless media.nil? 
                m.media(media)
            end 
        end 
    end 

        # increment the session number
    count += 1 
        # send a response to twilio
    content_type 'text/xml'
    twiml.to_s
    
end

def cmuSearch (body)

    andrew_id = body.to_s

    dir_response = HTTParty.get('https://apis.scottylabs.org/directory/v1/andrewID/' + andrew_id )
    
    if dir_response.nil? or dir_response.empty?
        "Person not found"
      else
        first_name = dir_response["first_name"].to_s
        last_name = dir_response["last_name"].to_s
        andrew_id = dir_response["andrewID"].to_s
        contact = dir_response["preferred_email"].to_s
        department = dir_response["department"].join(", ").to_s

        "Your search for " + andrew_id + " returns " + first_name + ' ' + last_name + ", contact at " + ' ' + contact + " at the " +  department
      end
      
end 

# get '/sms/incoming' do
 
#     sender = params[:From] || ""
#     body = params[:Body] || ""
#     body = body.downcase.strip
#     media = nil


      
#     Giphy::Configuration.configure do |config|
#       config.api_key = ENV["GIPHY_API_KEY"]
#     end
    
#       message = determine_response body
      
#       if message.nil?
#           # if there's no match for a response
#       else 
#         results = Giphy.search( body, {limit: 3})
#         unless results.empty? 
#             media = results.first.fixed_width_downsampled.url
#             puts media
#               message = "Powered by Giphy.com and Twilio MMS: twilio.com/mms" 
#         else 
#           message = "Hmmm, that's odd. I couldn't find anything for '#{query}'. Try something else?"
#         end
      
#       end
      
#     twiml = Twilio::TwiML::MessagingResponse.new do |r|
#       r.message do |m|
#         m.body( message )
#         unless media.nil?
#           m.media( media  )
#         end
#       end 
#     end
    
#     content_type 'text/xml'
#     twiml.to_s
#   end
    
  
def yelpSearch(body)
  
    json = search_yelp( body , "15232")
    
    first_rest = json['businesses'][0]
    
    # str = "I'd recommend: "

    # for business in json['businesses']
    #         str += business['name'] + "( #{ business['price'] } ) is located at: " + business['location']['display_address'].join(", ") + " " + 'The rating is ' + business['rating'].to_s + "<Br>" 
    
       
    # end 
    
    message = "I'd recommend 🍋" + first_rest['name'] + "( #{ first_rest['price'] } ) is located at: " + first_rest['location']['display_address'].join(", ") + " " + 'The rating is ' + first_rest['rating'].to_s + " " + first_rest['image_url'].to_s
   
 

    
   end 
   
   
   def search_yelp(term, location)
     
     url = "https://api.yelp.com/v3/businesses/search"
     params = {
       term: term,
       location: location,
       limit: 5
     }
     
     response = HTTParty.get( url, query: params, headers: {"Authorization" => "Bearer " + ENV['YELP_API_KEY']}  )
   
     puts response
     
     JSON.parse( response.body.to_s )
   
   end


# if it has the word hi, do this 
#if body.include? hi or body.include? hello

 #Methods
 def determine_response (body)
     #lowercase and remove spacing 


     body = body.to_s.downcase.strip
     if body == "hi"
         "Hi, I'm Dev-Bot 😈 , what are you looking for? " + media = "https://media.giphy.com/media/5qFgBGXqb7AuUx7KRG/giphy.gif}"
     elsif body.include? "who"
         "I am Dev-Bot, what do you want to do today? 🍄"
     elsif body.include? "what"
         "I am Dev-Bot, I am here to push you out of your comfort zone. Ask me something 🐽 Fun fact, I can also look up 💁‍♀️ for you in your circle " + media = "https://media.giphy.com/media/xUPGcigl4eOfc6hA5y/giphy.gif"
     elsif body == "where"
         "Pittsburgh"
     elsif body == "when"
         def timecheck ()
             if Time.now.hour >16
                 "I'm available, please call me"
             else
                 "I'm in class, please text me"
             end 
         end 
         timecheck()
     elsif body == "why"
         "For a class project"
     elsif body == "Search contact"
         "Please type in their andrewId"
     elsif body.include? "joke"
         funnythings = ["haha", "lol" , "ba dum chhh"]
         array_of_lines = IO.readlines("joke.txt")
         array_of_lines.sample + ' ' +funnythings.sample
     elsif body =="facts"
         array_of_lines = IO.readlines("facts.txt")
         array_of_lines.sample
     elsif body.start_with? "find"

        directory_query = body.gsub!("find", "").strip

        if directory_query.split( " " ).length > 1
            "You can only search for people based on a Andrew ID. Don't include more than that i.e. 'find sisixiy'"
        else
            cmuSearch (directory_query)
        end 
    elsif body.include? "hungry"
        "I can make food option suggestions, please type in what you are feeling like 🍔 🥦 🍠 🥓 "
    elsif  body.include? "food" or body.include? "drinks" or body.include? "breakfast" or body.include? "dinner" or body.include? "lunch"
        yelpSearch(body)
    elsif body.include? "bored"
        "What would you like to do? Type in a category 🏄🏻‍♂️🧘‍♀️🤼‍♂️"
    elsif body.include? "active" or body.include? "calm" or body.include? "fun"
        yelpSearch(body)
    elsif body.include? "thanks"
        "No worries, always there to help with procrastinating 🍑"
     else 
        "I'm sorry, I don't quite understand that, try asking me something else"
        yelpCategory(cagtegory)
     end 
 end 


#  def handleKeywordMatching (body, keywords)
#     puts body.to_s
#     keywords.each do |keyword|
#         if body.include? keyword.to_s
#             return true
#         end 
#     end
#     return false
# end 





get '/test/conversation' do
    if !params[:Body].nil? and !params[:From].nil?
        determine_response params[:Body]
    else 
        return "input fields required"
    end 
end 
