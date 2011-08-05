require 'rubygems'
require 'sinatra'
require 'haml'
require 'data_mapper'
require 'dm-migrations'
require 'net/http'

# Set path to sqlite3 database file
set :public, File.dirname(__FILE__) + '/static'
DataMapper.setup(:default, ENV['DATABASE_URL'] || 'sqlite3://pasta.db')

class Paste
  include DataMapper::Resource

  property :id,         Serial
  property :title,      String
  property :body,       Text
  property :author,     String
  property :language,   String
  property :created_at, DateTime
end

Paste.auto_upgrade!

set :haml, :format => :html5

get '/' do
  @pastes = Paste.last(5)
  haml :index
end

get '/:id' do |id|
  @paste = Paste.get(Integer(id))
  haml :paste
end

post '/' do
  request = Net::HTTP.post_form(URI.parse('http://pygments.appspot.com/'),
                                {'lang'=>params[:language],
                                 'code'=>params[:body]}
                               )

  title    = params[:title].empty?  ? 'Untitled' : params[:title]
  author   = params[:author].empty? ? 'Untitled' : params[:author]
  language = params[:language]

  new_paste = Paste.create(
                           :title      => title,
                           :author     => author,
                           :body       => request.body,
                           :language   => language,
                           :created_at => Time.now
                           )
  redirect "/#{new_paste[:id]}"
end
