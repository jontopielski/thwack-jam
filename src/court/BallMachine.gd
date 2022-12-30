extends Node2D

const TennisBall = preload("res://src/court/TennisBall.tscn")

export(bool) var is_on = true

func _ready():
	if is_on:
		$Timer.start()
		yield(get_tree().create_timer(0.5), "timeout")
		shoot_ball()

func shoot_ball():
	var next_ball = TennisBall.instance()
	get_parent().add_child(next_ball)
	next_ball.position = position
	next_ball.shoot_ball(Vector2.DOWN.rotated(deg2rad(rand_range(-30, 30))))

func _on_Timer_timeout():
	shoot_ball()
