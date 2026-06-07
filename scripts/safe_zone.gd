extends Node3D

class_name SafeZone

var game_manager: GameManager
var player: Node3D
var _light: OmniLight3D
var _radius: float = 1.5

func _ready() -> void:
	game_manager = get_parent().get_node("GameManager")
	player        = get_parent().get_node("Player")

	# Glow light
	_light = OmniLight3D.new()
	_light.light_color  = Color(1.0, 0.85, 0.3)
	_light.light_energy = 2.5
	_light.omni_range   = 4.0
	_light.position     = Vector3(0, 1.0, 0)
	add_child(_light)

	# Glowing sphere
	var glow_mesh = MeshInstance3D.new()
	var sphere    = SphereMesh.new()
	sphere.radius = 0.35
	sphere.height = 0.70
	glow_mesh.mesh     = sphere
	glow_mesh.position = Vector3(0, 0.5, 0)
	var glow_mat = StandardMaterial3D.new()
	glow_mat.albedo_color               = Color(1.0, 0.9, 0.3, 0.7)
	glow_mat.emission_enabled           = true
	glow_mat.emission                   = Color(1.0, 0.85, 0.2)
	glow_mat.emission_energy_multiplier = 3.0
	glow_mat.transparency               = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow_mesh.set_surface_override_material(0, glow_mat)
	add_child(glow_mesh)

	# Floor ring
	var ring_mesh = MeshInstance3D.new()
	var torus     = TorusMesh.new()
	torus.inner_radius = 0.55
	torus.outer_radius = 0.75
	ring_mesh.mesh     = torus
	ring_mesh.position = Vector3(0, 0.05, 0)
	var ring_mat = StandardMaterial3D.new()
	ring_mat.albedo_color               = Color(1.0, 0.9, 0.2)
	ring_mat.emission_enabled           = true
	ring_mat.emission                   = Color(1.0, 0.85, 0.1)
	ring_mat.emission_energy_multiplier = 2.0
	ring_mesh.set_surface_override_material(0, ring_mat)
	add_child(ring_mesh)

func _process(_delta: float) -> void:
	# Pulse light
	if _light != null:
		var t: float = float(Time.get_ticks_msec()) / 1000.0
		_light.light_energy = 2.0 + sin(t * 2.5) * 0.5

	# Only SET to true — never set false (player resets it each frame)
	if player == null or game_manager == null:
		return
	if position.distance_to(player.position) <= _radius:
		game_manager.is_invisible = true
