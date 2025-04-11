extends CanvasLayer

@onready var wave_value = %Value
@onready var zombies_killed_value = %Value
@onready var money_collected_value = %Value
@onready var animation_player = $AnimationPlayer

var game_manager: Node
var player: Node
var stats = {
	"wave": 1,
	"zombies_killed": 0,
	"money_collected": 0
}

func _ready() -> void:
	# Hide initially
	visible = false
	
	# Find references to needed nodes
	game_manager = get_node("/root/Game/GameManager") if has_node("/root/Game/GameManager") else null
	player = get_node("/root/Game/Player") if has_node("/root/Game/Player") else null
	
	# Connect to player's death signal
	if player and player.has_signal("death"):
		player.connect("death", _on_player_death)

func _on_player_death() -> void:
	# Get stats before showing death screen
	_gather_stats()
	
	# Show death screen and play animation
	visible = true
	animation_player.play("fade_in")
	
	# Pause the game
	get_tree().paused = true

func _gather_stats() -> void:
	if game_manager:
		stats.wave = game_manager.current_wave
		
		# You might have these values stored elsewhere
		# For now using placeholder data
		stats.zombies_killed = game_manager.zombies_killed if "zombies_killed" in game_manager else 0
	
	if player and player.has_node("Money"):
		stats.money_collected = player.get_node("Money").get_amount()
	
	# Update UI with collected stats
	wave_value.text = str(stats.wave)
	zombies_killed_value.text = str(stats.zombies_killed)
	money_collected_value.text = "$" + str(stats.money_collected)

func _on_restart_button_pressed() -> void:
	# Unpause game and reload current scene
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_quit_button_pressed() -> void:
	# Quit to main menu or exit game
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
	# Or quit the game entirely
	# get_tree().quit()
