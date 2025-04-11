extends CanvasLayer

@onready var wave_label = %WaveLabel
@onready var zombie_count_label = %ZombieCountLabel
@onready var preparation_panel = %PreparationPanel
@onready var countdown_label = %CountdownLabel
@onready var progress_bar = %ProgressBar
@onready var wave_banner = %WaveBanner
@onready var money_label = %MoneyLabel

var game_manager: Node
var player: Node
var preparation_time: float = 6.0
var current_countdown: float = 0.0
var preparation_active: bool = false
var next_wave: int = 0

func _ready() -> void:
	# Find the game manager in the scene
	game_manager = get_node("/root/Game/GameManager")
	if game_manager:
		# Connect to signals
		game_manager.wave_started.connect(_on_wave_started)
		game_manager.wave_completed.connect(_on_wave_completed)
		
		# Initialize UI with current values
		_update_zombie_counter(game_manager.zombies_alive)
		_update_wave_label(game_manager.current_wave)
	else:
		push_error("UI Overlay: GameManager not found")
		
	# Get player reference and connect money signals
	player = get_node("/root/Game/Player")
	if player and player.has_node("Money"):
		var money_node = player.get_node("Money")
		money_node.money_changed.connect(_on_money_changed)
		# Initialize with current money amount
		_update_money_display(money_node.get_amount())
	else:
		push_error("UI Overlay: Player or Money node not found")

func _process(delta: float) -> void:
	# Update zombie counter if game is running
	if game_manager and game_manager.wave_in_progress:
		_update_zombie_counter(game_manager.zombies_alive)
	
	# Update countdown timer during preparation
	if preparation_active:
		current_countdown -= delta
		if current_countdown <= 0:
			preparation_active = false
			preparation_panel.visible = false
		else:
			countdown_label.text = str(ceil(current_countdown))
			progress_bar.value = current_countdown

func _on_wave_started(wave_number: int) -> void:
	# Update wave display
	_update_wave_label(wave_number)
	
	# Show wave started banner briefly
	var tween = create_tween()
	wave_banner.modulate = Color(1, 0, 0, 1)  # Red flash
	tween.tween_property(wave_banner, "modulate", Color(1, 1, 1, 1), 0.5)
	
	# Hide preparation panel
	preparation_active = false
	preparation_panel.visible = false

func _on_wave_completed(wave_number: int) -> void:
	# Show "Wave Complete" briefly
	wave_label.text = "WAVE " + str(wave_number) + " COMPLETE"
	
	# Start preparation countdown
	next_wave = wave_number + 1
	current_countdown = preparation_time
	preparation_panel.visible = true
	preparation_active = true
	
	# Update preparation panel text
	var prep_label = preparation_panel.get_node("MarginContainer/VBoxContainer/PrepLabel")
	prep_label.text = "PREPARE FOR WAVE " + str(next_wave)
	countdown_label.text = str(ceil(current_countdown))
	progress_bar.max_value = preparation_time
	progress_bar.value = preparation_time

func _on_money_changed(new_amount: int) -> void:
	_update_money_display(new_amount)

func _update_money_display(amount: int) -> void:
	money_label.text = "$" + str(amount)
	
	# Optional: Add animation for money changes
	var tween = create_tween()
	money_label.modulate = Color(1, 1, 0.5, 1)  # Bright yellow flash
	tween.tween_property(money_label, "modulate", Color(0.9, 0.9, 0.2, 1), 0.5)

func _update_zombie_counter(count: int) -> void:
	zombie_count_label.text = "ZOMBIES: " + str(count)
	
	# Make text red when few zombies remain
	if count <= 5 and count > 0:
		zombie_count_label.modulate = Color(1, 0.3, 0.3)
	else:
		zombie_count_label.modulate = Color(1, 1, 1)

func _update_wave_label(wave: int) -> void:
	wave_label.text = "WAVE " + str(wave)
