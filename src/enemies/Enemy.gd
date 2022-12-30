extends KinematicBody2D

const TennisBall = preload("res://src/court/TennisBall.tscn")

export var SPEED = 30.0
export(float) var WAITING_PERIOD_Y_LOWER_BOUND = 25
export(float) var WAITING_PERIOD_Y_UPPER_BOUND = 35
const STEP_DISTANCE = 10.0
const STEP_TIME = 0.25
const Y_OFFSET = 4

enum State {
	NONE,
	WAITING_FOR_SERVE,
	WAITING,
	WALK_TO_SERVE,
	SERVE,
	CHASING,
	PLAYING,
	SEEKING,
}

var last_input = Vector2.UP
var time_since_last_step = 0.0
var take_left_step = true
var left_step_offset = Vector2.UP
var right_step_offset = Vector2.UP
var current_rotation = 0.0
var next_rotation = 0.0
var rotation_speed = 10.0
var racquet_angle = -70
var target = null
var use_right_hand = false
var is_serve_hit = false

export(float) var wobble_offset = 0.0

export(Color) var leg_color = Color.green
export(Color) var shorts_color = Color.green
export(Color) var shoe_color = Color.green
export(Color) var head_color = Color.green
export(Color) var hands_color = Color.green
export(Color) var handle_color = Color.green
export(Color) var mesh_border_color = Color.green
export(Color) var white_color = Color.green
export(Color) var shadow_color = Color.green

export(float) var start_angle = 0
export(float) var rest_angle = -70
export(float) var right_end_angle = 130
export(float) var left_end_angle = -250

export(State) var current_state = State.WAITING

func _ready():
	change_state(current_state)
	left_step_offset = position + (last_input.normalized() * STEP_DISTANCE).rotated(deg2rad(15)) + Vector2(0, Y_OFFSET)
	right_step_offset = position + (last_input.normalized() * STEP_DISTANCE).rotated(deg2rad(-15)) + Vector2(0, Y_OFFSET)
	update()

func walk_to_serve(serve_spot):
	target = serve_spot
	move_target = serve_spot.position
	change_state(State.WALK_TO_SERVE)

func wait_for_serve():
	get_tree().call_group("player", "set_enemy_target_as_player")
	change_state(State.WAITING_FOR_SERVE)

func assign_target_as_enemy():
	get_tree().call_group("court", "assign_target", self)

func set_player_target_as_enemy():
	get_tree().call_group("player", "assign_target", self)

func start_serve():
	get_tree().call_group("court", "assign_target", self)
	yield(get_tree().create_timer(0.5), "timeout")
#	get_tree().call_group("player", "set_enemy_target_as_player")
	yield(get_tree().create_timer(0.5), "timeout")
	is_serve_hit = true
	setup_ball_serve()
	current_state = State.PLAYING
#	current_state = State.SERVE
#	show_icon($Icons/ServeIcon)

func player_won():
#	show_icon($Icons/SadIcon)
	turn_towards(Vector2(92, 200))

func enemy_won():
#	show_icon($Icons/HappyIcon)
	turn_towards(Vector2(92, 200))

func show_icon(icon_to_show):
	for icon in $Icons.get_children():
		if icon == icon_to_show:
			icon.show()
			icon.play()
		else:
			icon.hide()

func hide_icons():
	for icon in $Icons.get_children():
		icon.hide()

func setup_ball_serve():
	var next_tennis_ball = TennisBall.instance()
	get_parent().add_child(next_tennis_ball)
	next_tennis_ball.position = position + Vector2(-16, 0)
	next_tennis_ball.setup_serve()

func assign_target(new_target):
	target = new_target

func player_hit_ball():
	if current_state == State.WAITING or current_state == State.WAITING_FOR_SERVE:
		change_state(State.SEEKING)

func ball_crossed_net():
	if current_state == State.SEEKING:
		yield(get_tree().create_timer(rand_range(0.1, 0.25)), "timeout")
		change_state(State.CHASING)

