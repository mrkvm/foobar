require 'celluloid'

# FooBar is the hippest nerd bar in town.
class FooBar
  include Celluloid

  def initialize
    @deejay = DeeJay.new("DJ KRAM", Actor.current)
    @hipsters = []
  end

  def open
    # go dj go!
    @deejay.spin!
  end

  def play(song)
    # There's a new song now playing in the bar.
    @now_playing = song
    song.play

    # Notify all the hipsters of the new song.
    # Note: this is an asynchronous call, and the lazy hipsters might
    # not even notice that a new song is playing right away.
    @hipsters.each do |hipster|
      hipster.listen!(@now_playing, @deejay)
    end
  end

  def pay_cover(hipster)
    # Hipsters pay cover to get into the bar
    @hipsters << hipster
  end

  def leave(hipster)
    # Hipsters can leave the bar
    @hipsters.delete hipster
    hipster.terminate
  end
end

# Every bar needs a good DJ
class DeeJay
  include Celluloid

  def initialize(name, bar)
    @name = name
    @bar = bar
    @requests = []
  end

  def spin
    loop do
      print "===== #{@name} on the 1s and the 2s... (request count: #{@requests.count}) =====\n"

      # DJs only play requests only 70% of the time, elistist jerks.
      if @requests.count > 0 && rand(100) < 70
        song = @requests.shift
      else
        # DJs always play weird shit when they aren't playing requests.
        song = Song.new("Super Obscure Band", "Really Weird Song")
      end

      # Play the song in the bar
      @bar.play(song)

      # Let the song play
      sleep rand(10)
    end
  end

  def request(song)
    @requests << song
  end
end

# Hipsters like to hang out at bars and dance
class Hipster
  include Celluloid

  def initialize(name, fave_song)
    @name = name
    @fave_song = fave_song
    @dancing = false
    @fave_requested = false
  end

  # We just noticed a song playing in the bar (note: it might not even
  # be playing anymore!). Listen and decide what to do.
  def listen(song, deejay)
    # Remember if we were dancing.
    was_dancing = @dancing
    @dancing = false
    
    if song == @fave_song
      # If our favorite song is playing, there's an 80% chance we'll
      # dance (hipsters can never be 100% happy).
      if rand(100) < 80
        @dancing = true
      end
      
      # Our favorite song got played, so we should request it again
      @fave_requested = false
    elsif rand(100) < 20
      # If it's not our favorite song, there's 20% chance we might
      # lower ourselves to dancing anyway.
      @dancing = true
    end
 
    # Check to see if our state changed.
    if !was_dancing && @dancing
      print "#{@name} started dancing when they heard #{song.title}\n"
    elsif was_dancing && !@dancing
      print "#{@name} stopped dancing when they heard #{song.title}\n"
    end
    
    # Hipsters need to do something if they aren't dancing.
    if !@dancing
      if rand(100) < 5
        # Hipsters sure do love their PBR, despite its awfulness
        print "#{@name} chugged a PBR\n"
      elsif !@fave_requested
        # Send a request to the DJ.
        @fave_requested = true
        deejay.request(@fave_song)
        print "#{@name} requested their favorite song\n"
      end
    end  
  end
end

class Song
  attr_reader :artist
  attr_reader :title

  def initialize(artist, title)
    @artist = artist
    @title = title
  end

  def play
    print "#{@title} by #{@artist} is playing\n"
  end

  def ==(other)
    if @artist == other.artist && @title == other.title
      true
    else
      false
    end
  end
end

foobar = FooBar.new

# Open the bar
foobar.open!

# Some hipsters show up at the bar
foobar.pay_cover(Hipster.new("Mark", Song.new("New Order", "Ceremony")))
foobar.pay_cover(Hipster.new("Denise", Song.new("Purity Ring", "Belispeak")))
foobar.pay_cover(Hipster.new("Mia", Song.new("fun.", "We Are Young")))
foobar.pay_cover(Hipster.new("Naomi", Song.new("Cocteau Twins", "The Spangle Maker")))
foobar.pay_cover(Hipster.new("Hollis", Song.new("Walkmen", "We Can't Be Beat")))

# Sleep the main thread
sleep
