extends Node2D

signal finished_scoring

const Target = preload("res://src/court/Target.tscn")
const BallSpot = preload("res://src/court/BallSpot.tscn")

const Slime = preload("res://src/enemies/Slime.tscn")
const Devil = preload("res://src/enemies/Devil.tscn")
const Duck = preload("res://src/enemies/Duck.tscn")

onready var player = find_node("Player")
onready var progress_bar = find_node("ProgressBar")
onready var progress_tween = find_node("ProgressTween")

export(bool) var disable_enemy = false
export(int) var wait_time = 10.0

var last_target = null
var follow_target = null

var player_score = 0
var enemy_score = 0

func _ready():
	spawn_enemy()
	follow_target = player
	$PlayerServeSpot.show_circle = true
	$EnemyServeSpot.show_circle = false
	AudioManager.play_song("Crowd")
	$FakeNet.hide()
	randomize()
	if $YSort/BallMachine.is_on:
		spawn_sign()
	if disable_enemy:
		$YSort/Enemy.queue_free()

func spawn_enemy():
	var next_enemy = null
	match Globals.current_enemy:
		"Slime":
			next_enemy = Slime.instance()
			$EnemyLimit.position.y += 6
		"Devil":
			next_enemy = Devil.instance()
			$EnemyLimit.position.y += 10
		"Duck":
			next_enemy = Duck.instance()
		_:
			next_enemy = Slime.instance()
			$EnemyLimit.position.y += 6
	next_enemy.position = $EnemySpawn.position
	$YSort.add_child(next_enemy)

