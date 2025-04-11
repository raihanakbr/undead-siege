extends Node2D

signal item_selected(item_name, player)

@export var possible_items = ["pistol", "revolver", "rocket_launcher", "shotgun", "thompson"]
@export var randomize_duration = 2.0
@export var cost = 950  # Cost to use the mystery box

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var weapon_sprite: AnimatedSprite2D = $WeaponSprite
@onready var area_trigger: Area2D = $AreaTrigger
@onready var prompt_label = $PromptLabel if has_node("PromptLabel") else null

var is_randomizing = false
var selected_item = ""
var is_open = false
var players_in_area = []

func _ready():
	animated_sprite.play("closed")
	weapon_sprite.visible = false
	
	# Connect area detection signals
	area_trigger.connect("body_entered", _on_body_entered)
	area_trigger.connect("body_exited", _on_body_exited)
	
	# Initialize prompt label if it exists
	if prompt_label:
		prompt_label.text = "Mystery Box: $" + str(cost)
		prompt_label.visible = false

func _process(_delta):
	# Remove the direct input check from here
	pass
	
# Track players entering the area
func _on_body_entered(body):
	if body.is_in_group("player"):
		players_in_area.append(body)
		
		# Connect to player's signal if it exists and isn't already connected
		if body.has_signal("player_interact") and not body.is_connected("player_interact", _on_player_interact):
			body.player_interact.connect(_on_player_interact)
		
		# Show prompt if available
		if prompt_label:
			prompt_label.visible = true

# Remove players that leave the area
func _on_body_exited(body):
	if body.is_in_group("player"):
		players_in_area.erase(body)
		
		# Disconnect from player's signal if connected
		if body.has_signal("player_interact") and body.is_connected("player_interact", _on_player_interact):
			body.player_interact.disconnect(_on_player_interact)
		
		# Hide prompt if no players in area
		if prompt_label and players_in_area.size() == 0:
			prompt_label.visible = false

# Handle player interaction
func _on_player_interact(player):
	print("player interacted with mystereybox")
	if not is_randomizing:
		if is_open:
			# If box is open, give weapon to player and reset
			give_weapon_to_player(player)
		else:
			# Check if player has enough money before starting randomization
			if not player.has_node("Money"):
				print("Player doesn't have a Money node")
				return
				
			var money_node = player.get_node("Money")
			
			if money_node.get_amount() >= cost:
				# Subtract money from player
				print("hello")
				if money_node.subtract(cost):
					print("uhuh")
					# Start randomization
					start_randomizing(player)
					_show_success_effect()
			else:
				# Not enough money feedback
				_show_insufficient_funds_effect()

func start_randomizing(player):
	is_randomizing = true
	animated_sprite.play("randomizing")
	
	# Enable particle emission
	$RandomizingParticles.emitting = true
	
	# Start randomizing weapon display
	_start_weapon_randomizing()
	
	# Create a timer to stop randomizing after the specified duration
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = randomize_duration
	timer.one_shot = true
	timer.connect("timeout", _on_randomize_timeout.bind(player))
	timer.start()

# Visual feedback functions
func _show_success_effect() -> void:
	$Failed.play()
	if prompt_label:
		var original_text = prompt_label.text
		var original_color = prompt_label.modulate
		
		prompt_label.text = "Randomizing!"
		prompt_label.modulate = Color(0.3, 1.0, 0.3) # Green
		
		# Reset after delay
		await get_tree().create_timer(1.0).timeout
		prompt_label.text = original_text
		prompt_label.modulate = original_color

func _show_insufficient_funds_effect() -> void:
	$Failed.play()
	if prompt_label:
		var original_text = prompt_label.text
		var original_color = prompt_label.modulate
		
		prompt_label.text = "Not enough money!"
		prompt_label.modulate = Color(1.0, 0.3, 0.3) # Red
		
		# Reset after delay
		await get_tree().create_timer(1.0).timeout
		prompt_label.text = original_text
		prompt_label.modulate = original_color

# Randomly cycle through weapons during randomization
func _start_weapon_randomizing():
	weapon_sprite.visible = true
	var weapon_timer = Timer.new()
	add_child(weapon_timer)
	weapon_timer.wait_time = 0.15
	weapon_timer.connect("timeout", _change_random_weapon)
	weapon_timer.start()
	
	# Stop the timer when randomization ends
	await get_tree().create_timer(randomize_duration).timeout
	weapon_timer.stop()
	weapon_timer.queue_free()

func _change_random_weapon():
	var random_weapon = possible_items[randi() % possible_items.size()]
	weapon_sprite.animation = random_weapon
	weapon_sprite.frame = 6

func _on_randomize_timeout(player):
	is_randomizing = false
	is_open = true
	
	# Disable particle emission
	$RandomizingParticles.emitting = false
	
	# Select a random item
	selected_item = possible_items[randi() % possible_items.size()]
	
	# Play the open animation
	animated_sprite.play("open")
	animated_sprite.connect("animation_finished", _on_open_animation_finished.bind(player))
	
	# Show the final weapon
	weapon_sprite.play(selected_item)
	
	# Emit the signal with the selected item and player
	emit_signal("item_selected", selected_item, player)
	
func _on_open_animation_finished(player):
	if animated_sprite.animation == "open":
		animated_sprite.disconnect("animation_finished", _on_open_animation_finished)
		
		# Here you could spawn the actual item or show additional effects
		print("Selected item: ", selected_item, " for player: ", player.name)

# Instantiate and give weapon to player
func give_weapon_to_player(player):
	player.equip_weapon(selected_item)
	print("Gave " + selected_item + " to player: " + player.name)

	reset_box()

func reset_box():
	is_open = false
	selected_item = ""
	animated_sprite.play("closed")
	weapon_sprite.visible = false
