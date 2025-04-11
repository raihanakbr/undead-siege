extends Node2D

const BULLET: PackedScene = preload("res://scenes/guns/bullet.tscn")

enum FireMode {
	SINGLE,
	FULL_AUTO,
	SHOTGUN
}

@export var fire_mode: FireMode = FireMode.SINGLE
@export var reload_time: float = 1.5

@export var mag_size: int = 6       # Bullets per magazine
@export var max_ammo: int = 30       # Total extra ammo available
var current_mag: int = 0             # Bullets currently in magazine
var max_possible_ammo

@onready var muzzle = $Marker2D
@onready var anim_sprite = $AnimatedSprite2D

@export var x_cursor: int = 128
@export var bullet_stats: BulletStats

var upgrades : Array[BaseBulletStrategy] = []

var on_cooldown = false

signal reload_started
signal reload_completed

func _ready():
	current_mag = mag_size
	max_possible_ammo = max_ammo
	anim_sprite.play("default")
	_setup_cursor()
	
	# Add the gun to a group so the UI can find it
	add_to_group("player_gun")

func _setup_cursor() -> void:
	var cursor_sheet = preload("res://assets/SpriteSheets/Weapons sprites (32x32).png")
	var gun_cursor = AtlasTexture.new()
	gun_cursor.atlas = cursor_sheet
	gun_cursor.region = Rect2(x_cursor, 0, 32, 32)
	
	var image = gun_cursor.get_image()
	var new_size = image.get_size() * 1.5
	image.resize(int(new_size.x), int(new_size.y), Image.INTERPOLATE_NEAREST)
	
	var scaled_cursor = ImageTexture.create_from_image(image)
	Input.set_custom_mouse_cursor(scaled_cursor, Input.CURSOR_ARROW, Vector2(24, 24))

#func _exit_tree():
	#Input.set_custom_mouse_cursor(null)

func _process(delta: float) -> void:
	look_at(get_global_mouse_position())
	_update_rotation_and_scale()
	
	# Check for reload input (no reload animation)
	if Input.is_action_just_pressed("reload") and not on_cooldown:
		_handle_reload()
	
	var shoot_input: bool = false
	match fire_mode:
		FireMode.FULL_AUTO:
			shoot_input = Input.is_action_pressed("shoot")
		FireMode.SINGLE, FireMode.SHOTGUN:
			shoot_input = Input.is_action_just_pressed("shoot")
		
	# Only shoot if there's ammo in magazine.
	if shoot_input and not on_cooldown and current_mag > 0:
		_handle_shoot()
	# Optionally, auto-reload if trying to shoot with an empty magazine.
	elif shoot_input and current_mag <= 0 and max_ammo > 0 and not on_cooldown:
		_handle_reload()

func _update_rotation_and_scale() -> void:
	rotation_degrees = wrap(rotation_degrees, 0, 360)
	if (rotation_degrees > 90 and rotation_degrees < 270):
		scale.y = -1
	else:
		scale.y = 1

func _handle_shoot() -> void:
	$Shot.play()
	# Deduct one bullet from current magazine
	current_mag -= 1
	on_cooldown = true
	anim_sprite.play("shoot")
	
	if fire_mode == FireMode.SHOTGUN:
		var bullet_count = 5
		# Total spread in radians (e.g., 30° spread total)
		var total_spread = deg_to_rad(30)
		for i in range(bullet_count):
			var bullet_instance = BULLET.instantiate()
			bullet_instance.stats = bullet_stats
			bullet_instance.global_position = muzzle.global_position
			# Calculate offset for even spread
			var offset = total_spread * ((i / float(bullet_count - 1)) - 0.5)
			bullet_instance.rotation = rotation + offset
			get_tree().root.add_child(bullet_instance)
	else:
		var bullet_instance = BULLET.instantiate()
		bullet_instance.stats = bullet_stats
		bullet_instance.global_position = muzzle.global_position
		bullet_instance.rotation = rotation
		get_tree().root.add_child(bullet_instance)
		
		_apply_bullet_upgrades(bullet_instance)

func _apply_bullet_upgrades(bullet: Bullet) -> void:
	for strategy in upgrades:
		strategy.apply_upgrade(bullet)

func _handle_reload() -> void:
	print('reloading...')
	$Reload.play()
	on_cooldown = true
	emit_signal("reload_started")
	
	# Wait for the reload time using await.
	await get_tree().create_timer(reload_time).timeout
	
	# Calculate bullets needed to fill magazine.
	var needed = mag_size - current_mag
	# Take only as many as available in max_ammo.
	var reload_amount = min(needed, max_ammo)
	current_mag += reload_amount
	max_ammo -= reload_amount
	
	on_cooldown = false
	emit_signal("reload_completed")

func _on_animated_sprite_2d_animation_finished() -> void:
	# Resets after shooting animation. (Not used during reload.)
	anim_sprite.play("default")
	on_cooldown = false
