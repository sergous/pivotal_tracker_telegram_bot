require_relative 'main'

bot_name = 'Pivotal Tracker Bot'.freeze
bot_help = <<-HELP
  Initially, the need to integrate the bot with pivotal tracker.
  See: https://github.com/mgrachev/pivotal_tracker_telegram_bot

  Support: support@mgrachev.com

  Available commands:

  /start  - Start a #{bot_name}
  /track  - Tracking project
  /stop   - Stop tracking project
  /help   - Show hint
HELP

track_argument_error = "You must specify the project ID and Project Name.\n Example: /track 1234 Ruby"

begin
  $telegram_bot.run do |bot|
    bot.listen do |message|
      case message.text
        when '/start'
          bot.api.sendMessage(chat_id: message.chat.id, text: "Hello! I'm #{bot_name}")
        # TODO: Disable tracking multiple projects
        when /^\/track/
          args = message.text.split(' ')

          if args.length < 3
            bot.api.sendMessage(chat_id: message.chat.id, text: track_argument_error)
            next
          end

          project_id, project_name = args[1..-1]
          $redis.set("pivotal_tracker_bot/chat_id/#{project_id}_#{project_name}", message.chat.id)
          # To stop tracking
          $redis.set("pivotal_tracker_bot/project_key/#{message.chat.id}", "#{project_id}_#{project_name}")

          bot.api.sendMessage(chat_id: message.chat.id, text: "Start tracking project #{project_name}")
        when '/stop'
          redis_key = "pivotal_tracker_bot/project_key/#{message.chat.id}"

          unless $redis.exists(redis_key)
            bot.api.sendMessage(chat_id: message.chat.id, text: 'No track projects')
            next
          end

          project_key   = $redis.get(redis_key)
          project_name  = project_key.split('_')[1]

          $redis.del("pivotal_tracker_bot/chat_id/#{project_key}")
          $redis.del("pivotal_tracker_bot/project_key/#{message.chat.id}")

          bot.api.sendMessage(chat_id: message.chat.id, text: "Stop tracking project #{project_name}")
        when '/help'
          bot.api.sendMessage(chat_id: message.chat.id, text: bot_help)
      end
    end
  end
rescue => error
  $bot_logger.fatal(error)
end



