extends CanvasLayer

var next_scene = null

func _ready():
	$Background.hide()

func transition_to(scene):
	$Background.show()
	get_tree().paused = true
	next_scene = scene
	$AnimationPlayer.play("fade_to_black")

func _on_AnimationPlayer_animation_finished(anim_name):
	match anim_name:
		"fade_to_black":
			get_tree().change_scene_to(next_scene)
			$AnimationPlayer.play("fade_to_normal")
		"fade_to_normal":
			$Background.hide()
			get_tree().paused = false
