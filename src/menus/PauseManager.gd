extends Node

func tiny_pause():
	get_tree().paused = true
	yield(get_tree().create_timer(0.05), "timeout")
	get_tree().paused = false

func tiny_pause_after_delay(delay):
	yield(get_tree().create_timer(delay), "timeout")
	tiny_pause()

func glitch_screen():
	pass
