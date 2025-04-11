class_name HurtBox
extends Area2D

signal recieved_damage(damage: int)
signal knockback_applied(direction: Vector2, force: float)

@export var health: Health
@export var knockback_force: float = 250.0  # Adjust as needed

func _ready():
	connect("area_entered", _on_area_entered)

func _on_area_entered(hitbox: HitBox) -> void:
	if hitbox != null:
		print(hitbox.get_parent().name)
		health.health -= hitbox.damage
		if health.health > 0:
			recieved_damage.emit(hitbox.damage)
			
			# Calculate knockback direction from the hitbox to our parent
			var knockback_direction: Vector2
			if hitbox.global_position.distance_to(global_position) > 1.0:
				knockback_direction = (global_position - hitbox.global_position).normalized()
			else:
				# Fallback if positions are too close
				knockback_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
			
			# Emit knockback signal
			knockback_applied.emit(knockback_direction, knockback_force)
