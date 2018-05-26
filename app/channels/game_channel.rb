class GameChannel < ApplicationCable::Channel
  def subscribed
    stream_from "game_#{params[:game_id]}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def update(opts)
    game = Game.find(opts['game_id'])
    game.move(opts['position_index'], opts['new_position'], opts['upgraded_type'])
  end
end
