class ChatMessageCreationEventBroadcastJob < ApplicationJob
  queue_as :default

  def perform(chat_message)
    ActionCable
      .server
      .broadcast(
        "chat_#{chat_message.game_id}",
        ChatMessageSerializer.serialize(chat_message)
      )
  end
end