func change_state(next_state):
	current_state = next_state
	match next_state:
		State.WALK_TO_SERVE:
			pass
		State.WAITING_FOR_SERVE:
			match Globals.current_enemy:
				"Slime":
					move_target = Vector2(rand_range(60, 65), rand_range(25, 35))
				"Duck":
					move_target = Vector2(rand_range(60, 65), rand_range(20, 30))
				"Devil":
					move_target = Vector2(rand_range(60, 65), rand_range(20, 25))
		State.WAITING:
			randomize()
			move_target = Vector2(rand_range(50, 130), rand_range(WAITING_PERIOD_Y_LOWER_BOUND, WAITING_PERIOD_Y_UPPER_BOUND))
		State.SERVE:
			pass
		State.SEEKING:
			pass
		State.CHASING:
			pass
		State.PLAYING:
			pass

var move_target = Vector2.ZERO
func _physics_process(delta):
	var input = Vector2.ZERO
	if is_instance_valid(target):
		turn_towards(target.position)
	match current_state:
		State.WALK_TO_SERVE:
			if position.distance_to(move_target) > 5:
				input = position.direction_to(move_target)
		State.WAITING_FOR_SERVE:
			if position.distance_to(move_target) > 5:
				input = position.direction_to(move_target)
		State.WAITING:
			if position.distance_to(move_target) > 5:
				input = position.direction_to(move_target)
		State.SEEKING:
			if is_instance_valid(target) and position.distance_to(target.position) > 5:
				input = Vector2(position.direction_to(target.position).x, 0)
		State.CHASING:
			if is_instance_valid(target) and position.distance_to(target.position) > 5:
				input = position.direction_to(target.position)
		State.SERVE:
			pass
		State.PLAYING:
			pass
	if input != Vector2.ZERO and current_state != State.SERVE:
		if input.length() > .01:
			var speed_bonus = 1.0
			if current_state == State.WAITING_FOR_SERVE:
				speed_bonus = 1.1
			move_and_slide(input.normalized() * SPEED * speed_bonus * Globals.speed_boost)
	current_rotation = lerp(current_rotation, next_rotation, rotation_speed * delta)
	if $AdjustTween.is_active():
		update()
	$Body.set_sprite_rotation(current_rotation)
	if !$Tween.is_active():
		adjust_hand_side_if_necessary()
	
	update()
	if input != Vector2.ZERO or abs(next_rotation - current_rotation) > .1 or $Tween.is_active():
		$AnimationPlayer.play("wobble")
	
	if input != Vector2.ZERO:
		last_input = input.normalized()
#		$Body.set_sprite_rotation(last_input.angle() + deg2rad(90))
		time_since_last_step += delta
		if time_since_last_step > STEP_TIME:
			AudioManager.play_sfx("EnemyTakeStep")
			time_since_last_step = 0.0
			if take_left_step:
				left_step_input = last_input
				left_step_offset = position + (input.normalized() * STEP_DISTANCE).rotated(deg2rad(15)) + Vector2(0, Y_OFFSET)
			else:
				right_step_input = last_input
				right_step_offset = position + (input.normalized() * STEP_DISTANCE).rotated(deg2rad(-15)) + Vector2(0, Y_OFFSET)
			take_left_step = !take_left_step
	else:
		$AnimationPlayer.stop()

func turn_towards(global_pos):
	next_rotation = global_position.angle_to_point(global_pos) + deg2rad(90)
	if abs(rad2deg(next_rotation) - rad2deg(current_rotation)) > 180.0:
		if next_rotation > current_rotation:
			next_rotation -= deg2rad(360.0)
		else:
			next_rotation += deg2rad(360.0)
	var rotation_distance = abs(rad2deg(next_rotation) - rad2deg(current_rotation))
	rotation_speed = max(5.0, rotation_distance / 5)
	last_input = Vector2.ZERO

