require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'

configure do
  enable :sessions
  set :session_secret, 'secret_session_id'

  # use Rack::Session::Cookie, :key => 'rack.session',
  #                            :path => '/',
  #                            :secret => 'secret session id'
end

ROOT = File.expand_path("..", __FILE__) + "/data/"

get "/" do
  @files = Dir.glob("#{ROOT}*")
              .map { |path| File.basename(path) }

  erb :index, layout: :layout
end

get "/:filename" do
  path = ROOT + params[:filename]

  if File.exist?(path)
    session[:success] = "File found"

    headers["Content-Type"] = "text/plain"
    File.read(path)
  else
    session[:message] = "#{params[:filename]} does not exist."
    redirect "/"
  end
end
