extends CanvasLayer

@onready var mag_label = %MagLabel
@onready var total_ammo_label = %TotalAmmoLabel
@onready var reload_progress_bar = %ReloadProgressBar

var gun: Node
var reload_timer: float = 0
var is_reloading: bool = false

func _ready() -> void:
	# Find the gun node
	await get_tree().process_frame
	_on_update_gun()
		
	var player = get_tree().get_first_node_in_group("player")
	player.connect("weapon_updated", _on_update_gun)
		
func _on_update_gun() -> void:
	gun = get_tree().get_first_node_in_group("player_gun")
	if gun:
		update_ammo_display()
		gun.connect("reload_started", Callable(self, "start_reload"))
	else:
		push_error("MagazineUI: No gun found with group 'player_gun'")

func _process(delta: float) -> void:
	if not gun:
		return
		
	update_ammo_display()
	
	# Handle reload progress
	if is_reloading:
		reload_timer -= delta
		reload_progress_bar.value = (1.0 - (reload_timer / gun.reload_time)) * 100
		
		if reload_timer <= 0:
			is_reloading = false
			reload_progress_bar.visible = false

func update_ammo_display() -> void:
	# Check if gun has magazine system
	if "current_mag" in gun and "max_ammo" in gun:
		mag_label.text = str(gun.current_mag)
		total_ammo_label.text = str(gun.max_ammo)
		
		# Change color based on ammo status
		if gun.current_mag == 0:
			mag_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
		else:
			mag_label.remove_theme_color_override("font_color")
	else:
		# Weapon has infinite ammo
		mag_label.text = "INF"
		total_ammo_label.text = "∞"
		
		# Reset color for infinite ammo
		mag_label.remove_theme_color_override("font_color")
		mag_label.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0))  # Light blue for infinite

func start_reload() -> void:
	is_reloading = true
	reload_timer = gun.reload_time
	reload_progress_bar.max_value = 100
	reload_progress_bar.value = 0
	reload_progress_bar.visible = true
