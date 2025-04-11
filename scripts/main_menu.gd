extends Control

var loading_screen_scene = preload("res://scenes/ui/loading_screen.tscn")
var loading_screen = null

func _ready():
	# Set up initial focus for gamepad/keyboard navigation
	$MenuPanel/MarginContainer/MenuButtons/PlayButton.grab_focus()

func _on_play_button_pressed():
	# Create loading screen instance
	loading_screen = loading_screen_scene.instantiate()
	add_child(loading_screen)
	
	# Start loading the game scene
	loading_screen.load_scene("res://scenes/game.tscn")

func _on_credits_button_pressed():
	# Implement credits screen or placeholder
	print("Credits screen - to be implemented")

func _on_quit_button_pressed():
	get_tree().quit()
