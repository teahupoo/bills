require 'sinatra'
require 'data_mapper'
require 'time'
require 'sinatra/flash'
require 'sinatra/redirect_with_flash'

SITE_TITLE = "Dollar Bills"
SITE_DESCRIPTION = "'...one day you WILL own a luxury, personal submarine'"


enable :sessions

DataMapper::setup :default, {
  :adapter  => 'postgres',
  :host     => 'localhost',
  :database => 'recall'
}

class Note
	include DataMapper::Resource
	property :id, Serial
	property :content, Text, :required => true
	property :complete, Boolean, :required => true, :default => 0
	property :created_at, DateTime
	property :updated_at, DateTime
end

configure do
  enable :logging, :dump_errors, :raise_errors
end

log = File.new("sinatra.log", "a")
STDOUT.reopen(log)
STDERR.reopen(log)


DataMapper.auto_upgrade!

helpers do
	include Rack::Utils
	alias_method :h, :escape_html
end


# 
# Application
#

get '/' do
	@notes = Note.all :order => :id.desc
	@title = 'All Notes'
	if @notes.empty?
		flash[:error] = 'No bills found. Add your first below.'
	end 
	erb :home
end

post '/' do
	n = Note.new
	n.attributes = {
		:content => params[:content],
		:created_at => Time.now,
		:updated_at => Time.now
	}
	if n.save
		redirect '/', :notice => 'Bill created successfully.'
	else
		redirect '/', :error => 'Failed to save bill.'
	end
end

get '/rss.xml' do
	@notes = Note.all :order => :id.desc
	builder :rss
end

get '/:id' do
	@note = Note.get params[:id]
	@title = "Edit note ##{params[:id]}"
	if @note
		erb :edit
	else
		redirect '/', :error => "Can't find that bill."
	end
end

put '/:id' do
	n = Note.get params[:id]
	unless n
		redirect '/', :error => "Can't find that bill."
	end
	n.attributes = {
		:content => params[:content],
		:complete => params[:complete] ? 1 : 0,
		:updated_at => Time.now
	}
	if n.save
		redirect '/', :notice => 'Bill updated successfully.'
	else
		redirect '/', :error => 'Error updating bill.'
	end
end

get '/:id/delete' do
	@note = Note.get params[:id]
	@title = "Confirm deletion of bill ##{params[:id]}"
	if @note
		erb :delete
	else
		redirect '/', :error => "Can't find that bill."
	end
end

delete '/:id' do
	n = Note.get params[:id]
	if n.destroy
		redirect '/', :notice => 'Bill deleted successfully.'
	else
		redirect '/', :error => 'Error deleting bill.'
	end
end

get '/:id/complete' do
	n = Note.get params[:id]
	unless n
		redirect '/', :error => "Can't find that bill."
	end
	n.attributes = {
		:complete => n.complete ? 0 : 1, # flip it
		:updated_at => Time.now
	}
	if n.save
		redirect '/', :notice => 'Bill marked as complete.'
	else
		redirect '/', :error => 'Error marking bill as complete.'
	end
end
