extends CharacterBody2D

signal player_interact(player: CharacterBody2D)
signal weapon_updated
signal death

const SPEED = 300.0

@onready var anim_sprite = $AnimatedSprite2D
@onready var weapon_holder = $WeaponHolder
@onready var health = $Health
@onready var hurtbox = $HurtBox
@onready var cheat_code_timer: Timer = $CheatCodeTimer

@export var weapon_scenes = {
	"pistol": preload("res://scenes/guns/pistol.tscn"),
	"revolver": preload("res://scenes/guns/revolver.tscn"),
	"rocket_launcher": preload("res://scenes/guns/rocket_launcher.tscn"),
	"shotgun": preload("res://scenes/guns/shotgun.tscn"),
	"thompson": preload("res://scenes/guns/thompson.tscn")
}

var is_hurt = false
var knockback_velocity = Vector2.ZERO
var is_dead = false
var current_gun

# Cheat code variables
var cheat_sequence = "12345"
var typed_sequence = ""

func _ready() -> void:
	hurtbox.connect("knockback_applied", _on_knockback_applied)
	anim_sprite.connect("animation_finished", _on_animated_sprite_2d_animation_finished)
	hurtbox.connect("recieved_damage", _on_hurt_box_recieved_damage)
	
	anim_sprite.play("default")
	
	current_gun = weapon_holder.get_child(0)
	# Connect to the knockback signal

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	# Apply knockback if there is any
	if knockback_velocity.length() > 0:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, delta * 1000)  # Decelerate knockback
		move_and_slide()
		return
	
	if is_hurt:
		return
		
	# Get input for 4-way movement
	var direction = Vector2.ZERO
	direction.x = Input.get_axis("left", "right")
	direction.y = Input.get_axis("up", "down")
	
	# Handle animations and facing
	if direction.length() > 0:
		# Character is moving, play run animation
		anim_sprite.play("run")
		
		# Handle facing direction
		if direction.x != 0:
			# If moving horizontally, flip sprite based on direction
			anim_sprite.flip_h = (direction.x > 0)
	else:
		# Character is idle, play default animation
		anim_sprite.play("default")
	
	# Normalize direction to prevent faster diagonal movement
	if direction.length() > 0:
		direction = direction.normalized()
		velocity = direction * SPEED
	else:
		# Deceleration when no input
		velocity = velocity.move_toward(Vector2.ZERO, SPEED)
	
	move_and_slide()

func _input(event):
	if event.is_action_pressed("interact"):
		print("interact")
		player_interact.emit(self)
	
	# Handle cheat code input
	if event is InputEventKey and event.pressed:
		var key_char = char(event.unicode)
		cheat_code_timer.start()
		
		# Process both numbers and letters
		if key_char.length() == 1 and (key_char >= "0" and key_char <= "9"):
			typed_sequence += key_char
			
			# Keep only the last characters up to cheat sequence length
			if typed_sequence.length() > cheat_sequence.length():
				typed_sequence = typed_sequence.substr(-cheat_sequence.length())
			
			# Check if cheat code was entered
			if typed_sequence == cheat_sequence:
				health.set_to_full_health()
				print("CHEAT ACTIVTED")
				typed_sequence = ""  # Reset sequence

func equip_weapon(weapon):
	
	# Now remove old weapons
	for child in weapon_holder.get_children():
		child.queue_free()
	
	# Instantiate new weapon
	var weapon_instance = weapon_scenes[weapon].instantiate()
	current_gun = weapon_instance
	
	# Set up cursor from player instead
	setup_cursor_for_weapon(weapon_instance.x_cursor)
	print("set cursor: ", weapon_instance.x_cursor)
	
	# Add weapon to player
	weapon_holder.add_child(weapon_instance)

	await get_tree().process_frame
	weapon_updated.emit()
	
func setup_cursor_for_weapon(x_cursor):
	var cursor_sheet = preload("res://assets/SpriteSheets/Weapons sprites (32x32).png")
	var gun_cursor = AtlasTexture.new()
	gun_cursor.atlas = cursor_sheet
	gun_cursor.region = Rect2(x_cursor, 0, 32, 32)
	
	var image = gun_cursor.get_image()
	var new_size = image.get_size() * 1.5
	image.resize(int(new_size.x), int(new_size.y), Image.INTERPOLATE_NEAREST)
	
	var scaled_cursor = ImageTexture.create_from_image(image)
	Input.set_custom_mouse_cursor(scaled_cursor, Input.CURSOR_ARROW, Vector2(24, 24))


func _on_hurt_box_recieved_damage(_damage: int) -> void:
	health.immortality = true
	is_hurt = true
	$AudioStreamPlayer2D.play()
	anim_sprite.play("hit")

func _on_animated_sprite_2d_animation_finished() -> void:
	if anim_sprite.animation == "hit":
		health.immortality = false
		is_hurt = false
	elif anim_sprite.animation == "death":
		death.emit()

func _on_knockback_applied(direction: Vector2, force: float) -> void:
	knockback_velocity = direction * force

func _on_death() -> void:
	is_dead = true
	
	for child in weapon_holder.get_children():
		child.queue_free()
	
	anim_sprite.play("death")
	$AudioStreamPlayer2D.play()

func upgrade_current_weapon(upgrade_strategy: BaseBulletStrategy) -> bool:
	var current_gun = weapon_holder.get_child(0) if weapon_holder.get_child_count() > 0 else null
	
	if current_gun == null:
		return false
		
	# Check if upgrade is already owned
	if has_upgrade(upgrade_strategy):
		return false
		
	# Add the upgrade to the gun
	current_gun.upgrades.append(upgrade_strategy)
	return true

# Check if player already has a specific upgrade
func has_upgrade(upgrade_strategy: BaseBulletStrategy) -> bool:
	if weapon_holder.get_child_count() == 0:
		return false
		
	var current_gun = weapon_holder.get_child(0)
	if not current_gun or not current_gun.has_method("get_upgrades") and not "upgrades" in current_gun:
		return false
	
	# Get the upgrades array
	var existing_upgrades = current_gun.get_upgrades() if current_gun.has_method("get_upgrades") else current_gun.upgrades
	
	# Check each upgrade
	for existing_upgrade in existing_upgrades:
		if existing_upgrade.get_script() == upgrade_strategy.get_script():
			return true
			
	return false

func set_max_ammo() -> void:
	if "max_ammo" in current_gun:
		current_gun.max_ammo = current_gun.max_possible_ammo

func play_start_bgm():
	print("start bgm played")
	$RelaxBGM.stop()
	$MainBGM.play()
	
func play_end_bgm():
	$MainBGM.stop()
	$RelaxBGM.play()

func activate_health_cheat():
	if health and health.has_method("heal"):
		health.heal(health.max_health)  # Restore to full health
		print("Cheat activated: Full health restored!")
	elif health and "current_health" in health and "max_health" in health:
		health.current_health = health.max_health
		print("Cheat activated: Full health restored!")

func _on_cheat_code_timer_timeout() -> void:
	typed_sequence = ""
