extends Node2D

@onready var spawnpoint: Node2D = $Spawnpoint
@onready var spawnpoint_2: Node2D = $Spawnpoint2
@onready var spawnpoint_3: Node2D = $Spawnpoint3
@onready var spawnpoint_4: Node2D = $Spawnpoint4
@onready var spawnpoint_5: Node2D = $Spawnpoint5
@onready var spawnpoint_6: Node2D = $Spawnpoint6

@export var zombies: Array[PackedScene]

# Wave system variables
var current_wave: int = 0
var zombies_to_spawn: int = 0
var zombies_alive: int = 0
var wave_in_progress: bool = false
var spawn_timer: Timer
var zombies_per_wave_base: int = 10
var spawn_delay: float = 1.5  # Time between zombie spawns

# Zombie distribution per type per wave
var zombies_by_type = []

# Signals
signal wave_completed(wave_number)
signal wave_started(wave_number)

func _ready() -> void:
	# Initialize spawn timer
	spawn_timer = Timer.new()
	spawn_timer.wait_time = spawn_delay
	spawn_timer.one_shot = false
	spawn_timer.connect("timeout", Callable(self, "_on_spawn_timer_timeout"))
	add_child(spawn_timer)
	
	# Start the first wave after a short delay
	await get_tree().create_timer(2.0).timeout
	start_next_wave()

func _process(delta: float) -> void:
	# Check if wave is complete
	if wave_in_progress and zombies_alive <= 0 and zombies_to_spawn <= 0:
		end_wave()

func start_next_wave() -> void:
	$"../Player".play_start_bgm()
	#$"../Player/WaveEnded".stop()
	#$"../Player/WaveStart".play()
	current_wave += 1
	
	# Calculate zombies for this wave according to the specified distribution
	zombies_by_type = calculate_zombie_distribution(current_wave)
	
	# Calculate total zombies
	zombies_to_spawn = 0
	for type_count in zombies_by_type:
		zombies_to_spawn += type_count
	
	zombies_alive = zombies_to_spawn
	wave_in_progress = true
	
	print("Wave " + str(current_wave) + " started! Zombies: " + str(zombies_to_spawn))
	print("Distribution: " + str(zombies_by_type))
	emit_signal("wave_started", current_wave)
	
	# Start spawning zombies
	spawn_timer.start()

func calculate_zombie_distribution(wave_number: int) -> Array:
	var distribution = [0, 0, 0, 0]  # Initialize with 0 zombies of each type
	
	if wave_number == 1:
		# Wave 1: 10 zombies of type 0
		distribution[0] = 10
	elif wave_number == 2:
		# Wave 2: 10 zombies of type 0 + 5 zombies of type 1
		distribution[0] = 10
		distribution[1] = 5
	elif wave_number == 3:
		# Wave 3: 10 zombies of type 0 + 10 zombies of type 1 + 5 zombies of type 2
		distribution[0] = 10
		distribution[1] = 10
		distribution[2] = 5
	elif wave_number == 4:
		# Wave 4: 10 zombies of type 0 + 10 zombies of type 1 + 10 zombies of type 2 + 5 zombies of type 3
		distribution[0] = 10
		distribution[1] = 10
		distribution[2] = 10
		distribution[3] = 5
	elif wave_number == 5:
		# Wave 5: Slight increase in all types
		distribution[0] = 12
		distribution[1] = 12
		distribution[2] = 12
		distribution[3] = 8
	else:
		# Wave 6+: Balanced increase across all zombie types
		var wave_beyond_5 = wave_number - 5
		
		# Base values from wave 5
		distribution[0] = 12 + wave_beyond_5 * 2       # Type 0 zombies increase by 2 per wave
		distribution[1] = 12 + wave_beyond_5 * 3       # Type 1 zombies increase by 3 per wave
		distribution[2] = 12 + wave_beyond_5 * 4       # Type 2 zombies increase by 4 per wave
		distribution[3] = 8 + wave_beyond_5 * 5        # Type 3 zombies increase by 5 per wave
	
	return distribution

func _on_spawn_timer_timeout() -> void:
	if zombies_to_spawn <= 0:
		spawn_timer.stop()
		return
	
	spawn_zombie()

func spawn_zombie() -> void:
	if zombies_to_spawn <= 0:
		return
		
	zombies_to_spawn -= 1
	
	# Determine zombie type based on distribution
	var zombie_type = select_zombie_type_from_distribution()
	
	# Make sure we don't exceed available zombie types
	zombie_type = min(zombie_type, zombies.size() - 1)
	
	# Choose random spawn point
	var spawn_points = [spawnpoint, spawnpoint_2, spawnpoint_3, 
						spawnpoint_4, spawnpoint_5, spawnpoint_6]
	var selected_spawn = spawn_points[randi() % spawn_points.size()]
	
	# Create zombie
	var zombie = zombies[zombie_type].instantiate()
	zombie.position = selected_spawn.position
	
	# Connect death signal (adjust signal name if different)
	if zombie.has_signal("zombie_died"):
		zombie.connect("zombie_died", Callable(self, "_on_zombie_died"))
	
	# Add to scene
	get_parent().add_child(zombie)
	print("zombie spawned")

func select_zombie_type_from_distribution() -> int:
	# Find a non-zero zombie type to spawn
	var remaining_types = []
	for type in range(zombies_by_type.size()):
		if zombies_by_type[type] > 0:
			remaining_types.append(type)
	
	if remaining_types.size() == 0:
		return 0  # Default to type 0 if something went wrong
	
	# Choose a random type that still has zombies to spawn
	var selected_type = remaining_types[randi() % remaining_types.size()]
	zombies_by_type[selected_type] -= 1
	
	return selected_type

func _on_zombie_died() -> void:
	zombies_alive -= 1

func end_wave() -> void:
	$"../Player".play_end_bgm()
	
	wave_in_progress = false
	print("Wave " + str(current_wave) + " completed!")
	emit_signal("wave_completed", current_wave)
	
	# Start next wave after delay
	await get_tree().create_timer(6.0).timeout
	start_next_wave()
