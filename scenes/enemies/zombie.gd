extends CharacterBody2D

@export var speed = 80.0
@export var max_ammo_drop_chance = 0.10  # 10% chance to drop max ammo

@onready var player = $"../Player"
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var health: Health = $Health
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var hitbox: HitBox = $HitBox

signal zombie_died

var can_see_player = false
var is_hurt = false

func _ready():
	if player == null:
		print("ERROR: Player not found! Make sure player is in the 'player' group.")
	
	anim.play("idle")

func _physics_process(delta):
	if player == null || is_hurt:
		return
	
	nav_agent.target_position = player.global_position
	
	var next_path_position = nav_agent.get_next_path_position()
	var direction = global_position.direction_to(next_path_position)
	var new_velocity = direction * speed
	
	anim.play("run")
	
	if direction.x != 0:
		anim_sprite.flip_h = (direction.x > 0)
	
	if nav_agent.avoidance_enabled:
		nav_agent.set_velocity(new_velocity)
	else:
		velocity = new_velocity
	
	move_and_slide()
	
func _on_hurt_box_recieved_damage(_damage: int) -> void:
	is_hurt = true
	print("zombie hurt")
	anim.play("hit")
	$AudioStreamPlayer2D.play()
	
func _on_finished_hurt_animation() -> void:
	is_hurt = false

func _on_navigation_agent_2d_velocity_computed(safe_velocity: Vector2) -> void:
	velocity = safe_velocity

func _on_health_health_depleted() -> void:
	is_hurt = true
	player.get_node("Money").transfer_from($Money)
	zombie_died.emit()
	
	# Check chance first before loading resource
	if randf() <= max_ammo_drop_chance:
		spawn_max_ammo()
	
	anim.play("death")
	hitbox.set_collision_layer_value(1, false)
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	
	$AudioStreamPlayer2D.play()

# Function to spawn max ammo power-up
func spawn_max_ammo() -> void:
	# Only load the scene when needed
	var max_ammo_scene = load("res://scenes/powerups/max_ammo.tscn")
	
	# Add the max ammo to the scene
	var max_ammo_instance = max_ammo_scene.instantiate()
	get_parent().add_child(max_ammo_instance)
	
	# Set position to zombie's position
	max_ammo_instance.global_position = global_position
