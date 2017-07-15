class Hangman
  MAX_WRONG_GUESSES = 8
  BODY_PARTS = ["\\", "/", "|", "-", "-", "|", "|", "O"].freeze

  attr_reader :guesser, :referee, :board

  def initialize(players)
    @guesser = players[:guesser]
    @referee = players[:referee]
  end

  def play
    setup

    until game_over?
      take_turn
    end

    display_board
    end_message
  end

  def setup
    secret_length = referee.pick_secret_word
    guesser.register_secret_length(secret_length)
    @board = Array.new(secret_length)
    @remaining_guesses = MAX_WRONG_GUESSES
  end

  def take_turn
    display_board

    guess = guesser.guess(board)
    indices = referee.check_guess(guess)

    update_board(guess, indices)
    guesser.handle_response(guess, indices)

    @remaining_guesses -= 1 if indices.empty?
  end

  def update_board(guess, indices)
    indices.each { |i| board[i] = guess } unless indices.empty?
  end

  def game_over?
    board.none?(&:nil?) || @remaining_guesses == 0
  end

  def end_message
    if @remaining_guesses > 0
      referee.win_message
    else
      referee.lose_message
    end
  end

  def display_board
    puts hanging_man
    display_array = board.map { |el| el.nil? ? "_" : el }
    puts display_array.join(" ")
  end

  private

  def hanging_man
    body_display = BODY_PARTS.drop(@remaining_guesses)
    @remaining_guesses.times { body_display.unshift(" ") }
    "____\n|  |\n|  #{body_display[7]}\n|  #{body_display[6]}\n"\
    "| #{body_display[4]}#{body_display[5]}#{body_display[3]}\n"\
    "|  #{body_display[2]}\n| #{body_display[1]} #{body_display[0]}\n"\
    "|\n-----"
  end
end

class HumanPlayer
  attr_reader :secret_word

  def pick_secret_word
    print "Please enter the length of your secret word: "
    gets.chomp.to_i
  end

  def register_secret_length(length)
    puts "The secret word is #{length} letters long."
  end

  # 'board' is added to match the ComputerPlayer guess method
  def guess(board)
    print "Make a guess: "
    gets.chomp
  end

  def check_guess(guess)
    print "Is #{guess} in your word (y/n)? "
    answer = gets.chomp
    if answer == "y"
      print "Please enter the indice(s) of the letter (e.g. '0, 4'): "
      gets.chomp.split(", ").map(&:to_i)
    elsif answer == "n"
      []
    end
  end

  def handle_response(guess, indices)
    if indices.empty?
      puts "Bad guess!"
    else
      puts "Found '#{guess}' at positions #{indices}!"
    end
  end

  def win_message
    puts "The computer guessed your word!"
  end

  def lose_message
    puts "R.I.P. Computer"
  end
end

class ComputerPlayer
  def self.initialize_with_file(dict_file)
    self.new(File.readlines(dict_file).map(&:chomp))
  end

  attr_reader :candidate_words, :secret_word

  def initialize(dictionary)
    @dictionary = dictionary
  end

  def pick_secret_word
    @secret_word = @dictionary.sample
    @secret_word.length
  end

  def register_secret_length(length)
    @candidate_words = @dictionary.select { |word| word.length == length }
  end

  def guess(board)
    freq_hash = frequency_hash(board)
    largest_frequency = freq_hash.values.max
    freq_hash.select { |_k, v| v == largest_frequency }.keys.first
  end

  def handle_response(guess, indices)
    if indices.empty?
      @candidate_words.reject! { |word| word.include?(guess) }
    else
      @candidate_words.select! do |w|
        indices.all? { |i| w[i] == guess } && indices.length == w.count(guess)
      end
    end
  end

  def check_guess(letter)
    indices = []

    @secret_word.each_char.with_index do |c, i|
      indices << i if c == letter
    end

    indices
  end

  def win_message
    puts "You made it through alive!"
  end

  def lose_message
    puts "R.I.P. The word was #{secret_word}."
  end

  private

  def frequency_hash(board)
    letter_count = Hash.new(0)

    @candidate_words.each do |word|
      word.each_char.with_index do |c, i|
        letter_count[c] += 1 if board[i].nil?
      end
    end

    letter_count
  end
end

if $0 == __FILE__
  print "Guesser: Computer (y/n)? "
  if gets.chomp == "y"
    guesser = ComputerPlayer.initialize_with_file("dictionary.txt")
  else
    guesser = HumanPlayer.new
  end

  print "Referee: Computer (y/n)? "
  if gets.chomp == "y"
    referee = ComputerPlayer.initialize_with_file("dictionary.txt")
  else
    referee = HumanPlayer.new
  end

  Hangman.new(guesser: guesser, referee: referee).play
end
