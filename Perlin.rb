
class Perlin
	
	def initialize(window, size)
		
		@window, @size = window, size
		
		@gradients = []
		for i in 0..@size
			@gradients << []
			for e in 0..@size
				@gradients[i] << rand(360)
			end
		end
		
	end
	
	def perlin(x, y)
		
		##### IMPORTANT!
		##### The x and y values are between 0 and 1
		
		## Map the coordinates so it's within the noise grid (it prevents errors)
		x = x*@size % @size
		y = y*@size % @size
		
		## Find the grid that the coordinate lies upon
		grid_x = x.ceil
		grid_y = y.ceil
		
		## Find the 4 distance vectors
		vec_topleft = [x - (grid_x-1), y - (grid_y-1)]
		vec_topright = [x - grid_x, y - (grid_y-1)]
		vec_botleft = [x - (grid_x-1), y - grid_y]
		vec_botright = [x - grid_x, y - grid_y]
		
		## Find the 4 gradient vectors
		vec_grad_topleft = [Gosu::offset_x(@gradients[grid_x-1][grid_y-1], 1.0), Gosu::offset_y(@gradients[grid_x-1][grid_y-1], 1.0)]
		vec_grad_topright = [Gosu::offset_x(@gradients[grid_x][grid_y-1], 1.0), Gosu::offset_y(@gradients[grid_x][grid_y-1], 1.0)]
		vec_grad_botleft = [Gosu::offset_x(@gradients[grid_x-1][grid_y], 1.0), Gosu::offset_y(@gradients[grid_x-1][grid_y], 1.0)]
		vec_grad_botright = [Gosu::offset_x(@gradients[grid_x][grid_y], 1.0), Gosu::offset_y(@gradients[grid_x][grid_y], 1.0)]
		
		# p vec_topleft
		
		## Find the value from each 4 corner
		dot_topleft  = dot_product(vec_topleft[0],  vec_topleft[1],  vec_grad_topleft[0],  vec_grad_topleft[1])   ## Number between 0..1
		dot_topright = dot_product(vec_topright[0], vec_topright[1], vec_grad_topright[0], vec_grad_topright[1])  ## Number between 0..1
		dot_botleft  = dot_product(vec_botleft[0],  vec_botleft[1],  vec_grad_botleft[0],  vec_grad_botleft[1])   ## Number between 0..1
		dot_botright = dot_product(vec_botright[0], vec_botright[1], vec_grad_botright[0], vec_grad_botright[1])  ## Number between 0..1
		
		## Calculate the weighted average value from the 4 corner values. --------> THIS NUMBER GOES BETWEEN -1 and +1
		value = avg_influence(dot_topleft, dot_topright, dot_botleft, dot_botright, vec_topleft[0],  vec_topleft[1])
		
		return [[value/2.0 + 0.5, 0].max, 1].min   ## The valued returned will always be between 0 and 1
		
	end
	
	def avg_influence(g1, g2, g3, g4, x, y)
		### Calculates the average between values in 4 corners and a point in the unit square.
		### x and y should be coordinates between 0..1
		### g1 would be the value in the topleft corner
		### g2 would be the value in the topright corner
		### g3 would be the value in the botleft corner
		### g4 would be the value in the botright corner
		
		u = 6*(x**5) - 15*(x**4) + 10*(x**3)
		v = 6*(y**5) - 15*(y**4) + 10*(y**3)
		
		value_1 = lerp(g1, g2, u)
		value_2 = lerp(g3, g4, u)
		return lerp(value_1, value_2, v)
	end
	
	def lerp(a, b, x)
		### STANDS FOR LINEAR INTERPOLATION
		### It's a weighted average between a and b, where x is the weight.
		### if x = 0,   result = a
		### if x = 1,   result = b
		### if x = 0.5, result = (a+b)/2
		### You get the idea
		return (1-x)*a + x*b
	end
	
	def dot_product(x1, y1, x2, y2)
		return (x1*x2+y1*y2)
	end
	
	def draw
		
		line_color = 0x88ffffff
		
		totalsize = @size*$gridsize
		offset_x = $window_width/2 - totalsize/2
		offset_y = $window_height/2 - totalsize/2
		
		@window.draw_line(offset_x,      offset_y,      line_color, offset_x,      offset_y+totalsize, line_color, 0)
		@window.draw_line(offset_x,      offset_y,      line_color, offset_x+totalsize, offset_y,      line_color, 0)
		@window.draw_line(offset_x+totalsize, offset_y+totalsize, line_color, offset_x,      offset_y+totalsize, line_color, 0)
		@window.draw_line(offset_x+totalsize, offset_y+totalsize, line_color, offset_x+totalsize, offset_y,      line_color, 0)
		
		for i in 1..@size
			@window.draw_line(offset_x+i*$gridsize,      offset_y,      line_color, offset_x+i*$gridsize,      offset_y+totalsize, line_color, 0)
			@window.draw_line(offset_x,      offset_y+i*$gridsize,      line_color, offset_x+totalsize,      offset_y+i*$gridsize, line_color, 0)
		end
		
		
		for i in 0..@size
			for e in 0..@size
				px = offset_x+i*$gridsize
				py = offset_y+e*$gridsize
				
				pointx = px + Gosu::offset_x(@gradients[i][e], $gridsize)
				pointy = py + Gosu::offset_y(@gradients[i][e], $gridsize)
				
				@window.point_img.draw_rot(pointx, pointy, 0, 0, 0.5, 0.5, 0.8, 0.8, 0xffffffff)
				@window.draw_line(pointx, pointy, 0xffff0000, px, py, 0xffff0000, 0)
			end
		end
		
	end
	
end