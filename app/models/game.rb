class Game < ApplicationRecord
  has_many :moves, dependent: :destroy
  has_many :chat_messages, dependent: :destroy
  belongs_to :ai_player, optional: true, dependent: :destroy

  include NotationLogic
  include FenNotationLogic
  include BoardLogic
  include AiLogic
  include PieceHelper
  include CacheLogic

  scope :winning_games, ->(win) { where(outcome: win) }
  scope :user_games, ->(user_id) { where(white_player: user_id).or(where(black_player: user_id))}

  scope :find_open_games, (lambda do |user_id|
    where.not(white_player: user_id)
         .or(where.not(black_player: user_id))
         .where(status: 'awaiting player')
  end)

  class << self
    def create_user_game(user, game_params)
      game = Game.new(game_type: game_params[:game_type])
      game_params[:color] == 'white' ? game.white_player = user.id : game.black_player = user.id

      if game_params[:game_type] == 'human vs machine'
        machine_player = create_ai_player(game_params[:color])
        game.ai_player = machine_player
        game.status = 'active'
      else
        game.status = 'awaiting player'
      end
      game.save
      game.ai_move if game.ai_turn?
      game
    end

    def create_ai_player(color)
      if color == 'white'
        ai_color = 'black'
      else
        ai_color = 'white'
      end
      AiPlayer.create(color: ai_color, name: Faker::Name.name)
    end

    def pieces_with_next_move(game_pieces, move)
      castle = false
      en_passant = false
      piece_index = move.to_i
      updated_pieces = game_pieces.reject { |piece| piece.position == move[-2..-1] }
        .map do |piece|
          game_piece = Piece.new(
            color: piece.color,
            piece_type: piece.piece_type,
            position_index: piece.position_index,
            game_id: piece.game_id,
            position: piece.position,
            has_moved: piece.has_moved
          )

          if piece.position_index == piece_index
            game_piece.moved_two = game_piece.piece_type == 'pawn' && game_piece.forward_two?(move[-2..-1])
            castle = game_piece.king_moved_two?(move[-2..-1])
            en_passant = en_passant?(piece, move[-2..-1], game_pieces)
            game_piece.piece_type = 'queen' if should_promote_pawn?(move)
            game_piece.position = move[-2..-1]
            game_piece.has_moved = true
          end

          game_piece
        end

      updated_pieces = update_rook(move, updated_pieces) if castle
      updated_pieces = handle_en_passant(move, updated_pieces) if en_passant
      updated_pieces
    end

    def en_passant?(piece, position, game_pieces)
      [
        piece.piece_type == 'pawn',
        piece.position[0] != position[0],
        game_pieces.detect { |p| p.position == position }.blank?
      ].all?
    end

    def should_promote_pawn?(move_value)
      (9..24).include?(move_value.to_i) &&
        (move_value[-1] == '8' || move_value[-1] == '1')
    end

    def update_rook(king_move, game_pieces)
      new_rook_column = king_move[-2] == 'g' ? 'f' : 'd'
      new_rook_row = king_move[-1] == '1' ? '1' : '8'

      new_rook_position = new_rook_column + new_rook_row

      rook_index = case new_rook_position
      when 'd8' then 1
      when 'f8' then 8
      when 'd1' then 25
      when 'f1' then 32
      end

      game_pieces.map do |game_piece|
        if game_piece.position_index == rook_index
          game_piece.position = new_rook_position
        end
        game_piece
      end
    end

    def handle_en_passant(pawn_move_value, updated_pieces)
      captured_row = pawn_move_value[-1] == '6' ? '5' : '3'
      updated_pieces.reject do |game_piece|
        game_piece.position == pawn_move_value[-2] + captured_row
      end
    end
  end

  def move(position_index, new_position, upgraded_type = '')
    update_notation(position_index, new_position, upgraded_type)
    update_game(position_index, new_position, upgraded_type)
    handle_human_game if game_type.include?('human')
    return handle_outcome if game_over?(pieces, current_turn)
    ai_move if ai_turn?
  end

  def handle_human_game
    GameEventBroadcastJob.perform_later(self)
    reload_pieces
  end

  def handle_move(move_value, upgraded_type = '')
    position_index = move_value.to_i
    new_position = move_value[-2..-1]
    update_notation(move_value.to_i, new_position, upgraded_type)
    update_game(position_index, new_position, upgraded_type)
    handle_human_game if game_type.include?('human')
    return handle_outcome if game_over?(pieces, current_turn)
  end

  def game_over?(pieces, game_turn)
    checkmate?(pieces, game_turn) || stalemate?(pieces, game_turn)
  end

  def handle_outcome
    if checkmate?(pieces, current_turn)
      outcome = current_turn == 'black' ? 1 : -1
    else
      outcome = 0
    end
    update(outcome: outcome)
    GameEventBroadcastJob.perform_later(self) if game_type.include?('human')
    propogate_results if game_type == 'machine vs machine' && outcome != 0
  end

  def join_user_to_game(user_id)
    if white_player.blank?
      update(white_player: user_id, status: 'active')
    else
      update(black_player: user_id, status: 'active')
    end
    GameEventBroadcastJob.perform_later(self)
  end

  def ai_turn?
    ai_player.present? && current_turn == ai_player.color
  end

  def current_turn
    moves.count.even? ? 'white' : 'black'
  end

  def opponent_color
    current_turn == 'white' ? 'black' : 'white'
  end

  def machine_vs_machine
    until outcome.present? do
      ai_move
      update(outcome: 0) if moves.count > 400
      puts moves.order(:move_count).last.value
      puts '******************'
    end
  end

  def propogate_results
    moves.each do |move|
      setup = move.setup
      setup.update_outcomes(outcome)
      setup.signatures.each do |signature|
        signature.update(rank: signature.rank + outcome)
      end
    end
  end
end
