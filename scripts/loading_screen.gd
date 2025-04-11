extends Control

signal loading_completed

@export var min_load_time: float = 1.0  # Minimum time to show loading screen

@onready var progress_bar = $LoadingBar
@onready var tip_label = $TipContainer/MarginContainer/Tip
@onready var status_label = $StatusContainer/StatusLabel
@onready var anim_player = $AnimationPlayer

var target_scene: String = ""
var progress: Array[float] = []
var tips = [
    "Mystery boxes have a chance to give powerful weapons.",
    "Zombies may drop max ammo when defeated.",
    "Remember to reload your weapon when you have a moment of safety.",
    "Watch your back! Zombies can surround you quickly.",
    "Each wave becomes increasingly difficult.",
]

func _ready():
    # Hide initially, to be faded in
    modulate.a = 0
    
    # Select a random tip
    tip_label.text = "TIP: " + tips[randi() % tips.size()]

func load_scene(scene_path: String) -> void:
    target_scene = scene_path
    
    # Show the loading screen with animation
    anim_player.play("fade_in")
    await anim_player.animation_finished
    
    # Start loading the target scene in a separate thread
    _start_load()

func _start_load() -> void:
    progress = []
    
    # Start loading resources for the target scene
    ResourceLoader.load_threaded_request(target_scene)
    
    # Create a timer to simulate minimum loading time
    var min_timer = get_tree().create_timer(min_load_time)
    await min_timer.timeout
    
    # Continue with the resource loading process
    _update_progress()

func _process(_delta):
    # Update the progress bar if we have progress values
    if not progress.is_empty():
        progress_bar.value = progress.min() * 100

func _update_progress() -> void:
    # Check the loading status
    var loading_status = ResourceLoader.load_threaded_get_status(target_scene, progress)
    
    match loading_status:
        ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
            status_label.text = "ERROR"
            push_error("Failed to load scene: " + target_scene)
            return
            
        ResourceLoader.THREAD_LOAD_IN_PROGRESS:
            # Still loading, update progress and check again
            call_deferred("_update_progress")
            return
            
        ResourceLoader.THREAD_LOAD_FAILED:
            status_label.text = "FAILED"
            push_error("Failed to load scene: " + target_scene)
            return
            
        ResourceLoader.THREAD_LOAD_LOADED:
            # Loading completed, finish up
            progress_bar.value = 100
            status_label.text = "COMPLETE"
            _finish_loading()

func _finish_loading() -> void:
    # Get the loaded resource
    var new_scene = ResourceLoader.load_threaded_get(target_scene)
    
    # Play the transition out animation
    anim_player.play("transition_out")
    await anim_player.animation_finished
    
    # Signal that loading is completed
    loading_completed.emit()
    
    # Change to the new scene
    get_tree().change_scene_to_packed(new_scene)