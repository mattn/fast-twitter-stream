require 'rubygems'
require 'sinatra'
require 'json'  
require 'tweetstream'  
require 'pit'

# doesn't work on thin and webrick
set :server, 'mongrel'
set :public, File.dirname(__FILE__) + '/static'

get '/' do
  <<HTML
  <html>
  <head>
    <title>Server Push</title>
    <style type="text/css">
    #content { font-family: monospace }
    .tweets { background-color: #eee }
    </style>
    <script src="http://ajax.googleapis.com/ajax/libs/jquery/1.3.1/jquery.min.js"></script>
    <script type="text/javascript" src="/js/DUI.js"></script>
    <script type="text/javascript" src="/js/Stream.js"></script>
    <script type="text/javascript">
    $(function() {
      var s = new DUI.Stream();
      s.listen('text/javascript', function(payload) {
        var status = eval(payload);
        $('<div/>')
          .attr('class', 'tweets')
          .css('display', 'none')
          .append($('<a/>').attr('href', '#' + status.id))
          .append($('<b/>').text(status.user.screen_name))
          .append($('<p/>').text(status.text))
          .appendTo('#content').show('fast');
        location.href = '#' + status.id;
      });
      s.load('/push');
    });
    </script>
  </head>
  <body>
    <h1>Server Push</h1>
    <div id="content"></div>
  </body>
</html>
HTML
end

get '/push' do
  boundary = '|||'
  response['Content-Type'] = 'multipart/mixed; boundary="' + boundary + '"'

  MultipartResponse.new(boundary, 'text/javascript')
end

class MultipartResponse
  def initialize(boundary, content_type)
    @boundary = boundary
    @content_type = content_type
    @config = Pit.get("twitter.com", :require => {
      "username" => "your username in twitter",
      "password" => "your password in twitter"
    })

  end

  def each
    TweetStream::Client.new(@config['username'], @config['password']).sample do |status|  
      yield "--#{@boundary}\nContent-Type: #{@content_type}\n(#{status.to_json})"
    end  
  end
end
