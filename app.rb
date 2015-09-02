require 'bundler/setup'
require 'sinatra'
require 'multi_json'
require 'redis'

$redis = Redis.new

post '/activity' do
  json = MultiJson.load(request.body.read, symbolize_keys: true)

  project_id        = json[:project][:id]
  project_name      = json[:project][:name]
  username          = json[:performed_by][:name]
  highlight         = json[:highlight].tr(':', '')
  primary_resource  = json[:primary_resources][0]
  story_type        = primary_resource[:story_type]
  story_name        = primary_resource[:name]
  url               = primary_resource[:url]

  message = case json[:kind]
            when 'story_create_activity'
              "#{username} #{highlight} new #{story_type} \"#{story_name}\". See: #{url}"
            when 'story_update_activity'
              return if highlight == 'estimated'
              "#{username} #{highlight} #{story_type} \"#{story_name}\". See: #{url}"
            when 'comment_create_activity'
              "#{username} #{highlight} to the #{story_type} \"#{story_name}\". See: #{url}"
            end

  $redis.publish("activity/#{project_id}_#{project_name}", message)
end