var left_step_input = Vector2.UP
var right_step_input = Vector2.UP
func _draw():
	draw_shadows()
	
	var left_starting_position = last_input.rotated(deg2rad(90)) * 4
	var left_ending_position = -position + left_step_offset
	var left_distance = left_starting_position.distance_to(left_ending_position)
	var left_halfway_position = left_starting_position + left_starting_position.direction_to(left_ending_position) * (left_distance / 2.0)
	var right_starting_position = last_input.rotated(deg2rad(-90)) * 4
	var right_ending_position = -position + right_step_offset
	var right_distance = right_starting_position.distance_to(right_ending_position)
	var right_halfway_position = right_starting_position + right_starting_position.direction_to(right_ending_position) * (right_distance / 2.0)

	draw_shoe(left_ending_position, left_step_input)
	draw_shoe(right_ending_position, right_step_input)
	
	draw_line(left_starting_position, left_ending_position, leg_color, 3)
	draw_line(right_starting_position, right_ending_position, leg_color, 3)
	
	var current_point = left_starting_position
	while current_point.distance_to(left_ending_position) > 2.0:
		draw_circle(current_point, 1.5, leg_color)
		current_point += left_starting_position.direction_to(left_ending_position) * 1.5
	draw_circle(left_ending_position, 1.0, leg_color)
	current_point = right_starting_position
	while current_point.distance_to(right_ending_position) > 2.0:
		draw_circle(current_point, 1.5, leg_color)
		current_point += right_starting_position.direction_to(right_ending_position) * 1.5
	draw_circle(right_ending_position, 1.0, leg_color)
	
	draw_hands()

func draw_shadows():
	draw_circle(Vector2(0, 4), 7, shadow_color)
	
	# Shoes
	var left_starting_position = last_input.rotated(deg2rad(90)) * 4
	var right_starting_position = last_input.rotated(deg2rad(-90)) * 4
	var left_ending_position = -position + left_step_offset
	var right_ending_position = -position + right_step_offset
	draw_circle(left_ending_position + Vector2(0, 2), 3.5, shadow_color)
	draw_circle(left_ending_position + Vector2(0, 2) + left_step_input * 2, 3.5, shadow_color)
	draw_circle(left_ending_position + Vector2(0, 2) + left_step_input * 4, 3.5, shadow_color)
	
	draw_circle(right_ending_position + Vector2(0, 2), 3.5, shadow_color)
	draw_circle(right_ending_position + Vector2(0, 2) + right_step_input * 2, 3.5, shadow_color)
	draw_circle(right_ending_position + Vector2(0, 2) + right_step_input * 4, 3.5, shadow_color)
	
	draw_line(left_starting_position + Vector2(0, 6), left_ending_position, shadow_color, 3)
	draw_line(right_starting_position + Vector2(0, 6), right_ending_position, shadow_color, 3)
	
	var rotation_vector = Vector2.ZERO
	if use_right_hand:
		rotation_vector = Vector2(cos(current_rotation + deg2rad(90)), sin(current_rotation + deg2rad(90)))
	else:
		rotation_vector = Vector2(cos(current_rotation + deg2rad(-90)), sin(current_rotation + deg2rad(-90)))
	var hand_position = (rotation_vector * (10 + wobble_offset)).rotated(deg2rad(racquet_angle))
	draw_circle(hand_position + Vector2(0, 6), 2.5, shadow_color)
	
	var handle_direction = rotation_vector.rotated(deg2rad(racquet_angle))
	var handle_end_point = handle_direction * 14
	var divider_end_point = handle_direction.rotated(deg2rad(10)) * 20
	var divider_end_point_2 = handle_direction.rotated(deg2rad(-10)) * 20
	var mesh_center_position = handle_direction * 24
	var radius = 6
	
	draw_line(hand_position + Vector2(0, 6), handle_end_point + Vector2(0, 6), shadow_color, 2)
	draw_line(handle_end_point + Vector2(0, 6), divider_end_point + Vector2(0, 6), shadow_color, 1.0)
	draw_line(handle_end_point + Vector2(0, 6), divider_end_point_2 + Vector2(0, 6), shadow_color, 1.0)
	draw_arc(mesh_center_position + Vector2(0, 6), radius, 0, 180, 32, shadow_color, 1.0)
	
	for i in range(0, 220, 30):
		var line_weight = 0.1
		var mesh_radius = radius - .5
		var starting_position = Vector2(sin(deg2rad(i)), cos(deg2rad(i)))
		var ending_position = starting_position.reflect(Vector2.LEFT)
		var ending_position_2 = starting_position.reflect(Vector2.DOWN)
		draw_line(mesh_center_position + starting_position * mesh_radius + Vector2(0, 6), mesh_center_position + Vector2(0, 6) + ending_position * mesh_radius, shadow_color, line_weight)
		draw_line(mesh_center_position + starting_position * mesh_radius + Vector2(0, 6), mesh_center_position + Vector2(0, 6) + ending_position_2 * mesh_radius, shadow_color, line_weight)