func start_progress_tween():
	progress_tween.interpolate_property(progress_bar, "value", 100, 0, wait_time, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	progress_tween.start()

func unpause_progress_tween():
	if !progress_tween.is_active() and progress_bar.value == 100:
		start_progress_tween()
	progress_tween.set_active(true)

func pause_progress_tween():
	progress_tween.set_active(false)

func update_scores(did_player_score):
	follow_target = $ScoreLocation
	get_tree().call_group("player", "set_enemy_target_as_player")
	get_tree().call_group("enemy", "set_player_target_as_enemy")
	get_tree().call_group("enemy", "set_waiting_state")
	yield(get_tree().create_timer(1.0), "timeout")
	
	if player_score == 0:
		$Scores/PlayerScore.text = "00"
	elif player_score == 1:
		$Scores/PlayerScore.text = "15"
	elif player_score == 2:
		$Scores/PlayerScore.text = "30"
	elif player_score >= 4 and enemy_score <= 2:
		$Scores/PlayerScore.text = "50"
	else:
		$Scores/PlayerScore.text = "40"
	
	if enemy_score == 0:
		$Scores/EnemyScore.text = "00"
	elif enemy_score == 1:
		$Scores/EnemyScore.text = "15"
	elif enemy_score == 2:
		$Scores/EnemyScore.text = "30"
	elif enemy_score >= 4 and player_score <= 2:
		$Scores/EnemyScore.text = "50"
	else:
		$Scores/EnemyScore.text = "40"
	
	if player_score >= 3 and enemy_score >= 3:
		if player_score == enemy_score + 1:
			$Scores/PlayerScore.text = "AD"
		elif enemy_score == player_score + 1:
			$Scores/EnemyScore.text = "AD"
		elif player_score == enemy_score + 2:
			$Scores/PlayerScore.text = "50"
		elif enemy_score == player_score + 2:
			$Scores/EnemyScore.text = "50"
	
	var score_ref = $Scores/PlayerScore
	if did_player_score:
		score_ref = $Scores/PlayerScore
	else:
		score_ref = $Scores/EnemyScore
	
	var score_text = score_ref.text
	score_ref.text = ""
	for i in range(0, 7):
		yield(get_tree().create_timer(0.05), "timeout")
		score_ref.text = score_text if score_ref.text == "" else ""
		if score_ref.text != "":
			AudioManager.play_sfx("ScoreBeep")

	yield(get_tree().create_timer(1.0), "timeout")
	
	if (player_score + enemy_score) % 2 == 1:
		get_tree().call_group("enemy", "assign_target_as_enemy")
	else:
		get_tree().call_group("player", "assign_target_as_player")
	
	if $Scores/EnemyScore.text == "50":
		AudioManager.play_sfx("PlayerLost")
		get_tree().call_group("participants", "enemy_won")
		get_tree().call_group("enemy", "set_waiting_state")
		get_tree().call_group("player", "assign_target_as_player")
		$EndGameTimer.start()
	elif $Scores/PlayerScore.text == "50":
		AudioManager.play_sfx("PlayerWon")
		get_tree().call_group("participants", "player_won")
		get_tree().call_group("enemy", "set_waiting_state")
		get_tree().call_group("player", "assign_target_as_player")
		$EndGameTimer.start()
	else:
		emit_signal("finished_scoring")

func assign_target(target):
	follow_target = target

var degree_offset = -90
func _process(delta):
	var object_following_weight = 4.0
	if "Player" in follow_target.name:
		degree_offset = -90
	if "Enemy" in follow_target.name:
		degree_offset = 90
		object_following_weight = 4.0
	if "Score" in follow_target.name or "Center" in follow_target.name:
		degree_offset = 0
		object_following_weight = 4.0
	var target_center_offset = follow_target.position - Vector2(92, 84)
	var target_offset_reduced = target_center_offset / object_following_weight
	$Camera2D.position = Vector2(92, 84) + target_offset_reduced
	Globals.camera_rotation = (target_offset_reduced.angle() + deg2rad(degree_offset)) / 4.0
	$Camera2D.rotation = Globals.camera_rotation
	if Input.is_action_just_pressed("ui_escape"):
		AudioManager.play_sfx("PlayerLost")
		TransitionScreen.transition_to(Globals.MainMenu)

func enemy_scored():
	AudioManager.play_sfx("EnemyScored")
	pause_progress_tween()
	enemy_score += 1
	yield(get_tree().create_timer(1.0), "timeout")
	update_scores(false)
	yield(self, "finished_scoring")
#	print("Enemy scored!")
#	show_current_score()
	get_tree().call_group("ball_spots", "clear_ball_spot")
	get_tree().call_group("balls", "fade_away")
	if (player_score + enemy_score) % 2 == 1:
		get_tree().call_group("enemy", "walk_to_serve", $EnemyServeSpot)
		yield(get_tree().create_timer(1.0), "timeout")
		$EnemyServeSpot.set_show_circle(true)
	else:
		get_tree().call_group("enemy", "wait_for_serve")
		yield(get_tree().create_timer(2.0 - min(0.5, abs(Globals.speed_boost - 1.0))), "timeout")
		$PlayerServeSpot.set_show_circle(true)

func player_scored():
	AudioManager.play_sfx("PlayerScored")
	pause_progress_tween()
	player_score += 1
	yield(get_tree().create_timer(1.0), "timeout")
	update_scores(true)
	yield(self, "finished_scoring")
#	print("Player scored!")
#	show_current_score()
	get_tree().call_group("ball_spots", "clear_ball_spot")
	get_tree().call_group("balls", "fade_away")
	if (player_score + enemy_score) % 2 == 1:
		get_tree().call_group("enemy", "walk_to_serve", $EnemyServeSpot)
		yield(get_tree().create_timer(1.0), "timeout")
		$EnemyServeSpot.set_show_circle(true)
	else:
		get_tree().call_group("enemy", "wait_for_serve")
		yield(get_tree().create_timer(2.5), "timeout")
		$PlayerServeSpot.set_show_circle(true)

func show_current_score():
	print("Player: %d" % player_score)
	print("Enemy: %d" % enemy_score)

func add_ball_spot(global_pos):
	if Rect2($Bounds.rect_position, $Bounds.rect_size).encloses(Rect2(global_pos, Vector2.ZERO)):
		return
	get_tree().call_group("ball_spots", "clear_ball_spot")
	var next_ball_spot = BallSpot.instance()
	$BallSpots.add_child(next_ball_spot)
	next_ball_spot.position = global_pos
	next_ball_spot.update()

func add_good_ball_spot(global_pos):
	var next_ball_spot = BallSpot.instance()
	$BallSpots.add_child(next_ball_spot)
	next_ball_spot.position = global_pos
	next_ball_spot.set_good_spot()

func add_bad_ball_spot(global_pos):
	var next_ball_spot = BallSpot.instance()
	$BallSpots.add_child(next_ball_spot)
	next_ball_spot.position = global_pos
	next_ball_spot.set_bad_spot()

func spawn_sign():
	var next_sign = Target.instance()
	var next_position = $TargetPoints.get_child(randi() % $TargetPoints.get_child_count())
	while next_position == last_target:
		next_position = $TargetPoints.get_child(randi() % $TargetPoints.get_child_count())
	last_target = next_position
	$YSort.add_child(next_sign)
	next_sign.position = next_position.position

func _on_BallBounds_body_entered(body):
	if "TennisBall" in body.name:
		if !body.has_given_score:
#			print("Ball went out of bounds!")
			if body.last_hit_by_player:
				if body.has_bounced_after_crossing:
					player_scored()
				else:
					enemy_scored()
			else:
				if body.has_bounced_after_crossing:
					enemy_scored()
				else:
					player_scored()
			body.has_given_score = true
		body.queue_free()

func _on_BallNet_body_entered(body: RigidBody2D):
	return
	if "TennisBall" in body.name:
		if !body.has_hit_net and !body.has_given_score:
			body.has_given_score = true
			body.has_hit_net = true
			body.linear_damp = 1000.0
#			print("Ball hit net!")
			if body.last_hit_by_player:
				body.z_index = 1
#				body.apply_central_impulse(Vector2.DOWN * 5)
#				body.add_central_force(Vector2.DOWN * 30)
				get_tree().call_group("court", "add_bad_ball_spot", body.position)
				enemy_scored()
			else:
				$FakeNet.show()
				body.add_central_force(Vector2.UP * 10)
				body.apply_central_impulse(Vector2.UP * 15)
				get_tree().call_group("court", "add_good_ball_spot", body.position)
				player_scored()

func clear_fake_net():
	if $FakeNet.visible:
		$FakeNet.hide()

func _on_NetCrossing_body_entered(body):
	if "TennisBall" in body.name and !body.has_given_score:
		body.has_bounced_after_crossing = false
#		print("Crossed net!")
		get_tree().call_group("enemy", "ball_crossed_net")
		if $FakeNet.visible:
			$FakeNet.hide()

func _on_PlayerBallNet_body_entered(body):
	if "TennisBall" in body.name and body.last_hit_by_player:
		if !body.has_hit_net and !body.has_given_score:
			body.has_given_score = true
			body.has_hit_net = true
			body.linear_damp = 1000.0
#			print("Ball hit net!")
			if body.last_hit_by_player:
				body.z_index = 1
#				body.apply_central_impulse(Vector2.DOWN * 5)
#				body.add_central_force(Vector2.DOWN * 30)
				get_tree().call_group("court", "add_bad_ball_spot", body.position)
				enemy_scored()
			else:
				$FakeNet.show()
				body.add_central_force(Vector2.UP * 10)
				body.apply_central_impulse(Vector2.UP * 15)
				get_tree().call_group("court", "add_good_ball_spot", body.position)
				player_scored()

func _on_EnemyBallNet_body_entered(body):
	if "TennisBall" in body.name and !body.last_hit_by_player:
		if !body.has_hit_net and !body.has_given_score:
			body.has_given_score = true
			body.has_hit_net = true
			body.linear_damp = 1000.0
			if body.last_hit_by_player:
				body.z_index = 1
#				body.apply_central_impulse(Vector2.DOWN * 5)
#				body.add_central_force(Vector2.DOWN * 30)
				get_tree().call_group("court", "add_bad_ball_spot", body.position)
				enemy_scored()
			else:
				$FakeNet.show()
				body.add_central_force(Vector2.UP * 10)
				body.apply_central_impulse(Vector2.UP * 15)
				get_tree().call_group("court", "add_good_ball_spot", body.position)
				player_scored()

func _on_ProgressTween_tween_all_completed():
	get_tree().call_group("balls", "supercharge_ball")
#	PauseManager.glitch_screen()
	$AnimationPlayer.play("speed_up")
	AudioManager.play_sfx("SpeedUp")
	Globals.speed_boost += .05
#	Engine.time_scale += .1
#	Globals.activate_curse("InvertXY")
	start_progress_tween()

func _on_EndGameTimer_timeout():
	TransitionScreen.transition_to(Globals.MainMenu)
#	get_tree().change_scene_to(Globals.MainMenu)
