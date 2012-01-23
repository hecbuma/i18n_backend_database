require 'cgi'
require 'net/http'
require 'json'

class GoogleLanguage

  # Thanks http://ruby.geraldbauer.ca/google-translation-api.html
  def self.translate( text, to, from='en' )
    base = 'https://www.googleapis.com/language/translate/v2'

    # assemble query params
    params = {
      :source => "#{from}",
      :target => "#{to}",
      :q => text,
      :key => # add your google app key
    }

    query = params.map{ |k,v| "#{k}=#{CGI.escape(v.to_s)}" }.join('&')

    # send get request
    # response = Net::HTTP.get_response( URI.parse( "#{base}?#{query}" ) )
    puts "URI >> #{URI.parse( "#{base}?#{query}")}"
    response = JSON.parse(open(URI.parse( "#{base}?#{query}" )).read)

    response['data']['translations'].first['translatedText']

  end

end
