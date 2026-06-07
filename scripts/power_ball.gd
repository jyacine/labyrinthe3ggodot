extends Area3D

class_name PowerBall

var game_manager: GameManager
var player: Player
var mesh_instance: MeshInstance3D

func _ready() -> void:
	var root = get_parent()
	game_manager = root.get_node("GameManager")
	player = root.get_node("Player")

	# Create visual mesh
	mesh_instance = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.25
	sphere_mesh.height = 0.5
	mesh_instance.mesh = sphere_mesh

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color.GOLD
	mesh_instance.set_surface_override_material(0, mat)

	add_child(mesh_instance)

	# Setup collision
	var collision_shape = CollisionShape3D.new()
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = 0.25
	collision_shape.shape = sphere_shape
	add_child(collision_shape)

	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area3D) -> void:
	if area.name == "Player":
		game_manager.activate_invisibility()
		queue_free()
