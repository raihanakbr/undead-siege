extends Node2D

@export var upgrade: BaseBulletStrategy
@export var cost: int = 500
@export var icon: Texture

@onready var sprite: Sprite2D = $Sprite2D
@onready var prompt_label = $PromptLabel if has_node("PromptLabel") else null

var players_in_area = []

func _ready():
	# Initialize prompt label if it exists
	if prompt_label:
		prompt_label.text = "Upgrade: $" + str(cost)
		prompt_label.visible = false
		
	if icon:
		sprite.texture = icon
		

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		# Add player to tracking array
		if not body in players_in_area:
			players_in_area.append(body)
			
		# Connect to player's interact signal if available
		if body.has_signal("player_interact") and not body.is_connected("player_interact", _on_player_interact):
			body.player_interact.connect(_on_player_interact)
		
		# Show prompt if available
		if prompt_label:
			prompt_label.visible = true

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		# Remove player from tracking array
		if body in players_in_area:
			players_in_area.erase(body)
		
		# Disconnect from player's signal if connected
		if body.has_signal("player_interact") and body.is_connected("player_interact", _on_player_interact):
			body.player_interact.disconnect(_on_player_interact)
		
		# Hide prompt if no players in area
		if prompt_label and players_in_area.size() == 0:
			prompt_label.visible = false

# Handle player interaction
func _on_player_interact(player) -> void:
	# Check if player has Money node
	if not player.has_node("Money"):
		print("Player doesn't have a Money node")
		return
	
	# First check if player already has this upgrade using player's own method
	if player.has_upgrade(upgrade):
		_show_already_owned_effect()
		return
	
	var money_node = player.get_node("Money")
	
	# Check if player has enough money
	if money_node.get_amount() >= cost:
		# Subtract money from player
		if money_node.subtract(cost):
			# Apply the upgrade and check if it was successful
			if player.upgrade_current_weapon(upgrade):
				_show_success_effect()
			else:
				# If upgrade failed, refund the money
				money_node.add(cost)
				_show_upgrade_failed_effect()
	else:
		# Not enough money feedback
		_show_insufficient_funds_effect()

func _show_success_effect() -> void:
	# Optional: Add visual/audio feedback for successful purchase
	if prompt_label:
		var original_text = prompt_label.text
		var original_color = prompt_label.modulate
		
		prompt_label.text = "Upgraded!"
		prompt_label.modulate = Color(0.3, 1.0, 0.3) # Green
		
		# Reset after delay
		await get_tree().create_timer(1.0).timeout
		prompt_label.text = original_text
		prompt_label.modulate = original_color

func _show_insufficient_funds_effect() -> void:
	# Optional: Add visual/audio feedback for insufficient funds
	if prompt_label:
		var original_text = prompt_label.text
		var original_color = prompt_label.modulate
		
		prompt_label.text = "Not enough money!"
		prompt_label.modulate = Color(1.0, 0.3, 0.3) # Red
		
		# Reset after delay
		await get_tree().create_timer(1.0).timeout
		prompt_label.text = original_text
		prompt_label.modulate = original_color

func _show_already_owned_effect() -> void:
	# Visual feedback for already owned upgrade
	if prompt_label:
		var original_text = prompt_label.text
		var original_color = prompt_label.modulate
		
		prompt_label.text = "Upgrade already owned!"
		prompt_label.modulate = Color(0.5, 0.5, 1.0) # Blue
		
		# Reset after delay
		await get_tree().create_timer(1.0).timeout
		prompt_label.text = original_text
		prompt_label.modulate = original_color

func _show_upgrade_failed_effect() -> void:
	# Visual feedback for upgrade failure
	if prompt_label:
		var original_text = prompt_label.text
		var original_color = prompt_label.modulate
		
		prompt_label.text = "Cannot upgrade this weapon!"
		prompt_label.modulate = Color(1.0, 0.5, 0.2) # Orange
		
		# Reset after delay
		await get_tree().create_timer(1.0).timeout
		prompt_label.text = original_text
		prompt_label.modulate = original_color
