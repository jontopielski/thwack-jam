extends Area2D

export(Color) var circle_color = Color("#838a54")
export(bool) var show_circle = false setget set_show_circle

var circle_radius = 12
var starting_arc_angle = 0.0

func _ready():
	set_show_circle(show_circle)

func set_show_circle(value):
	show_circle = value
	if find_node("CollisionShape2D"):
		$CollisionShape2D.set_deferred("disabled", !show_circle)
		update()

func _process(delta):
	if show_circle:
		starting_arc_angle += delta * 125.0
		update()

func _draw():
	if !show_circle:
		return
	var degrees_per_arc = 30
	var space_between_arcs = 20
	var current_angle = starting_arc_angle
	var arc_width = 2.0
	while current_angle < 360.0 + starting_arc_angle:
		draw_arc(Vector2(0, 1), circle_radius, deg2rad(current_angle), deg2rad(current_angle + degrees_per_arc), 8, circle_color, arc_width)
		current_angle += degrees_per_arc + space_between_arcs

func _on_ServeSpot_body_entered(body):
	if show_circle and "Player" in body.name:
#		print("Collided with player")
		body.start_serve()
		set_show_circle(false)
	elif show_circle and "Enemy" in body.name:
#		print("Collided with enemy")
		body.start_serve()
		set_show_circle(false)

func _on_Timer_timeout():
	pass # Replace with function body.
