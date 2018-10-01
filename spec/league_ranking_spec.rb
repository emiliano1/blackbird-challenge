require_relative '../league_ranking'

describe InputProcessor do
  let(:filename) { 'path/to/file.txt' }
  let(:line1) { 'Lions 3, Snakes 3' }
  let(:line2) { 'Tarantulas 1, FC Awesome 0' }
  let(:league_manager) { LeagueManager.new }
  let(:match_processor) { MatchProcessor.new(league_manager) }
  subject(:input_processor) { InputProcessor.new(match_processor, filename) }

  context 'when a file name is given' do
    it 'reads the file content' do
      expect(File).to receive(:open).with(filename, 'r')

      input_processor.process
    end

    it 'process the file content' do
      sample_file = instance_double(File)
      allow(sample_file).to receive(:each_line).and_yield(line1).and_yield(line2)

      allow(File).to receive(:open).and_yield(sample_file)

      expect(match_processor).to receive(:process).with(line1)
      expect(match_processor).to receive(:process).with(line2)

      input_processor.process
    end
  end

  context 'when a file name is not given' do
    subject(:input_processor) { InputProcessor.new(match_processor) }

    it 'process STDIN input' do
      allow($stdin).to receive(:gets).and_return(line1, line2, nil)

      expect(match_processor).to receive(:process).with(line1)
      expect(match_processor).to receive(:process).with(line2)

      input_processor.process
    end
  end
end

describe MatchProcessor do
  let(:raw_match_result) { 'Tarantulas 1, FC Awesome 0' }
  let(:match_result) { { team1: 'Tarantulas', score1: 1, team2: 'FC Awesome', score2: 0, winner: 1 } }
  let(:league_manager) { LeagueManager.new }
  subject(:match_processor) { MatchProcessor.new(league_manager) }

  it 'parses the result and send to LeagueManager' do
    expect(league_manager).to receive(:add_match_result).with(match_result)

    match_processor.process(raw_match_result)
  end
end

describe LeagueManager do
  let(:match_result1) { { team1: 'Lions', score1: 3, team2: 'Snakes', score2: 3, winner: 0 } }
  let(:match_result2) { { team1: 'Tarantulas', score1: 1, team2: 'FC Awesome', score2: 0, winner: 1 } }
  let(:match_result3) { { team1: 'Lions', score1: 1, team2: 'FC Awesome', score2: 1, winner: 0 } }
  let(:match_result4) { { team1: 'Tarantulas', score1: 3, team2: 'Snakes', score2: 1, winner: 1 } }
  let(:match_result5) { { team1: 'Lions', score1: 4, team2: 'Grouches', score2: 0, winner: 1 } }
  subject(:league_manager) { LeagueManager.new }

  context 'ranking' do
    before do
      league_manager.add_match_result(match_result1)
      league_manager.add_match_result(match_result2)
      league_manager.add_match_result(match_result3)
      league_manager.add_match_result(match_result4)
      league_manager.add_match_result(match_result5)
    end

    it 'calculates the ranking' do
      expect(league_manager.rank).to eq([
        { team: 'Tarantulas', points: 6, matches: 2 },
        { team: 'Lions', points: 5, matches: 3 },
        { team: 'FC Awesome', points: 1, matches: 2 },
        { team: 'Snakes', points: 1, matches: 2 },
        { team: 'Grouches', points: 0, matches: 1 },
      ])
    end

    it 'prints the ranking' do
      [
        '1. Tarantulas, 6 pts',
        '2. Lions, 5 pts',
        '3. FC Awesome, 1 pt',
        '3. Snakes, 1 pt',
        '5. Grouches, 0 pts',
      ].each do |output|
        expect($stdout).to receive(:puts).with(output)
      end

      league_manager.print_rank
    end
  end

end
