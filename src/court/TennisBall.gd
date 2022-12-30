extends RigidBody2D

const BALL_HEIGHT = 20.0
const INITIAL_GRAVITY = 20

var MAX_HEIGHT = 25.0
var ACCELERATION = 60.0
var GRAVITY = 20.0
var height = 0.0

var has_ball_been_hit_before = false
var has_bounced_after_crossing = false
var has_hit_net = false
var has_given_score = false

var last_hit_by_player = false

export(Color) var ball_color = Color.green
export(Color) var line_color = Color.green
export(Color) var shadow_color = Color.green
export(Color) var secondary_color = Color.green

func _ready():
	hide()
	$Ball.play("default")
	get_tree().call_group("participants", "assign_target", self)
	yield(get_tree().create_timer(0.05), "timeout")
	show()

func is_in_bounds():
	var bounds_rect = Rect2()
	bounds_rect.position = Vector2(11, 11)
	bounds_rect.size = Vector2(162, 162)
	return bounds_rect.encloses(Rect2(position, Vector2.ZERO))

func _physics_process(delta):
	$Ball.position.y = height
	var speed_length = linear_velocity.length()
	if has_hit_net:
		if MAX_HEIGHT == 0.0:
			$Ball.speed_scale = 0.25
			$Ball.rotate(delta * speed_length / 300.0)
		else:
			$Ball.speed_scale = 0.5 + speed_length / 100.0
			$Ball.rotate(delta * speed_length / 150.0)
	else:
		if MAX_HEIGHT == 0.0:
			$Ball.speed_scale = 0.25
			$Ball.rotate(delta * speed_length / 300.0)
		else:
			$Ball.speed_scale = 1.0 + speed_length / 100.0
			$Ball.rotate(delta * speed_length / 50.0)
	update()
	scale = Vector2(.8 + (-height / 100.0), .8 + (-height / 100.0))
	if MAX_HEIGHT == 0.0:
		return
	height = min(0, lerp(height, height + GRAVITY * Globals.speed_boost * delta, (5 * (5 + ACCELERATION * (1.0 - (-height / max(0.01, MAX_HEIGHT))) * Globals.speed_boost)) * delta))
	$CollisionShape2D.position.y = height
	if height == 0:
		touched_ground()
		AudioManager.play_sfx("Bounce")
		set_gravity_up()
	if abs(height) >= MAX_HEIGHT and GRAVITY < 0 and !$Tween.is_active():
		set_gravity_down()
	if abs(height) < 3.5 and !get_collision_mask_bit(2):
		set_collision_mask_bit(2, true)
	elif abs(height) >= 3.5 and get_collision_mask_bit(2):
		set_collision_mask_bit(2, false)

func touched_ground():
	if !has_given_score and !has_bounced_after_crossing and !is_in_bounds() and has_ball_been_hit_before:
		if last_hit_by_player:
			get_tree().call_group("court", "enemy_scored")
			get_tree().call_group("court", "add_bad_ball_spot", position)
		else:
			get_tree().call_group("court", "player_scored")
			get_tree().call_group("court", "add_good_ball_spot", position)
		has_given_score = true
	elif has_bounced_after_crossing and !has_given_score and has_ball_been_hit_before:
		if position.y < 80:
			get_tree().call_group("court", "player_scored")
			get_tree().call_group("court", "add_good_ball_spot", position)
		elif position.y > 80:
			get_tree().call_group("court", "enemy_scored")
			get_tree().call_group("court", "add_bad_ball_spot", position)
		has_given_score = true
	has_bounced_after_crossing = true
	if !has_ball_been_hit_before:
		return
	MAX_HEIGHT -= 5.0
	if has_hit_net:
		MAX_HEIGHT -= 5.0
	MAX_HEIGHT = max(MAX_HEIGHT, 0.0)

func fade_away():
	if !has_given_score:
		return
	yield(get_tree().create_timer(0.5), "timeout")
	$AnimationPlayer.play("fade_out")
	yield($AnimationPlayer, "animation_finished")
	get_tree().call_group("ball_spots", "clear_ball_spot")
	queue_free()

func set_gravity_up():
	if GRAVITY > 0 and !$Tween.is_active():
		GRAVITY = -GRAVITY