func draw_hands():
	var rotation_vector = Vector2.ZERO
	if use_right_hand:
		rotation_vector = Vector2(cos(current_rotation + deg2rad(90)), sin(current_rotation + deg2rad(90)))
	else:
		rotation_vector = Vector2(cos(current_rotation + deg2rad(-90)), sin(current_rotation + deg2rad(-90)))
	var hand_position = (rotation_vector * (10 + wobble_offset)).rotated(deg2rad(racquet_angle))
	var hand_position_2 = (rotation_vector * (8 + wobble_offset)).rotated(deg2rad(racquet_angle))
	draw_circle(hand_position, 2.5, hands_color)
	
	var handle_direction = rotation_vector.rotated(deg2rad(racquet_angle))
	var handle_end_point = handle_direction * 14
	draw_line(hand_position, handle_end_point, handle_color, 2)
	
	var divider_end_point = handle_direction.rotated(deg2rad(10)) * 20
	draw_line(handle_end_point, divider_end_point, mesh_border_color, 1.0)
	
	var divider_end_point_2 = handle_direction.rotated(deg2rad(-10)) * 20
	draw_line(handle_end_point, divider_end_point_2, mesh_border_color, 1.0)
	
	var mesh_center_position = handle_direction * 24
	var radius = 6
	
	for i in range(0, 370, 30):
		var line_weight = 0.1
		var mesh_radius = radius - .5
		var starting_position = Vector2(sin(deg2rad(i)), cos(deg2rad(i)))
		var ending_position = starting_position.reflect(Vector2.LEFT)
		var ending_position_2 = starting_position.reflect(Vector2.DOWN)
		draw_line(mesh_center_position + starting_position * mesh_radius, mesh_center_position + ending_position * mesh_radius, white_color, line_weight)
		draw_line(mesh_center_position + starting_position * mesh_radius, mesh_center_position + ending_position_2 * mesh_radius, white_color, line_weight)
#	draw_circle((rotation_vector * (10 + wobble_offset)).rotated(-80), 2.5, hands_color)
	draw_arc(mesh_center_position, radius, 0, 360, 32, mesh_border_color, 1.0)

