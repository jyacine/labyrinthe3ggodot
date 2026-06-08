extends Node3D

class_name ExitDoor

var game_manager: GameManager
var player: Player
var _light: OmniLight3D
var _catch_radius: float = 1.2

func _ready() -> void:
	var root = get_parent()
	game_manager = root.get_node("GameManager")
	player        = root.get_node("Player")

	# Pulsing green light (like safe zone but green - no sphere)
	_light = OmniLight3D.new()
	_light.light_color  = Color(0.2, 1.0, 0.3)
	_light.light_energy = 3.0
	_light.omni_range   = 6.0
	_light.position     = Vector3(0, 1.5, 0)
	add_child(_light)

	# Floor ring to show the target area
	var ring_mesh = MeshInstance3D.new()
	var torus     = TorusMesh.new()
	torus.inner_radius = 0.55
	torus.outer_radius = 0.80
	ring_mesh.mesh     = torus
	ring_mesh.position = Vector3(0, 0.05, 0)
	var ring_mat = StandardMaterial3D.new()
	ring_mat.albedo_color               = Color(0.2, 1.0, 0.3)
	ring_mat.emission_enabled           = true
	ring_mat.emission                   = Color(0.1, 0.8, 0.2)
	ring_mat.emission_energy_multiplier = 2.5
	ring_mesh.set_surface_override_material(0, ring_mat)
	add_child(ring_mesh)

func _process(delta: float) -> void:
	# Pulse light
	if _light != null:
		var t = float(Time.get_ticks_msec()) / 1000.0
		_light.light_energy = 2.5 + sin(t * 2.0) * 0.8

	# Check if player reached exit
	if game_manager == null or player == null or not game_manager.is_playing:
		return
	if position.distance_to(player.position) <= _catch_radius:
		game_manager.is_playing = false
		game_manager.time_left  = -1  # Signal win
