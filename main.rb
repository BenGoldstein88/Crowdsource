require "elo"

$NUM_TEAMS = 10
$NUM_RIDDLES = 1

$DEFAULT_ELO = 1000
$RIDDLES = []
$SUBMISSIONS = []
$MATCHUPS = []

$BATCHES_GENERATED = 0


# TEMP: generates riddles
def generate_riddles(num_riddles = $NUM_RIDDLES)
    return Array.new(num_riddles) { |e| e = {id: "#{e}"} }
end

# TEMP: generates submissions
def generate_submissions(num_teams = $NUM_TEAMS, num_riddles = $NUM_RIDDLES)
    team_submissions = []
    for i in 0..num_teams-1
        for j in 0..num_riddles-1
            team_submissions.push(Array.new(num_riddles) { |e| e =  {id: "#{i}#{j}", team_id: "#{i}", riddle_id: "#{j}", elo_rating: $DEFAULT_ELO} })
        end
    end

    return team_submissions.flatten
end

# generates matchups totally randomly
def generate_matchups(submissions, riddle_id = "0")
    submissions_by_category = submissions.select { |submission| submission[:riddle_id] == riddle_id }

    puts "submissions_by_category: #{submissions_by_category.count}"

    # TODO: handle when odd-number of submissions
    matchups = submissions_by_category.shuffle.each_slice(2).map { |pairing| {
        id: "#{pairing[0][:id]}#{pairing[1][:id]}#{$BATCHES_GENERATED}",
        submission_id_a: pairing[0][:id],
        submission_id_b: pairing[1][:id],
        team_id_a: pairing[0][:team_id],
        team_id_b: pairing[1][:team_id],
        completed: false,
        assigned: false,
        riddle_id: pairing[0][:riddle_id],
        winning_submission_id: nil
    } }
    $BATCHES_GENERATED = $BATCHES_GENERATED+1
    return matchups
end

def generate_more_matchups(submissions = $SUBMISSIONS, riddle_id = "0")
    submissions_by_category = $SUBMISSIONS.select { |submission| submission[:riddle_id] == riddle_id }
    more_matchups = submissions_by_category.shuffle.each_slice(2).map { |pairing| {
        id: "#{pairing[0][:id]}#{pairing[1][:id]}#{$BATCHES_GENERATED}",
        submission_id_a: pairing[0][:id],
        submission_id_b: pairing[1][:id],
        team_id_a: pairing[0][:team_id],
        team_id_b: pairing[1][:team_id],
        completed: false,
        assigned: false,
        riddle_id: pairing[0][:riddle_id],
        winning_submission_id: nil
    } }
    $BATCHES_GENERATED = $BATCHES_GENERATED+1
    $MATCHUPS.concat(more_matchups)
    puts "GENERATING MOR MATCHUPS"
end

# scores a matchup with winner and loser
def score_matchup(matchup_id, winning_submission_id, losing_submission_id)
    # TODO: ensure we're filtering by category or whatever
    matchup = $MATCHUPS.find{|matchup| matchup[:id] == matchup_id}
    matchup[:completed] = true
    matchup[:winning_submission_id] = winning_submission_id

    winning_submission = $SUBMISSIONS.find{|s| s[:id] == winning_submission_id }
    losing_submission = $SUBMISSIONS.find{|s| s[:id] == losing_submission_id }

    winning_sub_elo  = Elo::Player.new(:rating => winning_submission[:elo_rating])
    losing_sub_elo = Elo::Player.new(:rating => losing_submission[:elo_rating])
  
    winning_sub_elo.wins_from(losing_sub_elo)

    winning_submission[:elo_rating] = winning_sub_elo.rating
    losing_submission[:elo_rating] = losing_sub_elo.rating

    # $SUBMISSIONS.map{|s| s[:id] == winning_submission_id ? winning_submission : s[:id] == losing_submission_id ? losing_submission : s }

    # $MATCHUPS.map{|m| m[:id] == matchup_id ? matchup : m }
    incomplete_matches = $MATCHUPS.select{|m| m[:completed] == false && m[:assigned] == false}

    if(incomplete_matches.count() < $NUM_TEAMS) 
        generate_more_matchups()
    end
end


# matchup = {
#     id
#     team_id_a => 1,
#     team_id_b => 2,
#     submission_id_a => 1,
#     submission_id_b => 2,
#     completed => false,
#     assigned => false
# }

# submission = {
#     id => 1,
#     riddle_id => 1,
#     elo_rating => 1000,
#     # numMatchups, (computed attr?)
# }

$RIDDLES = generate_riddles()
# puts "RIDDLES: #{$RIDDLES}"

$SUBMISSIONS = generate_submissions()
# puts "SUBMISSIONS: #{$SUBMISSIONS}"

$MATCHUPS = generate_matchups($SUBMISSIONS)
# puts "MATCHUPS: #{$MATCHUPS}"

# gets a matchup for a given team
def get_matchup(team_id, matchups = $MATCHUPS)
    matchup = matchups.find{|matchup| matchup[:team_id_a] != team_id && matchup[:team_id_b] != team_id && matchup[:completed] == false && matchup[:assigned] == false}
    matchup[:assigned] = true
    return matchup
end


# Print out stuff for testing
for i in 0..$NUM_TEAMS-1
    puts("Team #{i}: ")
    m = get_matchup("#{i}")
    puts m
    score_matchup(m[:id], m[:submission_id_a], m[:submission_id_b])
end

puts "SUBMISSIONS: #{$SUBMISSIONS}"

