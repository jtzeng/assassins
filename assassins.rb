# Assassins simulator.
require 'rainbow'
require 'trollop'
require 'zlib'

module Assassins
  extend Assassins

  @opts = Trollop::options do
    opt :die, "Whether to die after init"
    opt :count, "The number of players", :default => 8
    opt :path, "The path to the names file", :default => './assassins.txt'
    opt :shuffle_factor, "The chance of a random re-matchup", :default => 10
    opt :brightness, "The brightness of the name colors", :default => 1.5
    opt :no_color, "If your eyes are bleeding enough"
  end

  Trollop::die :count, 'too low' if @opts[:count] < 2

  Rainbow.enabled = !@opts[:no_color]

  # http://stackoverflow.com/questions/11120840/hash-string-into-rgb-color
  def color_str(s, sc)
    hash = Zlib.crc32(s)
    r = sc * ((hash & 0xFF0000) >> 16)
    g = sc * ((hash & 0x00FF00) >> 8)
    b = sc * (hash & 0x0000FF)
    r = 255 if r > 255
    g = 255 if g > 255
    b = 255 if b > 255
    Rainbow(s).color(r, g, b)
  end

  def make_players(path, n, sc)
    File.open(path) do |f|
      plrs = f.readlines.map(&:strip).select { |s| s.length > 0 }.shuffle[0...n]

      # Might as well store color attributes directly in the strings.
      plrs.map { |s| color_str(s, sc) }
    end
  end

  def find_target(plrs, p)
    return nil if plrs.empty? || plrs.length == 1
    i = plrs.index(p)
    i == plrs.length - 1 ? plrs[0] : plrs[i + 1]
  end

  def remove_random_player!(plrs)
    i = rand(plrs.length)
    k = plrs[i]
    t = find_target(plrs, k)

    # Return the killer and target.
    return k, plrs.delete(t)
  end

  def shuffle_targets!(plrs)
    plrs.shuffle!
  end

  def print_players(plrs)
    puts Rainbow('Mapping:').bright
    plrs.each { |p| puts "#{p} => #{find_target(plrs, p)}" }
  end

  def begin_game
    plrs = make_players(@opts[:path], @opts[:count], @opts[:brightness])
    puts Rainbow("Welcome to Assassins.\n").bright.green
    print_players(plrs)
    return if @opts[:die]

    while true
      k, t = remove_random_player!(plrs)
      puts "\n#{k} has killed #{t}.\n\n"
      print_players(plrs)

      if rand(@opts[:shuffle_factor]).zero?
        shuffle_targets!(plrs)
        puts "\nThe killers have new targets.\n\n"
        print_players(plrs)
      end

      break if plrs.length <= 1
    end

    puts "The champion is #{plrs[0]}! Congratulations!"
  end

end

Assassins.begin_game
