require 'ruby2d'

set background: 'yellow'      # Window color
set width: 1024, height: 768  # Window dimensions


class Paddle
  attr_accessor :direction

  def initialize(side = 'left', movement_speed = Window.height/80, auto_player = false)
    @pad_width  = Window.width/30     # width of the paddles
    @pad_height = (Window.height)/3   # height of the paddles
    @pad_indent = Window.width/25     # paddle indent from sides

    @auto_player = auto_player
    @movement_speed = movement_speed
    @direction = nil

    @y = Window.height/3              # y coordinate of paddles (upper-left korner)

    # x coordinates and game keys of the paddles according to the side (upper-left korner)
    if side == 'left'
      @x = @pad_indent
      @allowed_keys = ['w', 's']
    else
      @x = Window.width - @pad_width - @pad_indent
      @allowed_keys = ['up', 'down']
    end

  end


  def draw
    @shape = Rectangle.new(x: @x, y: @y, width: @pad_width, height: @pad_height, color: 'red' )
  end


  def move(ball)
    unless @auto_player
      if ['w', 'up'].include?(@direction)
        @y = [@y - @movement_speed, 0].max
      elsif ['s', 'down'].include?(@direction)
        @y = [@y + @movement_speed, max_y].min
      end
    else
      track_the_ball?(ball)   # if auto player is true, the paddles moves itself and tracks the ball
    end

  end

  def is_allowed_key?(event_key)
    @allowed_keys.include?(event_key)   # checks whether keys is right that pressed by user
  end


  def hit_the_paddles?(ball)
    # The following are coordinates of ball (four corners)
    ball && [[ball.x1,ball.y1], [ball.x2,ball.y2], [ball.x3,ball.y3], [ball.x4,ball.y4]].any? do |coordinate|
      @shape.contains?(coordinate[0], coordinate[1])  # is paddles contain ball's coordinates?
    end

  end

  def increase_movement_speed
    @movement_speed += 1
  end

  private

  def max_y
    Window.height - @pad_height
  end

  def y_middle
    @y + @pad_height / 2
  end

  def track_the_ball?(ball)
    if ball.y_middle > y_middle
      @y = [@y + @movement_speed, max_y].min
    elsif ball.y_middle < y_middle
      @y = [@y - @movement_speed, 0].max
    end
  end


end


class Ball
  attr_reader :shape, :finished, :increase_speed

  def initialize(x_velocity = Window.width/128, y_velocity = Window.height/96, increase_speed = true )
    @x = Window.height / 2                            # x coordinate of ball
    @y = Window.width  / 2                            # y coordinate of ball
    @size = Window.height * Window.width / 25000      # size of ball

    @x_velocity = x_velocity                          # speed of the ball on the x-axis
    @y_velocity = y_velocity                          # speed of the ball on the y-axis

    @increase_speed = increase_speed
    @start_time = Time.now
    @finished = false

  end


  def draw
    @shape = Square.new(x: @x, y: @y, size: @size, color: 'red') unless finished
    Text.new(text_message, x: Window.width / 75, y: Window.height/ 100, color: 'green')
  end


  def bounce(axis)
    @x_velocity = -@x_velocity if axis == 'x'
    @y_velocity = -@y_velocity if axis == 'y'
  end


  def move
    bounce('y') if hit_lower_upper_edges?

    @x -= @x_velocity
    @y += @y_velocity
  end

  def increase_speed?
    @time ||= Time.now

    #Increases the movement speed of paddles and game ball per 1 second
    if Time.now - @time >= 1
      @x_velocity > 0 ? @x_velocity += 1 : @x_velocity -= 1
      @y_velocity > 0 ? @y_velocity += 1 : @y_velocity -= 1
      @time = nil
      return true  # for increase paddles speed
    end

    return false

  end

  def text_message
    @finished ? "Game over. Press 'r' to Retry" : "Time: #{(Time.now - @start_time).round}"
  end


  def game_over?
    hit_left_right_sides?
  end

  def finish
    @finished = true
  end

  def y_middle
    @y + @size / 2
  end


  private

  def hit_lower_upper_edges?
    @y <= 0 || @y >= Window.height - @size
  end

  def hit_left_right_sides?
    @x <= 0 || @x >= Window.width - @size
  end


end


paddle1 = Paddle.new('left')
paddle2 = Paddle.new('right', Window.height/80, true ) # auto player. do false for two players
ball = Ball.new


update do
  clear

  if paddle1.hit_the_paddles?(ball.shape) || paddle2.hit_the_paddles?(ball.shape)
    ball.bounce('x')
  end


  if ball.game_over?
    ball.finish
  else
    paddle1.move(ball)
    paddle2.move(ball)
    ball.move
  end


  paddle1.draw
  paddle2.draw
  ball.draw


  if ball.increase_speed && ball.increase_speed?
    paddle1.increase_movement_speed
    paddle2.increase_movement_speed
  end

end


on :key_down do |event|
  if ball.finished
    case event.key.downcase
    when 'r'
      paddle1 = Paddle.new('left')
      paddle2 = Paddle.new('right', Window.height/80, true ) # auto player do false for two players
      ball = Ball.new
    when 'q'
      exit
    end
  end
end


on :key_held do |event|
  paddle1.direction = event.key if paddle1.is_allowed_key?(event.key)
  paddle2.direction = event.key if paddle2.is_allowed_key?(event.key)
end


on :key_up do |event|
  paddle1.direction = nil if paddle1.is_allowed_key?(event.key)
  paddle2.direction = nil if paddle2.is_allowed_key?(event.key)

end



show
