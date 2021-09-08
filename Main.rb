require 'rubygems'
require 'gosu'

include Gosu

require_relative 'Perlin.rb'
require_relative 'Textflash.rb'
require_relative 'TextClass.rb'
require_relative 'Unit.rb'

class GameWindow < Gosu::Window
	
	WIDTH = 1000
	HEIGHT = 700
	TITLE = "Just another ruby project"
	
	attr_reader :font, :bigfont
	
	def initialize
		
		super(WIDTH, HEIGHT, false)
		self.caption = TITLE
		
		$window_width = WIDTH
		$window_height = HEIGHT
		
		@asteroids_img = Gosu::Image.new(self, "media/asteroids.png", true)
		@darkmatter_img = Gosu::Image.new(self, "media/darkmatter2.png", true)
		@refinery_img = Gosu::Image.new(self, "media/refinery.png", true)
		@shipyard_img = Gosu::Image.new(self, "media/shipyard.png", true)
		@radiation_img = Gosu::Image.new(self, "media/radiation.png", true)
		@nebula_img = Gosu::Image.new(self, "media/nebula.png", true)
		@wallfull_img = Gosu::Image.new("media/wallfull16.png", retro: true)
		@wall1_img = Gosu::Image.new("media/wall116.png", retro: true)
		@wall2_img = Gosu::Image.new("media/wall216.png", retro: true)
		@wall3_img = Gosu::Image.new("media/wall316.png", retro: true)
		@wall4_img = Gosu::Image.new("media/wall416.png", retro: true)
		@grid20_img = Gosu::Image.new(self, "media/20x20_grid.png", true)
		
		@font = Gosu::Font.new(self, Gosu::default_font_name, 17)
		@font18 = Gosu::Font.new(self, Gosu::default_font_name, 18)
		@bigfont = Gosu::Font.new(self, Gosu::default_font_name, 20)
		
		$tiles = []				## An 8000 array which stores all the possible 100 x 80 tiles in the game.
		$worldsize_x = 20		## Size of world in tiles
		$worldsize_y = 20		
		$tile_size = 16
		
		$textflash = []
		$units = []
		
		@menu = "main"
		
		$camera_x = $worldsize_x * $tile_size / 2.0
		$camera_y = $worldsize_y * $tile_size / 2.0
		$zoomlvls = [1.8, 2.08, 3.0]
		$zoomindx = 0
		$camera_zoom = $zoomlvls[$zoomindx]
		
		for i in 0..$worldsize_x * $worldsize_y - 1
			$tiles[i] = "ground"
		end
		
		@perlin_frequency = 12
		@perlin1 = Perlin.new(self, @perlin_frequency)
		
		## Load map names
		@saved = Dir.entries("maps")
		@saved.shift(2)
		
		@scenarios = ["Skirmish", "Frontier Battle"]
		
	end
	
	def update
		self.caption = "Platinum Wars  -  [FPS: #{Gosu::fps.to_s}]"
		
		$textflash.each   { |inst|  inst.update }
		$units.each   { |inst|  inst.update }
		
		if button_down? Gosu::KbA
			$camera_x = $camera_x-3
		end
		if button_down? Gosu::KbD
			$camera_x = $camera_x+3
		end
		if button_down? Gosu::KbW
			$camera_y = $camera_y-3
		end
		if button_down? Gosu::KbS
			$camera_y = $camera_y+3
		end
	end
	
	def button_down(id)
		case id
			when Gosu::KbEscape
				close
			when Gosu::KbQ
				$zoomindx = [0, $zoomindx-1].max
				$camera_zoom = $zoomlvls[$zoomindx]
			when Gosu::KbE
				$zoomindx = [$zoomlvls.length-1, $zoomindx+1].min
				$camera_zoom = $zoomlvls[$zoomindx]
			when Gosu::MsLeft
				if @menu == "main"
					if point_in_rectangle(mouse_x, mouse_y, 10, 658, 150, 681)
						@menu = "custom"
					end
					
					for i in 0..@scenarios.length-1
						save_a = 10
						save_b = 310+1 + 26*i
						save_c = 150
						save_d = 310-1 + 26*(i+1)
						
						if point_in_rectangle(mouse_x, mouse_y, save_a, save_b, save_c, save_d)
							self.load_scenario(@scenarios[i])
						end
					end
					
				elsif @menu == "custom"
					if point_in_rectangle(mouse_x, mouse_y, 10, 658, 75, 681)
						@menu = "main"
					end
				end
				
		end
	end
	
	def load_scenario(scenario)
		
		@menu = false
		if scenario == "Skirmish"
			self.load_map("skirmish.txt")
			$camera_x = $worldsize_x * $tile_size / 2.0
			$camera_y = $worldsize_y * $tile_size / 2.0
			$zoomindx = 2
			$camera_zoom = $zoomlvls[$zoomindx]
			
		elsif scenario == "Frontier Battle"
			self.load_map("frontier.txt")
			$camera_x = $worldsize_x * $tile_size / 2.0
			$camera_y = $worldsize_y * $tile_size / 2.0
			$zoomindx = 1
			$camera_zoom = $zoomlvls[$zoomindx]
		end
		
	end
	
	def load_map(mapfile)
		
		mapdata = []	## Mapdata is a 1d array
		this_line = []
		
		File.open("maps/#{mapfile}") do |f|
			f.each_line do |line|
				this_line = line.split
				mapdata << this_line
			end
		end
		
		if mapdata.length == 2
			
			self.create_textflash($window_width/2-20, 10, "Map Loaded!", false, 0xffFF7F00, false, "big", 100)
			
			$worldsize_x = mapdata[0][0].to_i
			$worldsize_y = mapdata[0][1].to_i
			
			$tiles = []
			for i in 0..mapdata[1].length-1
				$tiles[i] = mapdata[1][i]
			end
		else
			
			mapdata = []	## Mapdata is a 1d array
			this_line = []
			
			File.open("maps/#{mapfile}") do |f|
				f.each_line do |line|
					mapdata << line.chop
				end
			end
			
			$worldsize_x = 20
			$worldsize_y = 20
			
			$tiles = []
			for i in 0..mapdata.length-1
				$tiles[i] = mapdata[i]
			end
		
		end
		
		## Generate perlin values for the wall colors
		## 
		@wall_perlin_values = []
		for i in 0..$tiles.length-1
			tx = i % $worldsize_x
			ty = (i/$worldsize_x).floor
			x = get_x(tx)
			y = get_y(ty)
			tempvals = []
			
			for e in 0..3
				case e
					when 0
						boundx = x - $tile_size/4.0
						boundy = y - $tile_size/4.0
					when 1
						boundx = x + $tile_size/4.0
						boundy = y - $tile_size/4.0
					when 2
						boundx = x + $tile_size/4.0
						boundy = y + $tile_size/4.0
					when 3
						boundx = x - $tile_size/4.0
						boundy = y + $tile_size/4.0
				end
				
				norm_x = self.normalize(0, $worldsize_x*$tile_size, boundx)
				norm_y = self.normalize(0, $worldsize_y*$tile_size, boundy)
				val1 = @perlin1.perlin(norm_x, norm_y)		## Gives a value between 0..1
				tempvals << val1
			end
			@wall_perlin_values << tempvals
		end
		
	end
	
	def get_x(tile_x)
		return tile_x * $tile_size
	end
	
	def get_y(tile_y)
		return tile_y * $tile_size
	end
	
	def normalize(a, b, x)
		## Similar to lerp, except reversed.
		## It outputs a number between 0..1 (when x is between a and b)
		## 
		## b should be larger than a
		w = b-a
		p = x-a
		return p*1.0/w
	end
	
	### Optimised point_in_rectangle. DOES NOT WORK IF SECOND POINT IS LESS THAN FIRST POINT!!!
	def point_in_rectangle(point_x, point_y, first_x, first_y, second_x, second_y)
		if point_x.between?(first_x, second_x) and point_y.between?(first_y, second_y)
			return true
		end
	end
	
	def create_textflash(x, y, text, camera, color, moving, size, lifetime)
		inst = TextFlash.new(self, x, y, text, camera, color, moving, size, lifetime)
		$textflash << inst
	end
	
	def create_unit(type, x, y)
		inst = Unit.new(self, type, x, y)
		$units << inst
	end
	
	def destroy_textflash(id)
		$textflash.delete(id)
	end
	
	def destroy_unit(inst)
		$units.delete(inst)
	end
	
	def draw
		## Background
		color = 0xff000000
		self.draw_quad(0, 0, color, $window_width, 0, color, $window_width, $window_height, color, 0, $window_height, color, 0)
		
		$textflash.each   { |inst|  inst.draw }
		$units.each   { |inst|  inst.draw }
		
		if @menu == false
			
			## Tiles
			for i in 0..$tiles.length-1
				
				tx = i % $worldsize_x
				ty = (i/$worldsize_x).floor
				
				x = get_x(tx)
				y = get_y(ty)
				
				## Draw grid
				if (tx + ty).even? == true
					color = 0xffbfbfbf
				else
					color = 0xffaaaaaa
				end
				x1 = (x-$tile_size/2)*$camera_zoom + $window_width/2 - $camera_x*$camera_zoom
				x2 = (x+$tile_size/2)*$camera_zoom + $window_width/2 - $camera_x*$camera_zoom
				y1 = (y-$tile_size/2)*$camera_zoom + $window_height/2 - $camera_y*$camera_zoom
				y2 = (y+$tile_size/2)*$camera_zoom + $window_height/2 - $camera_y*$camera_zoom
				self.draw_quad(x1, y1, color, x2, y1, color, x2, y2, color, x1, y2, color, 0)
				
				## Draw features
				colorr = 0xff727272
				
				if $tiles[i] == "wall"
					
					for e in 0..3
						
						case e
							when 0
								scalex = 1
								scaley = 1
							when 1
								scalex = -1
								scaley = 1
							when 2
								scalex = -1
								scaley = -1
							when 3
								scalex = 1
								scaley = -1
						end
						
						colval = @wall_perlin_values[i][e]
						
						blue = ([colorr%256 - 60*colval, 0].max).to_i
						green = ([(colorr/256)%256 - 60*colval, 0].max).to_i
						red = ([(colorr/65536)%256 - 60*colval, 0].max).to_i
						alpha = ((colorr/16777216)%256).to_i
						
						col = alpha*16777216 +
										[[red, 0].max, 255].min*65536 +
										[[green, 0].max, 255].min*256 +
										[[blue, 0].max, 255].min
						
						boundx = x - scalex*$tile_size/2.0
						boundy = y - scaley*$tile_size/2.0
						
						if boundx.between?(4, $worldsize_x * $tile_size-20) and boundy.between?(4, $worldsize_y * $tile_size-20)
							
							nindx1 = i - scalex
							nindx2 = i - $worldsize_x*scaley
							nindx3 = i - $worldsize_x*scaley - scalex
							
							if $tiles[nindx1] != "wall" and $tiles[nindx2] != "wall"
								if $tiles[nindx3] != "wall"
									@wall2_img.draw_rot((x-$tile_size)*$camera_zoom + $window_width/2 - $camera_x*$camera_zoom, (y-$tile_size)*$camera_zoom + $window_height/2 - $camera_y*$camera_zoom, 2, 0, 1-scalex, 1-scaley, $camera_zoom*(scalex), $camera_zoom*(scaley), col)
								else
									@wall3_img.draw_rot((x-$tile_size)*$camera_zoom + $window_width/2 - $camera_x*$camera_zoom, (y-$tile_size)*$camera_zoom + $window_height/2 - $camera_y*$camera_zoom, 2, 0, 1-scalex, 1-scaley, $camera_zoom*(scalex), $camera_zoom*(scaley), col)
								end
							elsif $tiles[nindx1] == "wall" and $tiles[nindx2] == "wall" and $tiles[nindx3] != "wall"
								@wall4_img.draw_rot((x-$tile_size)*$camera_zoom + $window_width/2 - $camera_x*$camera_zoom, (y-$tile_size)*$camera_zoom + $window_height/2 - $camera_y*$camera_zoom, 2, 0, 1-scalex, 1-scaley, $camera_zoom*(scalex), $camera_zoom*(scaley), col)
							else
								@wall1_img.draw_rot((x-$tile_size)*$camera_zoom + $window_width/2 - $camera_x*$camera_zoom, (y-$tile_size)*$camera_zoom + $window_height/2 - $camera_y*$camera_zoom, 2, 0, 1-scalex, 1-scaley, $camera_zoom*(scalex), $camera_zoom*(scaley), col)
							end
						else
							@wall1_img.draw_rot((x-$tile_size)*$camera_zoom + $window_width/2 - $camera_x*$camera_zoom, (y-$tile_size)*$camera_zoom + $window_height/2 - $camera_y*$camera_zoom, 2, 0, 1-scalex, 1-scaley, $camera_zoom*(scalex), $camera_zoom*(scaley), col)
						end
						
					end
					
					# @wallfull_img.draw_rot(x*$camera_zoom + $window_width/2 - $camera_x*$camera_zoom, y*$camera_zoom + $window_height/2 - $camera_y*$camera_zoom, 1, 0, 0.5, 0.5, $camera_zoom, $camera_zoom, colorr)
					
					
				elsif $tiles[i] == "asteroids"
					@asteroids_img.draw_rot(x*$camera_zoom + $window_width/2 - $camera_x*$camera_zoom, y*$camera_zoom + $window_height/2 - $camera_y*$camera_zoom, 1, 0, 0.5, 0.5, 16/30.0*$camera_zoom, 16/30.0*$camera_zoom)
				elsif $tiles[i] == "nebula"
					@nebula_img.draw_rot(x*$camera_zoom + $window_width/2 - $camera_x*$camera_zoom, y*$camera_zoom + $window_height/2 - $camera_y*$camera_zoom, 1, 0, 0.5, 0.5, 16/30.0*$camera_zoom, 16/30.0*$camera_zoom)
				elsif $tiles[i] == "dark_matter"
					@darkmatter_img.draw_rot(x*$camera_zoom + $window_width/2 - $camera_x*$camera_zoom, y*$camera_zoom + $window_height/2 - $camera_y*$camera_zoom, 1, 0, 0.5, 0.5, 16/35.0*$camera_zoom, 16/35.0*$camera_zoom, 0xaaffffff)
				elsif $tiles[i] == "refinery"
					@refinery_img.draw_rot(x*$camera_zoom + $window_width/2 - $camera_x*$camera_zoom, y*$camera_zoom + $window_height/2 - $camera_y*$camera_zoom, 1, 0, 0.5, 0.5, 16/30.0*$camera_zoom, 16/30.0*$camera_zoom)
				elsif $tiles[i] == "shipyard"
					@shipyard_img.draw_rot(x*$camera_zoom + $window_width/2 - $camera_x*$camera_zoom, y*$camera_zoom + $window_height/2 - $camera_y*$camera_zoom, 1, 0, 0.5, 0.5, 16/30.0*$camera_zoom, 16/30.0*$camera_zoom)
				elsif $tiles[i] == "radiation"
					@radiation_img.draw_rot(x*$camera_zoom + $window_width/2 - $camera_x*$camera_zoom, y*$camera_zoom + $window_height/2 - $camera_y*$camera_zoom, 1, 0, 0.5, 0.5, 16/30.0*$camera_zoom, 16/30.0*$camera_zoom)
				end
				
			end
		elsif @menu == "main"		##### Main menu
			
			@bigfont.draw("Platinum Wars"	, 200, 20, 11, 1.0, 1.0, 0xffffffff)
			
			@font18.draw("Select Scenario"	, 10, 280, 11, 1.0, 1.0, 0xffffffff)
			for i in 0..@scenarios.length-1
				
				save_a = 10
				save_b = 310+1 + 26*i
				save_c = 150
				save_d = 310-1 + 26*(i+1)
				
				if point_in_rectangle(mouse_x, mouse_y, save_a, save_b, save_c, save_d)
					savecol = 0xffffffff
				else
					savecol = 0xffcccccc
				end
				
				self.draw_quad(save_a+2, save_b, savecol, save_c-2, save_b, savecol, save_c-2, save_d, savecol, save_a+2, save_d, savecol, 12)
				@font18.draw("#{@scenarios[i]}", save_a+6, save_b+3, 13, 1.0, 1.0, 0xff000000)
				
			end
			
			## Custom Game button
			a = 10
			b = 658
			c = 150
			d = 681
			if point_in_rectangle(mouse_x, mouse_y, a, b, c, d)
				color2 = 0xffffffff
			else
				color2 = 0xffcccccc
			end
			self.draw_quad(a, b, color2, c, b, color2, c, d, color2, a, d, color2, 11)
			@font18.draw("Custom Game", a+7, b+3, 11, 1.0, 1.0, 0xff000000) 
			
		elsif @menu == "custom"		##### Custom Game menu
			
			@bigfont.draw("Custom Game"	, 200, 20, 11, 1.0, 1.0, 0xffffffff)
			@bigfont.draw("(in development)"	, 200, 40, 11, 1.0, 1.0, 0xffffffff)
			
			@font18.draw("Select Map"	, 10, 280, 11, 1.0, 1.0, 0xffffffff)
			
			for i in 0..@saved.length-1
				save_a = 7
				save_b = 310+1 + 26*i
				save_c = 100
				save_d = 310-1 + 26*(i+1)
				
				if point_in_rectangle(mouse_x, mouse_y, save_a, save_b, save_c, save_d)
					savecol = 0xffffffff
				else
					savecol = 0xffcccccc
				end
				
				self.draw_quad(save_a+2, save_b, savecol, save_c-2, save_b, savecol, save_c-2, save_d, savecol, save_a+2, save_d, savecol, 12)
				@font18.draw("#{@saved[i].chop.chop.chop.chop}", save_a+6, save_b+3, 13, 1.0, 1.0, 0xff000000)
			end
			
			@font18.draw("Select Teams"	, 160, 280, 11, 1.0, 1.0, 0xffffffff)
			
			for i in 2..4
				save_a = 157
				save_b = 310+1 + 26*(i-2)
				save_c = 250
				save_d = 310-1 + 26*(i-1)
				
				if point_in_rectangle(mouse_x, mouse_y, save_a, save_b, save_c, save_d)
					savecol = 0xffffffff
				else
					savecol = 0xffcccccc
				end
				
				self.draw_quad(save_a+2, save_b, savecol, save_c-2, save_b, savecol, save_c-2, save_d, savecol, save_a+2, save_d, savecol, 12)
				@font18.draw("#{i} teams", save_a+6, save_b+3, 13, 1.0, 1.0, 0xff000000)
			end
			
			@font18.draw("Controled by"	, 310, 280, 11, 1.0, 1.0, 0xffffffff)
			
			for i in 0..2
				
				save_a = 307
				save_b = 310+1 + 26*i
				save_c = 440
				save_d = 310-1 + 26*(i+1)
				
				if point_in_rectangle(mouse_x, mouse_y, save_a, save_b, save_c, save_d)
					savecol = 0xffffffff
				else
					savecol = 0xffcccccc
				end
				
				self.draw_quad(save_a+2, save_b, savecol, save_c-2, save_b, savecol, save_c-2, save_d, savecol, save_a+2, save_d, savecol, 12)
				case i
					when 0
						@font18.draw("1 player vs ais"	, save_a+6, save_b+3, 13, 1.0, 1.0, 0xff000000)
					when 1
						@font18.draw("all players"	, save_a+6, save_b+3, 13, 1.0, 1.0, 0xff000000)
					when 2
						@font18.draw("all ais"	, save_a+6, save_b+3, 13, 1.0, 1.0, 0xff000000)
				end
				
			end
			
			## Back button
			a = 10
			b = 658
			c = 75
			d = 681
			if point_in_rectangle(mouse_x, mouse_y, a, b, c, d)
				color2 = 0xffffffff
			else
				color2 = 0xffcccccc
			end
			self.draw_quad(a, b, color2, c, b, color2, c, d, color2, a, d, color2, 11)
			@font18.draw("Back", a+7, b+3, 11, 1.0, 1.0, 0xff000000) 
			
		end
		
	end
	
	def needs_cursor?
		true
	end
	
end

# show the window
window = GameWindow.new
window.show