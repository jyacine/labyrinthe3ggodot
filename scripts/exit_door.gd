extends Area3D

class_name ExitDoor

var game_manager: GameManager
var player: Player
var mesh_instance: MeshInstance3D
var collision_shape: CollisionShape3D

func _ready() -> void:
	var root = get_parent()
	game_manager = root.get_node("GameManager")
	player = root.get_node("Player")

	# Create visual mesh
	mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(0.8, 2.0, 0.8)
	mesh_instance.mesh = box_mesh

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color.GREEN
	mesh_instance.set_surface_override_material(0, mat)

	add_child(mesh_instance)

	# Setup collision
	collision_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(0.8, 2.0, 0.8)
	collision_shape.shape = box_shape
	add_child(collision_shape)

	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area3D) -> void:
	if area.name == "Player":
		# Win condition
		game_manager.is_playing = false
		game_manager.time_left = -1  # Signal win
