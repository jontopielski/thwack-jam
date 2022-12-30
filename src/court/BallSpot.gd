extends Node2D

export(Color) var in_bounds_color = Color.black
export(Color) var out_bounds_color = Color.black
export(Color) var spot_color = Color.black

func is_in_bounds():
	var bounds_rect = Rect2()
	bounds_rect.position = Vector2(12, 12)
	bounds_rect.size = Vector2(160, 160)
	return bounds_rect.encloses(Rect2(position, Vector2.ZERO))

func set_good_spot():
	spot_color = in_bounds_color
	update()

func set_bad_spot():
	spot_color = out_bounds_color
	update()

func _draw():
	draw_circle(Vector2.ZERO, 3, spot_color)

func clear_ball_spot():
	pass

func _on_Timer_timeout():
	queue_free()
