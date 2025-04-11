extends Node2D

@onready var anim_player = $AnimationPlayer

func _ready() -> void:
	anim_player.play("explode")
