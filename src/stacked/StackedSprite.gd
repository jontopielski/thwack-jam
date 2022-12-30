tool
extends Node2D

export(Texture) var texture = null setget set_texture
export(int) var hframes = 0 setget set_hframes
export(bool) var rotate_sprites = false setget set_rotate_sprites

var rotation_sum = 0

func set_texture(value):
	texture = value
	render_sprites()

func set_hframes(value):
	hframes = value
	render_sprites()

func set_rotate_sprites(value):
	rotate_sprites = value

func _process(delta):
	if rotate_sprites:
		rotation_sum += delta * 100.0
		set_sprite_rotation(deg2rad(rotation_sum))
	elif Globals:
		update_camera_rotation()

func update_camera_rotation():
	var up_vector = Vector2.DOWN
	if !Engine.editor_hint:
		up_vector = Vector2(cos(Globals.camera_rotation + PI/2), sin(Globals.camera_rotation + PI/2))
	for i in range(0, hframes):
		var next_sprite = get_child(i)
		next_sprite.position = -i * up_vector

func set_sprite_rotation(rot):
	for sprite in get_children():
		sprite.rotation = rot

func clear_sprites():
	var sprites = []
	for child in get_children():
		if child is Sprite:
			sprites.push_back(child)
	for sprite in sprites:
		sprite.queue_free()

func render_sprites():
	clear_sprites()
	for i in range(0, hframes):
		var next_sprite = Sprite.new()
		add_child(next_sprite)
		next_sprite.texture = texture
		next_sprite.hframes = hframes
		next_sprite.frame = i
		next_sprite.position.y = -i
