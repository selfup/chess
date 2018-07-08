require 'rails_helper'

RSpec.describe AiLogic, type: :module do
  before do
    allow_any_instance_of(Game).to receive(:ai_turn?).and_return(false)
  end

  describe 'ai_move' do
    xit 'test' do
    end
  end

  describe 'find_next_moves' do
    it 'returns all the next moves for a color' do
      game = Game.create

      values = [
        "31f3", "31h3", "26a3", "26c3", "24h3", "24h4", "23g3", "23g4", "22f3",
        "22f4", "21e3", "21e4", "20d3", "20d4", "19c3", "19c4", "18b3", "18b4",
        "17a3", "17a4"
      ]

      actual = game.find_next_moves.pluck(:value).all? { |value| values.include?(value) }

      expect(actual).to be true
    end
  end

  describe 'all_next_moves_for_piece' do
    xit 'test' do
    end
  end

  describe 'setup_analysis' do
    xit 'test' do
    end
  end

  describe 'best_rank_setup' do
    it 'test' do
    end
  end

  describe 'winning_setups' do
    xit 'test' do
    end
  end

  describe 'piece_analysis' do
    xit 'test' do
    end
  end

  describe 'handle_ratio' do
    it 'calls double_position_match and single_position_match' do
      expect_any_instance_of(Game).to receive(:find_matching_moves)
        .with('1a4')
        .and_return([])
      expect_any_instance_of(Game).to receive(:find_double_matching_moves)
        .with([], '2b4')
        .and_return([])

      game = Game.new

      game.handle_ratio('1a4', '2b4')
    end

    context 'when the match amount is 0' do
      it 'returns 0' do
        setup = Setup.new
        allow_any_instance_of(Game).to receive(:find_matching_moves)
          .with('1a4')
          .and_return([setup])
        allow_any_instance_of(Game).to receive(:find_double_matching_moves)
          .with([setup], '2b4')
          .and_return([])

        game = Game.new

        expect(game.handle_ratio('1a4', '2b4')).to eq 0
      end
    end

    context 'when the total is 0' do
      it 'returns 0' do
        allow_any_instance_of(Game).to receive(:find_matching_moves)
          .with('1a4')
          .and_return([])
        allow_any_instance_of(Game).to receive(:find_double_matching_moves)
          .with([], '2b4')
          .and_return([Setup.new])

        game = Game.new

        expect(game.handle_ratio('1a4', '2b4')).to eq 0
      end
    end

    context 'when neither the match nor the total is 0' do
      it 'returns the ratio' do
        setup = Setup.new
        allow_any_instance_of(Game).to receive(:find_matching_moves)
          .with('1a4')
          .and_return([setup, setup])
        allow_any_instance_of(Game).to receive(:find_double_matching_moves)
          .with([setup, setup], '2b4')
          .and_return([setup])

        game = Game.new

        expect(game.handle_ratio('1a4', '2b4')).to eq 0.5
      end
    end
  end

  describe 'find_matching_moves' do
    # Move.where(value: value).joins(:setup).where(winning_moves, 0)
    xit 'test' do

    end
  end

  describe 'find_double_matching_moves' do
    # moves.joins(:setup).where(winning_moves, 0)
    #      .where('position_signature LIKE ?', "%#{index_two}%")
    xit 'test' do
    end
  end

  describe 'current_turn' do
    context 'when there are an even number of moves on a game' do
      it 'returns white' do
        game = Game.new

        expect(game.current_turn).to eq 'white'
      end
    end

    context 'when there are an odd number of moves on a game' do
      it 'returns black' do
        game = Game.create
        move = game.moves.create

          expect(game.current_turn).to eq 'black'
      end
    end
  end

  describe 'opponent_color' do
    context 'when it is white\'s turn' do
      it 'returns black' do
        allow_any_instance_of(Game).to receive(:current_turn).and_return('white')
        game = Game.new

        expect(game.opponent_color).to eq 'black'
      end
    end

    context 'when it is black\'s turn' do
      it 'returns white' do
        allow_any_instance_of(Game).to receive(:current_turn).and_return('black')
        game = Game.new

        expect(game.opponent_color).to eq 'white'
      end
    end
  end

  describe 'find_checkmate' do
    xit 'test' do
    end
  end

  describe 'position_index_from_move' do
    xit 'test' do
    end
  end

  describe 'crossed_pawn?' do
    xit 'test' do
    end
  end

  describe 'promote_pawn' do
    xit 'test' do
    end
  end

  describe 'wins_from_notation' do
    xit 'test' do
    end
  end

  describe 'random_winning_game' do
    xit 'test' do
    end
  end

  describe 'best_move_from_notation' do
    xit 'test' do
    end
  end

  describe 'start_index' do
    xit 'test' do
    end
  end

  describe 'material_analysis' do
    context 'when a pawn is captured' do
      it 'returns the material difference between the current state and the next move' do
        game = Game.create

        game.find_piece_by_index(20).position = 'd4'
        game.find_piece_by_index(11).position = 'c5'

        expect(game.material_analysis('20c5')).to eq 1
        expect(game.material_analysis('20d5')).to eq 0
      end
    end

    context 'when a queen is captured' do
      it 'returns the material difference between the current state and the next move' do
        game = Game.create

        game.pieces.reject! { |piece| piece.position_index == 20 }
        game.move(28, 'd4')
        game.find_piece_by_index(11).position = 'c5'

        expect(game.material_analysis('11d4')).to eq 9
      end
    end
  end

  describe 'find_material_value' do
    it 'returns the sum of a color\'s material value' do
      game = Game.new

      pieces = [
        Piece.new(piece_type: 'queen', color: 'white'),
        Piece.new(piece_type: 'pawn', color: 'white'),
        Piece.new(piece_type: 'rook', color: 'black'),
        Piece.new(piece_type: 'bishop', color: 'black')
      ]

      expect(game.find_material_value(pieces, 'white')).to eq 10
      expect(game.find_material_value(pieces, 'black')).to eq 8
    end
  end

  describe 'weight_analysis' do
    it 'returns the sum of all ratios' do
      allow_any_instance_of(Game).to receive(:handle_ratio)
        .and_return(0.5)
      game = Game.new

      signature = ['1d4', '8c6', '28a6']
      possible_move_value = '4a7'

      expect(game.weight_analysis(signature, possible_move_value)).to eq 1.5
    end
  end
end
