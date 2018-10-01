class InputProcessor
  def initialize(match_processor, filename=nil)
    @match_processor = match_processor
    @filename = filename
  end

  def process
    if @filename
      File.open(@filename, 'r') do |f|
        f.each_line do |line|
          @match_processor.process(line)
        end
      end
    else
      loop do
        match = $stdin.gets
        break unless match

        @match_processor.process(match)
      end
    end
  end
end

class MatchProcessor
  def initialize(league_manager)
    @league_manager = league_manager
  end

  def process(match_result)
    @league_manager.add_match_result(parse_result(match_result))
  end

  private

  def parse_result(match_result)
    match_data = match_regex.match(match_result).named_captures

    team1, score1 = match_data['team1'], match_data['score1'].to_i
    team2, score2 = match_data['team2'], match_data['score2'].to_i

    { team1: team1, score1: score1, team2: team2, score2: score2, winner: find_winner(score1, score2) }
  end

  def match_regex
    /(?<team1>.*?)\ (?<score1>\d+)\,\ (?<team2>.*?)\ (?<score2>\d+)/
  end

  # 0 -> tie
  # 1 -> team1 won
  # 2 -> team2 won
  def find_winner(score1, score2)
    return 0 if score1 == score2

    score1 > score2 ? 1 : 2
  end
end

class LeagueManager
  def initialize
    @match_history = []

    @matches = Hash.new(0)
    @points = Hash.new(0)
  end

  def add_match_result(match_result)
    @match_history << match_result

    team1 = match_result[:team1]
    team2 = match_result[:team2]

    @matches[team1] += 1
    @matches[team2] += 1

    if match_result[:winner].zero?
      @points[team1] += 1
      @points[team2] += 1
    elsif match_result[:winner] == 1
      @points[team1] += 3
      @points[team2] += 0
    elsif match_result[:winner] == 2
      @points[team1] += 0
      @points[team2] += 3
    end
  end

  def rank
    @points.sort_by do |key, value|
      [-value, key]
    end.map do |key, value|
      { team: key, points: value, matches: @matches[key] }
    end
  end

  def print_rank
    previous_pos = 1
    previous_points = nil

    rank.each_with_index do |result, i|
      points = result[:points]

      pos = points == previous_points ? previous_pos : i + 1
      previous_pos = pos
      previous_points = points

      points_text = points == 1 ? 'pt' : 'pts'
      puts "#{pos}. #{result[:team]}, #{points} #{points_text}"
    end
  end
end


if $0 == __FILE__
  league_manager = LeagueManager.new
  match_processor = MatchProcessor.new(league_manager)

  input_processor = InputProcessor.new(match_processor, ARGV[0])
  input_processor.process

  league_manager.print_rank
end