#		$Tween.interpolate_property(self, "ACCELERATION", 45, 60, 0.1, Tween.TRANS_EXPO, Tween.EASE_IN_OUT)
#		$Tween.start()

func set_gravity_down():
	if GRAVITY < 0 and !$Tween.is_active():
		GRAVITY = -GRAVITY
#		$Tween.interpolate_property(self, "GRAVITY", GRAVITY, -GRAVITY, 0.1, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
#		$Tween.start()

func _integrate_forces(state):
	pass

func get_time_to_fall(height_distance):
	return height_distance / 10.0

func serve_ball_as_player(distance_from_center):
	hit_ball(Vector2(-.7, -1).normalized(), distance_from_center, true)

func serve_ball_as_enemy(distance_from_center):
	randomize()
	match Globals.current_enemy:
		"Duck":
			hit_ball(Vector2(rand_range(.6, .8), rand_range(.7, 1)).normalized(), distance_from_center, false)
		"Slime":
			hit_ball(Vector2(rand_range(.4, .6), rand_range(.6, .8)).normalized(), distance_from_center, false)
		"Devil":
			hit_ball(Vector2(rand_range(.4, .8), rand_range(.7, 1)).normalized(), distance_from_center, false)

func hit_ball(direction, distance_from_center, hit_by_player = true):
	last_hit_by_player = hit_by_player
	AudioManager.play_sfx("BallHit")
	MAX_HEIGHT = 25.0
#	$Tween.stop_all()
	if !has_ball_been_hit_before: # Serve
		get_tree().call_group("court", "unpause_progress_tween")
		add_force(direction, direction * 1.0)
		var speed_bonus = 0.0
		if height < -20:
			speed_bonus = 3
		elif height < -17:
			speed_bonus = 2
		elif height < -14:
			speed_bonus = 1
		if !hit_by_player:
			speed_bonus = rand_range(-2, 2)
		apply_impulse(direction, direction * Globals.speed_boost * (rand_range(13, 15) + speed_bonus + (distance_from_center / 10.0)))
		has_ball_been_hit_before = true
		$JustHitBallUpTimer.start()
		height = -BALL_HEIGHT
		linear_damp = 1.33 + ((Globals.speed_boost - 1.0) * .25)
		set_gravity_up()
	else: # Regular hit
		var speed_bonus = 1.0
		add_force(direction, direction * 1.0)
		linear_damp = 1.33 + ((Globals.speed_boost - 1.0) * .25)
		apply_impulse(direction, speed_bonus * direction * Globals.speed_boost * (rand_range(14, 16) + (distance_from_center / 10.0)))
		if !has_bounced_after_crossing and abs(height) > 10.0:
			set_gravity_up()
		else:
			set_gravity_up()

func supercharge_ball():
	return

func reverse_ball():
	return
	hit_ball(linear_velocity.normalized().rotated(deg2rad(180)), 16, false)

func shoot_ball(direction):
	add_force(direction, direction * 1.0)
	apply_impulse(direction, direction * 60.0)
	height = -BALL_HEIGHT
	set_gravity_up()

func setup_serve():
	get_tree().call_group("court", "clear_fake_net")
	set_gravity_up()
	height = BALL_HEIGHT

func _draw():
	if $AnimationPlayer.is_playing():
		return
	var radius = 6
	draw_circle(Vector2(0, 0), radius - .5 + height / 15.0, shadow_color)
	return
	for i in range(0, 3):
		draw_circle(Vector2(0, height + (3 - i)), radius - (3 - i), ball_color if i % 2 == 0 else secondary_color)
	draw_circle(Vector2(0, height), radius, ball_color)
	for i in range(0, 3):
		draw_circle(Vector2(0, height + i), radius - i, ball_color if i % 2 == 0 else secondary_color)
#	draw_arc(Vector2(radius + 2, height), 6, deg2rad(-140), deg2rad(-220), 32, line_color, line_weight)
#	draw_arc(Vector2(-radius - 2, height), 6, deg2rad(320), deg2rad(400), 32, line_color, line_weight)

func _on_JustHitBallUpTimer_timeout():
	pass
