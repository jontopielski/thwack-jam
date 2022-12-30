extends Control

func _ready():
	Globals.speed_boost = 1.0
	AudioManager.stop_all_songs()
	$Options/Slime.grab_focus()

func _on_Slime_pressed():
	Globals.current_enemy = "Slime"
	TransitionScreen.transition_to(Globals.Court)
#	get_tree().change_scene_to(Globals.Court)
	AudioManager.play_sfx("EnterMatch")

func _on_Slime_focus_entered():
	if $InitialBeepTimer.is_stopped():
		AudioManager.play_sfx("ChangeOptions")

func _on_Devil_focus_entered():
	AudioManager.play_sfx("ChangeOptions")

func _on_Devil_pressed():
	Globals.current_enemy = "Devil"
	TransitionScreen.transition_to(Globals.Court)
#	get_tree().change_scene_to(Globals.Court)
	AudioManager.play_sfx("EnterMatch")

func _on_Duck_focus_entered():
	AudioManager.play_sfx("ChangeOptions")


func _on_Duck_pressed():
	Globals.current_enemy = "Duck"
	TransitionScreen.transition_to(Globals.Court)
#	get_tree().change_scene_to(Globals.Court)
	AudioManager.play_sfx("EnterMatch")
