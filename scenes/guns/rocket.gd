extends Node2D

const SPEED:int = 300

const EXPLOSIVE = preload("res://scenes/utils/explosive.tscn")

func _process(delta: float) -> void:
	position += transform.x * SPEED * delta

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()

func _on_hit_box_area_entered(area: Area2D) -> void:
	if area.get_parent().is_in_group("enemy"):
		var explosive_instance = EXPLOSIVE.instantiate()
		explosive_instance.scale = Vector2(3, 3)
		get_tree().root.add_child(explosive_instance)
		explosive_instance.global_position = global_position
		queue_free()
