extends Node

signal curse_activated(curse_name)

const Court = preload("res://src/court/Court.tscn")
const MainMenu = preload("res://src/menus/MainMenu.tscn")

var camera_rotation = 0.0
var delta_sum = 0.0

var active_curses = []
var speed_boost = 1.0

var current_enemy = ""

func is_curse_active(curse_name):
	return curse_name in active_curses

func activate_curse(curse_name):
	active_curses.push_back(curse_name)
	emit_signal("curse_activated", curse_name)

func _process(delta):
	if OS.is_debug_build() and Input.is_action_just_pressed("ui_reset"):
		var current_scene_path = get_tree().current_scene.filename
		get_tree().change_scene(current_scene_path)
	if Input.is_action_just_pressed("ui_screenshot") and OS.is_debug_build():
		var image = get_viewport().get_texture().get_data()
		image.flip_y()
		image.save_png("C:\\Users\\jonto\\Desktop\\Game_Screenshot_%s.png" % str(randi() % 1000))
