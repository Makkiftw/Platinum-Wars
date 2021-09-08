require 'rubygems'
require 'gosu'

include Gosu

require_relative 'Perlin.rb'
require_relative 'Textflash.rb'
require_relative 'TextClass.rb'

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
		$worldsize_x_new = 20		
		$worldsize_y_new = 20		
		$tile_size = 16
		
		$textflash = []
		
		$camera_x = $worldsize_x * $tile_size / 2.0
		$camera_y = $worldsize_y * $tile_size / 2.0
		$zoomlvls = [1.8, 2.08, 3.0]
		$zoomindx = 0
		$camera_zoom = $zoomlvls[$zoomindx]
		
		$selection = 0
		$sel_ary = [nil, "ground", "wall", "asteroids", "nebula", "interior", "dark_matter", "refinery", "shipyard", "radiation"]
		
		for i in 0..$worldsize_x * $worldsize_y - 1
			$tiles[i] = "ground"
		end
		
		$tiles[1] = "asteroids"
		
		@perlin_frequency = 12
		@perlin1 = Perlin.new(self, @perlin_frequency)
		
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
		
		## Load map names
		@saved = Dir.entries("maps")
		@saved.shift(2)
		
		@mapname = ""
		@cursor = false
		
		## Textfields
		@text_field1 = TextField.new(self, @font, 13+6, 203+3, 12)
		@text_field2 = TextField.new(self, @font, 10+6, 624+3, 12)
		@text_field3 = TextField.new(self, @font, 60+6, 624+3, 12)
		self.text_input = nil
		
	end
	
	def update
		self.caption = "Map Editor  -  [FPS: #{Gosu::fps.to_s}]"
		
		$textflash.each   { |inst|  inst.update }
		
		if self.text_input == nil
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
		if button_down? Gosu::MsLeft
			
			tile_pos_x = (((mouse_x - $window_width/2) / $camera_zoom + $camera_x)/16).round*16
			tile_pos_y = (((mouse_y - $window_height/2) / $camera_zoom + $camera_y)/16).round*16
		
			tile_x = get_tile_x(tile_pos_x)
			tile_y = get_tile_y(tile_pos_y)
			
			indx = tile_x + tile_y*$worldsize_x
			if indx.between?(0, $worldsize_x*$worldsize_y-1) and point_in_rectangle(tile_pos_x, tile_pos_y, 0, 0, ($worldsize_x-1)*$tile_size, ($worldsize_y-1)*$tile_size)
				ss = $sel_ary[$selection]
				if ss != nil
					$tiles[indx] = ss
				end
			end
		end
	end
	
	def button_down(id)
		case id
			when Gosu::KbEscape
				close
			when Gosu::KbQ
				if self.text_input == nil
					$zoomindx = [0, $zoomindx-1].max
					$camera_zoom = $zoomlvls[$zoomindx]
				end
			when Gosu::KbE
				if self.text_input == nil
					$zoomindx = [$zoomlvls.length-1, $zoomindx+1].min
					$camera_zoom = $zoomlvls[$zoomindx]
				end
			when Gosu::Kb1
				if self.text_input == nil
					if $selection != 1
						$selection = 1
					else
						$selection = 0
					end
				end
			when Gosu::Kb2
				if self.text_input == nil
					if $selection != 2
						$selection = 2
					else
						$selection = 0
					end
				end
			when Gosu::Kb3
				if self.text_input == nil
					if $selection != 3
						$selection = 3
					else
						$selection = 0
					end
				end
			when Gosu::Kb4
				if self.text_input == nil
					if $selection != 4
						$selection = 4
					else
						$selection = 0
					end
				end
			# when Gosu::Kb5
				# if self.text_input == nil
					# if $selection != 5
						# $selection = 5
					# else
						# $selection = 0
					# end
				# end
			when Gosu::Kb6
				if self.text_input == nil
					if $selection != 6
						$selection = 6
					else
						$selection = 0
					end
				end
			when Gosu::Kb7
				if self.text_input == nil
					if $selection != 7
						$selection = 7
					else
						$selection = 0
					end
				end
			when Gosu::Kb8
				if self.text_input == nil
					if $selection != 8
						$selection = 8
					else
						$selection = 0
					end
				end
			when Gosu::Kb9
				if self.text_input == nil
					if $selection != 9
						$selection = 9
					else
						$selection = 0
					end
				end
			when Gosu::MsLeft
				
				if point_in_rectangle(mouse_x, mouse_y, 13, 233, 97, 257)
					$selection = 0
					if @mapname != "" and self.text_input == nil
						self.save_map
					end
				elsif point_in_rectangle(mouse_x, mouse_y, 10, 658, 90, 681)
					$selection = 0
					if self.text_input == nil
						self.new_map
					end
				elsif point_in_rectangle(mouse_x, mouse_y, 13, 203, 97, 225)
					if @cursor == "mapname"
						@cursor = false
						@mapname = self.text_input.text
						self.text_input.text = ""
						self.text_input = nil
					else
						@cursor = "mapname"
						self.text_input = @text_field1
						self.text_input.text = @mapname
						self.text_input.move_caret($window_width) unless self.text_input.nil?
					end
				elsif point_in_rectangle(mouse_x, mouse_y, 10, 624, 50, 644)
					if @cursor == "x_mapsize"
						self.macro_setworldsizex
					else
						@cursor = "x_mapsize"
						self.text_input = @text_field2
						self.text_input.text = $worldsize_x_new
						self.text_input.move_caret($window_width) unless self.text_input.nil?
					end
				elsif point_in_rectangle(mouse_x, mouse_y, 60, 624, 100, 644)
					if @cursor == "y_mapsize"
						self.macro_setworldsizey
					else
						@cursor = "y_mapsize"
						self.text_input = @text_field3
						self.text_input.text = $worldsize_y_new
						self.text_input.move_caret($window_width) unless self.text_input.nil?
					end
				end
				
				for i in 0..@saved.length-1
							
					save_a = 7
					save_b = 310+1 + 26*i
					save_c = 100
					save_d = 310-1 + 26*(i+1)
					
					if point_in_rectangle(mouse_x, mouse_y, save_a, save_b, save_c, save_d)
						$selection = 0
						self.load_map(@saved[i])
						@mapname = @saved[i].chop.chop.chop.chop
						break
					end
					
				end
				
				
				if !point_in_rectangle(mouse_x, mouse_y, 13, 203, 97, 225) and @cursor == "mapname"
					@cursor = false
					@mapname = self.text_input.text
					self.text_input.text = ""
					self.text_input = nil
				end
				if !point_in_rectangle(mouse_x, mouse_y, 10, 624, 50, 644) and @cursor == "x_mapsize"
					self.macro_setworldsizex
				end
				if !point_in_rectangle(mouse_x, mouse_y, 60, 624, 100, 644) and @cursor == "y_mapsize"
					self.macro_setworldsizey
				end
				
			when Gosu::KbReturn
				if @cursor == "mapname"
					@cursor = false
					@mapname = self.text_input.text
					self.text_input.text = ""
					self.text_input = nil
				elsif @cursor == "x_mapsize"
					self.macro_setworldsizex
				elsif @cursor == "y_mapsize"
					self.macro_setworldsizey
				end
				
		end
	end
	
	def macro_setworldsizex
		@cursor = false
		$worldsize_x_new = [[self.text_input.text.to_i, 5].max, 50].min
		self.text_input.text = ""
		self.text_input = nil
	end
	
	def macro_setworldsizey
		@cursor = false
		$worldsize_y_new = [[self.text_input.text.to_i, 5].max, 50].min
		self.text_input.text = ""
		self.text_input = nil
	end
	
	def save_map
		save_text = ""
		save_text << "#{$worldsize_x} #{$worldsize_y}\n"
		for i in 0..$tiles.length-1
			type = $tiles[i]
			save_text << "#{type} "
		end
		
		File.open("maps/#{@mapname}.txt", "w") {|f| f.write(save_text) }
		self.create_textflash($window_width/2-20, 10, "Map Saved!", false, 0xffFF7F00, false, "big", 100)
		
		@saved = Dir.entries("maps")
		@saved.shift(2)
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
	
	def new_map
		$worldsize_x = $worldsize_x_new		## Size of world in tiles
		$worldsize_y = $worldsize_y_new
		$tiles = []
		for i in 0..$worldsize_x * $worldsize_y - 1
			$tiles[i] = "ground"
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
	
	def draw
		## Background
		color = 0xff000000
		self.draw_quad(0, 0, color, $window_width, 0, color, $window_width, $window_height, color, 0, $window_height, color, 0)
		
		$textflash.each   { |inst|  inst.draw }
		
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
		
		## Tile selection
		cols = []
		for i in 1..9
			cols[i] = 0xffcccccc
			if $selection == i
				cols[i] = 0xffffff00
			end
		end
		
		@font.draw("1: ground"		, 10, 10, 11, 1.0, 1.0, cols[1])
		@font.draw("2: wall"		, 10, 30, 11, 1.0, 1.0, cols[2])
		@font.draw("3: asteroids"	, 10, 50, 11, 1.0, 1.0, cols[3])
		@font.draw("4: nebula"		, 10, 70, 11, 1.0, 1.0, cols[4])
		@font.draw("5: interior"	, 10, 90, 11, 1.0, 1.0, 0x88cccccc)
		@font.draw("6: dark_matter"	, 10, 110, 11, 1.0, 1.0, cols[6])
		@font.draw("7: refinery"	, 10, 130, 11, 1.0, 1.0, cols[7])
		@font.draw("8: shipyard"	, 10, 150, 11, 1.0, 1.0, cols[8])
		@font.draw("9: radiation"	, 10, 170, 11, 1.0, 1.0, cols[9])
		
		
		## Map name
		a = 13
		b = 203
		c = 97
		d = 225
		if point_in_rectangle(mouse_x, mouse_y, a, b, c, d)
			bgcol = 0xffdddd22
		else
			bgcol = 0xffcccccc
		end
		self.draw_quad(a, b, bgcol, c, b, bgcol, c, d, bgcol, a, d, bgcol, 11)
		
		if @cursor == "mapname"
			@text_field1.draw
		else
			if @mapname != ""
				@font.draw("''#{@mapname}''", a+6, b+3, 11, 1.0, 1.0, 0xff000000)
			else
				@font.draw("?", a+6, b+3, 11, 1.0, 1.0, 0xff000000)
			end
		end
		
		## Save map button
		a = 10
		b = 230
		c = 100
		d = 260
		if @mapname == ""
			color2 = 0xff888888
		else
			if point_in_rectangle(mouse_x, mouse_y, a, b, c, d)
				color2 = 0xffffff00
			else
				color2 = 0xffcccccc
			end
		end
		self.draw_quad(a+3, b+3, color2, c-3, b+3, color2, c-3, d-3, color2, a+3, d-3, color2, 11)
		@font.draw("Save map", a+9, b+6, 11, 1.0, 1.0, 0xff000000) 
		
		@font.draw("Load Map"	, 10, 280, 11, 1.0, 1.0, 0xffffffff)
		
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
			@font.draw("#{@saved[i].chop.chop.chop.chop}", save_a+6, save_b+3, 13, 1.0, 1.0, 0xff000000)
		end
		
		
		@font.draw("Map Size"	, 10, 600, 11, 1.0, 1.0, 0xffffffff)
		
		
		a = 10
		b = 624
		c = 50
		d = 644
		if point_in_rectangle(mouse_x, mouse_y, a, b, c, d)
			bgcol = 0xffdddd22
		else
			bgcol = 0xffcccccc
		end
		self.draw_quad(a, b, bgcol, c, b, bgcol, c, d, bgcol, a, d, bgcol, 11)
		if @cursor == "x_mapsize"
			@text_field2.draw
		else
			@font.draw("#{$worldsize_x_new}", a+6, b+3, 11, 1.0, 1.0, 0xff000000)
		end
		
		
		a = 60
		b = 624
		c = 100
		d = 644
		if point_in_rectangle(mouse_x, mouse_y, a, b, c, d)
			bgcol = 0xffdddd22
		else
			bgcol = 0xffcccccc
		end
		self.draw_quad(a, b, bgcol, c, b, bgcol, c, d, bgcol, a, d, bgcol, 11)
		if @cursor == "y_mapsize"
			@text_field3.draw
		else
			@font.draw("#{$worldsize_y_new}", a+6, b+3, 11, 1.0, 1.0, 0xff000000)
		end
		
		## New map button
		a = 10
		b = 658
		c = 90
		d = 681
		if point_in_rectangle(mouse_x, mouse_y, a, b, c, d)
			color2 = 0xffffff00
		else
			color2 = 0xffcccccc
		end
		self.draw_quad(a, b, color2, c, b, color2, c, d, color2, a, d, color2, 11)
		@font.draw("New map", a+7, b+3, 11, 1.0, 1.0, 0xff000000) 
		
	end
	
	def needs_cursor?
		true
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
	
	def get_x(tile_x)
		return tile_x * $tile_size
	end
	
	def get_y(tile_y)
		return tile_y * $tile_size
	end
	
	def get_tile_x(x)
		return (x/$tile_size).round
	end
	
	def get_tile_y(y)
		return (y/$tile_size).round
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
	
	def destroy_textflash(id)
		$textflash.delete(id)
	end
	
end

# show the window
window = GameWindow.new
window.show