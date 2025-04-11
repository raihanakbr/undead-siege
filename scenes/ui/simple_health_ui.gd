extends CanvasLayer

@onready var health_bar = %HealthBar

func _ready() -> void:
	# Find the player's health component
	await get_tree().process_frame
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var health_component = player.get_node("Health")
		if health_component:
			# Connect health signals
			health_component.health_changed.connect(_on_health_changed)
			health_component.max_health_changed.connect(_on_max_health_changed)
			
			# Initialize UI
			health_bar.max_value = health_component.max_health
			health_bar.value = health_component.health
		else:
			push_error("HealthUI: Player has no Health component")
	else:
		push_error("HealthUI: No player found")

func _on_health_changed(diff: int) -> void:
	var player = get_tree().get_first_node_in_group("player")
	var health_component = player.get_node("Health")
	health_bar.value = health_component.health
	
	# Color animation when taking damage
	if diff < 0:
		var tween = create_tween()
		tween.tween_property(health_bar, "modulate", Color(1, 0.5, 0.5), 0.1)
		tween.tween_property(health_bar, "modulate", Color(1, 1, 1), 0.2)

func _on_max_health_changed(diff: int) -> void:
	var player = get_tree().get_first_node_in_group("player")
	var health_component = player.get_node("Health")
	health_bar.max_value = health_component.max_health
