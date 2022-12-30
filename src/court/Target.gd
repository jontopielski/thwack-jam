extends Area2D

func _on_Target_body_entered(body):
	if "TennisBall" in body.name:
		get_tree().call_group("court", "spawn_sign")
		queue_free()
