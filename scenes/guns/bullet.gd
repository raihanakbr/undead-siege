class_name Bullet
extends Node2D

@onready var hitbox : HitBox = $HitBox
@onready var sprite : Sprite2D = $Sprite2D

@export var stats : BulletStats

var speed : int = 600
var piercing : int = 0
var bullet_damage : int = 1

func _ready() -> void:
	speed = stats.speed
	piercing = stats.piercing
	sprite.frame = stats.animation_frame
	bullet_damage = stats.bullet_damage

func _process(delta: float) -> void:
	position += transform.x * speed * delta

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()

func _on_hit_box_area_entered(area: Area2D) -> void:
	if area.get_parent().is_in_group("enemy"):
		if piercing > 0:
			piercing -= 1
		else:
			queue_free()
