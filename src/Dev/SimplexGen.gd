tool

extends Sprite

export(bool) var dirty := false setget reload
export(bool) var generate_terrain := true
export(bool) var generate_border := true
export(bool) var generate_connections := true
export(bool) var smooth_connection_border := true

export(int) var size := 300
export(int) var octaves := 2
export(float) var persistance := 0.3
export(float) var period := 20.0
export(int) var border_size := 30
export(int) var border_tickness := 0.3
export(bool) var border_montains := true
export(int) var border_connection_size := 15

func reload(_value):
	var img = Image.new()
	img.create(size, size, false, Image.FORMAT_RGB8)
	
	if generate_terrain:
		generate_terrain(img)
	
	if generate_border:
		generate_border(img)
	
	if generate_connections:
		generate_connections(img)
	
	var texture = ImageTexture.new()
	texture.create_from_image(img)
	texture.flags = 0
	self.set_texture(texture)


func generate_terrain(img: Image) -> void:
	var noise = OpenSimplexNoise.new()
	
	noise.seed = randi()
	noise.octaves = octaves
	noise.period = period
	noise.persistence = persistance

	for x in range(img.get_size().x):
		for y in range(img.get_size().y):
			var h = (noise.get_noise_2d(x, y) + 1) / 2
			
			img.lock()
			img.set_pixel(x, y, Color(h, h, h))
			img.unlock()


func generate_border(img: Image) -> void:
	var border_left := border_size
	var border_up := border_size
	var border_right := img.get_size().x - border_size
	var border_down := img.get_size().y - border_size
	
	for x in range(img.get_size().x):
		for y in range(img.get_size().y):
			if x > border_left && x < border_right && y > border_up && y < border_down:
				continue
			
			var border_tickness_x := 0
			
			if x < border_left:
				border_tickness_x = border_left - x
			elif x > border_right:
				border_tickness_x = x - border_right
			
			var border_tickness_y := 0
			
			if y < border_up:
				border_tickness_y = border_up - y
			elif y > border_down:
				border_tickness_y = y - border_down
			
			img.lock()
			
			var h := img.get_pixel(x, y).r
			h += max(border_tickness_x, border_tickness_y) * (border_tickness * (1 if border_montains else -1))
			
			img.set_pixel(x, y, Color(h, h, h))
			img.unlock()


func generate_connections(img: Image) -> void:
	var connection_count = randi() % 3 + 1
	
	create_connection(40, 0, img)
	
	pass
	
func create_connection(connection_x: int, connection_y: int, img: Image) -> void:
	var rect := Rect2(connection_x, connection_y, border_connection_size, border_connection_size)
	var img_rect = img.get_used_rect()
	
	if not img_rect.encloses(rect):
		return
	
	var border_tickness := int(float(border_connection_size) / 5.0)
	print(border_tickness)
	var border_rect = Rect2(connection_x - border_tickness, connection_y - border_tickness, 
	border_connection_size + (border_tickness * 2) - 1, 
	border_connection_size + (border_tickness * 2) - 1)
	
	for pixel_x in range(rect.position.x, rect.end.x):
		for pixel_y in range(rect.position.y, rect.end.y):
			var pixel_point = Vector2(pixel_x, pixel_y)
			
			if not img_rect.has_point(pixel_point):
				continue
			
			img.lock()
			var h := 0.5 #TODO Find a better way to place this const
			img.set_pixel(pixel_x, pixel_y, Color(h, h, h))
			img.unlock()

	if smooth_connection_border:
		var half_size = (border_rect.end - border_rect.position) / 2
		
		var point := Vector2(border_rect.position.x + int(half_size.x), border_rect.position.y + int(half_size.y))
		var count := 0
		var walk_left = 1
		var dirs := [Vector2(1,0), Vector2(0, 1), Vector2(-1, 0), Vector2(0, -1)]
		var dir_cnt := 0
		var dir: Vector2 = dirs[dir_cnt]
		var dir_mod := 0
		
		while border_rect.has_point(point):
			if img_rect.has_point(point) && not rect.has_point(point):
				smooth_pixel(point.x, point.y, img, rect)
			
			count += 1
			walk_left -= 1
			
			if walk_left <= 0:
				dir_mod += 1
				dir = dirs[dir_mod % 4]
				
				dir_cnt += (1 if dir_mod % 2 == 1 else 0)
				walk_left = dir_cnt
			
			point += dir


func smooth_pixel(x: int, y: int, img: Image, rect: Rect2) -> void:
	var img_rect = img.get_used_rect()
	var h := 0.0
	var count := 0
	
	img.lock()
	
	for i in range (-1, 2):
		for k in range (-1, 2):
			var point = Vector2(x + i, y + k)
			
			if not img_rect.has_point(point):
				continue
	
			h += img.get_pixel(point.x, point.y).r
			count += 1
	
	
	
	img.set_pixel(x, y, Color(h / count, h / count, h / count))
	img.unlock()
