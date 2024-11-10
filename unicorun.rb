require 'gosu'
require 'rubygems'

module ZOrder
    BACKGROUND, FOOD, PLAYER, UI = *0..3
  end

class Player
    attr_accessor  :image, :x, :y, :score, :speed, :lives, :width, :height

    def initialize(unicorn)
        @image = Gosu::Image.new("media/unicorn.png")
        @x = 80
        @y = 400
        @width = @image.width
        @height = @image.height
        @speed = 8
        @score = 0
        @lives = 3
    end


    def draw
        @image.draw_rot(@x, @y, 1, ZOrder::PLAYER)
    end

    def move_up
      @y -= @speed
    end

    def move_down
        @y += @speed
    end

    def bumped_into?(object) #method if player bumped to an object or collision
       self_top = @y 
       self_bottom = @y + @height
       self_left = @x
       self_right = @x + @width

        object_top = object.y
        object_bottom = object.y + object.height
        object_left = object.x
        object_right = object.x + object.width

        if self_top > object_bottom
            false
        elsif self_bottom < object_top
            false
        elsif self_left > object_right
            false
        elsif self_right < object_left
            false
        else
            true
        end
    end
    
end

class Food

    attr_accessor :image, :x, :y, :width, :height
    def initialize(window)
        @image = Gosu::Image.new("media/cherry.png")
        @x = 300
        @y = 500
        @width = @image.width
        @height = @image.height
        reset(window)
    end

    def reset(window)
        @y = Random.rand(window.height - @height)
        @x = window.width
    end
    
    def move
        @x = @x - 10
    end

    def draw
        @image.draw_rot(@x, @y, 1, ZOrder::FOOD)
    end
    

end

class Bomb

    attr_accessor :image, :x, :y, :width, :height
    def initialize(window)
        @image = Gosu::Image.new("media/bomb.png")
        @x = 500
        @y = 500
        @width = @image.width
        @height = @image.height
        reset(window)
    end

    def reset(window)
        @y = Random.rand(window.height - @height)
        @x = window.width
    end
    
    def move
        @x = @x - 10
    end

    def draw
        @image.draw_rot(@x, @y, 1, ZOrder::FOOD)
    end

end



class Background

    attr_accessor :background, :foreground, :scroll_x
    def initialize(window)
        @background = Gosu::Image.new("media/bg.png")
        @foreground = Gosu::Image.new("media/bg.png")
        @scroll_x = 0
    end

    def draw
        @background.draw(0, 0, ZOrder::BACKGROUND)
        @foreground.draw(-@scroll_x, 0, ZOrder::BACKGROUND)
        @foreground.draw(-@scroll_x + @foreground.width, 0, ZOrder::BACKGROUND) #draw another foreground
    end

    def update_bg
        @scroll_x += 1.5 #make the background scroll x with speed 1.5
        if @scroll_x > @foreground.width
            @scroll_x = 0 
        end
    end

end 


class GameWindow < Gosu::Window
SCREEN_WIDTH = 960
SCREEN_HEIGHT = 768
     def initialize
        super SCREEN_WIDTH, SCREEN_HEIGHT
        self.caption = "UNICORUN" 
        @background = Background.new(self)
        @logo = Gosu::Image.new("media/logo.png")
        @game_over = Gosu::Image.new("media/gameover.png")
        @player = Player.new(self)
        @foods = 2.times.map { Food.new(self) } #map will return an Array
        @bomb = Bomb.new(self)
        @bombs = 2.times.map { Bomb.new(self) }
        @font = Gosu::Font.new(40)
        @level = 1
        @playing = false
        @song = Gosu::Song.new('media/uni.ogg')
        @song.play(looping=true) #make the song loop until game finish
 
    end
   

    def draw 
        @background.draw
        @player.draw
        @logo.draw(240, 200, ZOrder::UI) unless @playing
        @font.draw_text("Hit SPACEBAR to Play", 300, 550, ZOrder::UI, 1.0, 1.0, Gosu::Color::WHITE) unless @playing
        @font.draw_text("Score: #{@player.score}", 10, 10, ZOrder::UI, 1.0, 1.0, Gosu::Color::WHITE)
        @font.draw_text("Lives: #{@player.lives}", 10, 50, ZOrder::UI, 1.0, 1.0, Gosu::Color::WHITE)
        @font.draw_text("Level : #{@level} ", 400, 10, 1)
        @game_over.draw(200, 120, ZOrder::UI) if @player.lives == 0
        @font.draw_text("Press R to start over", 300, 700, ZOrder::UI, 1.0, 1.0, Gosu::Color::GRAY) if @player.lives == 0
        return if @player.lives == 0
        @foods.each { |food| food.draw } 
        draw_bomb() unless draw_bombs()
    end

    def update
        return unless @playing
        return if @player.lives == 0

        @background.update_bg

        #player move up and down 
        if button_down? Gosu::KbUp
            if @player.y > 55
                @player.move_up
            else
                @player.y = 55
            end
        end
      
        if button_down? Gosu::KbDown
            if @player.y < self.height - @player.height + 55
                @player.move_down
            else
                @player.y = self.height - @player.height + 55
            end
        end

        #move food
        @foods.each do |food| 
            food.move
            food.reset(self) if food.x < 0 
            
            if @player.bumped_into? food
                @player.score += 1
                food.reset(self)
            end
        end

        #level to level two
        if @player.score > 20 && @player.score < 51
            level_two()
        end
       

        #bumped to bomb
        if @player.bumped_into? @bomb
            @player.lives -= 1
            @bomb.reset(self)
        end


        #level up to level three
        if @player.score > 50
            level_three()
        end
        
    end


    def draw_bomb
        if @player.score > 20
            @bomb.draw
        end 
    end

    def draw_bombs #draw bombs as an array
        if @player.score > 50
            @bombs.each { |bomb| bomb.draw } 
        end
    end


    def level_two
            @level = 2
            @bomb.move
            @bomb.reset(self) if @bomb.x < 0
    end

    def level_three
            @level = 3
            @bombs.each do |bomb| 
                bomb.move
                bomb.reset(self) if bomb.x < 0 
                
                if @player.bumped_into? bomb
                    @player.lives -= 1
                    bomb.reset(self)
                end
            end
    end



    def button_down(button)
        case(button)
        when Gosu::KbEscape
            close()
        when Gosu::KbSpace
            @score = 0
            @playing = true

        when  Gosu::KbR
            if @player.lives == 0 
               @playing = true
               @player.lives = 3
               @player.score = 0
               @level = 1
           end

        end

    end

end 

    

window = GameWindow.new
window.show