func adjust_hand_side_if_necessary():
	if use_right_hand and (is_instance_valid(target) and (target.position.x < position.x and !$AdjustTween.is_active() and abs(target.position.x - position.x) > 1.0)):
		$AdjustTween.interpolate_property(self, "racquet_angle", racquet_angle, racquet_angle - 179, 0.2, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
		$AdjustTween.start()
		yield($AdjustTween, "tween_all_completed")
		racquet_angle = rest_angle
		use_right_hand = false
		update()
	elif !use_right_hand and (is_instance_valid(target) and (target.position.x > position.x and !$AdjustTween.is_active() and abs(target.position.x - position.x) > 1.0)):
		$AdjustTween.interpolate_property(self, "racquet_angle", racquet_angle, racquet_angle + 179, 0.2, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
		$AdjustTween.start()
		yield($AdjustTween, "tween_all_completed")
		racquet_angle = rest_angle
		use_right_hand = true
		update()

func draw_shoe(center_point, step_input):
	# Shoe Base
	draw_circle(center_point + Vector2(0, 1), 3, Color("#221d2e"))
	draw_circle(center_point + Vector2(0, 1) + step_input * 2, 3, Color("#221d2e"))
	draw_circle(center_point + Vector2(0, 1) + step_input * 4, 3, Color("#221d2e"))

	# Shoe
	draw_circle(center_point, 3, shoe_color)
	draw_circle(center_point + step_input * 2, 3, shoe_color)
	draw_circle(center_point + step_input * 4, 3, shoe_color)

	# Shoe Laces
	var lace_center = center_point + Vector2(0, 0) + step_input * 2
	for i in range(-1, 3, 2):
		lace_center = center_point + Vector2(0, 0) + step_input * (4 + i)
		draw_line(lace_center + step_input.rotated(deg2rad(90)) * 1.0, lace_center + step_input.rotated(deg2rad(90)) * -1.0, Color("#f0f0e4"))
	
	# Lining
	draw_circle(center_point + Vector2(0, -1), 2, Color("#f0f0e4"))

func _on_Tween_tween_all_completed():
	if racquet_angle == right_end_angle:
#		$RacquetArea/CollisionShape2D.set_deferred("disabled", true)
		$Tween.interpolate_property(self, "racquet_angle", racquet_angle, rest_angle, 0.5, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
		$Tween.start()
#		adjust_hand_side_if_necessary()
	elif racquet_angle == left_end_angle:
#		$RacquetArea/CollisionShape2D.set_deferred("disabled", true)
		$Tween.interpolate_property(self, "racquet_angle", racquet_angle, rest_angle, 0.5, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
		$Tween.start()
#		adjust_hand_side_if_necessary()

func set_waiting_state():
	change_state(State.WAITING)

func swing_racquet():
	change_state(State.WAITING)
	var is_adjusting = $AdjustTween.is_active()
	$AdjustTween.stop_all()
	$Tween.stop_all()
	if is_adjusting:
		use_right_hand = !use_right_hand
	if use_right_hand:
		$Tween.interpolate_property(self, "racquet_angle", rest_angle, right_end_angle, 0.25, Tween.TRANS_EXPO, Tween.EASE_IN_OUT)
	else:
		$Tween.interpolate_property(self, "racquet_angle", rest_angle, left_end_angle, 0.25, Tween.TRANS_EXPO, Tween.EASE_IN_OUT)
	$Tween.start()
	yield(get_tree().create_timer(.1), "timeout")
	$RacquetArea/CollisionShape2D.set_deferred("disabled", false)

var can_hit_ball = true
func _on_RacquetArea_body_entered(body):
	if "TennisBall" in body.name and can_hit_ball and !body.has_given_score and position.distance_to(body.position) < 50:
		can_hit_ball = false
		if is_serve_hit:
			yield(get_tree().create_timer(max(0.5, rand_range(0.9, 1.1) - abs(Globals.speed_boost - 1.0) * 1.25)), "timeout")
		swing_racquet()
		var angle_to_ball = position.angle_to_point(body.position)
		var ball_angle_degrees = rad2deg(angle_to_ball)
		var angle_to_hit = position.angle_to_point(body.position) + PI
		
		if body.position.x < position.x:
			angle_to_hit -= PI/2
		else:
			angle_to_hit += PI/2
		
#		print("I was struck at angle: %d" % ball_angle_degrees)
		var hit_vector = Vector2(cos(angle_to_hit), sin(angle_to_hit)).normalized()
		var division_factor = 1.0
		if ball_angle_degrees < -45 and ball_angle_degrees > -70:
			division_factor = 1.5
		if ball_angle_degrees < -110 and ball_angle_degrees > -135:
			division_factor = 1.5
		if ball_angle_degrees < -70 and ball_angle_degrees > -110:
			division_factor = 3.0
		
#		print("My division_factor is %d" % division_factor)
		yield(get_tree().create_timer(0.1), "timeout")
#		print("I shall fire the ball at the following vector!")
#		print((Vector2.DOWN + hit_vector / division_factor).normalized())
		if is_serve_hit:
			get_tree().call_group("player", "assign_target_as_player")
#			print("Serve hit!")
			body.serve_ball_as_enemy(position.distance_to(Vector2(92, 92)))
			is_serve_hit = false
		else:
#			print("Normal hit!")
#			print(position.distance_to(body.position))
			body.hit_ball((Vector2.DOWN + hit_vector / division_factor).normalized(), position.distance_to(Vector2(92, 92)), false)
		yield(get_tree().create_timer(0.5), "timeout")
		can_hit_ball = true
