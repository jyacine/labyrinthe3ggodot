extends Node3D

var game_manager: GameManager
var player: Player
var monsters: Array = []

func _ready() -> void:
	# Initialize game manager
	game_manager = GameManager.new()
	add_child(game_manager)
	game_manager.name = "GameManager"

	# Create maze geometry
	_create_maze()

	# Create player
	player = Player.new()
	add_child(player)
	player.name = "Player"

	# Create exit door
	_create_exit()

	# Create monsters: first 3 = Janna, last 3 = Souleym
	for i in range(game_manager.monster_positions.size()):
		var monster = Monster.new()

		if i < 3:
			# Janna creeper
			monster.face_texture_path = "res://assets/janna.png"
			monster.sound_patrol_path = "res://assets/janna_sound.wav"
			monster.sound_chase_path  = "res://assets/janna_sound.wav"
			monster.body_color_normal = Color(0.25, 0.55, 0.15)
			monster.body_color_chase  = Color(0.55, 0.65, 0.10)
			monster.body_color_enrage = Color(0.85, 0.20, 0.10)
		else:
			# Souleym creeper (purple-blue tones)
			monster.face_texture_path = "res://assets/souleym.png"
			monster.sound_patrol_path = "res://assets/souleym_sound.wav"
			monster.sound_chase_path  = "res://assets/souleym_sound.wav"
			monster.body_color_normal = Color(0.20, 0.15, 0.55)
			monster.body_color_chase  = Color(0.50, 0.10, 0.65)
			monster.body_color_enrage = Color(0.80, 0.05, 0.80)

		add_child(monster)
		monster.name = "Monster_%d" % i
		monster.add_to_group("monsters")
		var init_pos = game_manager.monster_positions[i]
		monster.position = Vector3((init_pos[0] + 0.5) * Config.CELL_SIZE, 0.0, (init_pos[1] + 0.5) * Config.CELL_SIZE)
		monsters.append(monster)

	# Create safe zones (replace power balls)
	for i in range(game_manager.safezone_positions.size()):
		_create_safezone(game_manager.safezone_positions[i], i)

	# Create UI
	_create_ui()

	# Lighting
	var dir_light = DirectionalLight3D.new()
	dir_light.rotation_degrees = Vector3(-45, 30, 0)
	dir_light.light_energy = 0.6
	add_child(dir_light)

	# Ambient environment
	var world_env = WorldEnvironment.new()
	var env = Environment.new()
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.4, 0.38, 0.45)
	env.ambient_light_energy = 1.2
	world_env.environment = env
	add_child(world_env)

func _create_maze() -> void:
	var maze_node = Node3D.new()
	maze_node.name = "Maze"
	add_child(maze_node)

	# --- Brick wall shader ---
	var wall_shader = Shader.new()
	wall_shader.code = """
shader_type spatial;
void fragment() {
	vec2 uv = UV * vec2(4.0, 2.5);
	float row = floor(uv.y);
	float offset = mod(row, 2.0) * 0.5;
	vec2 brick_uv = vec2(uv.x + offset, uv.y);
	float mx = abs(fract(brick_uv.x) - 0.5) * 2.0;
	float my = abs(fract(brick_uv.y) - 0.5) * 2.0;
	float mortar = step(0.88, max(mx, my));
	vec3 brick_base = vec3(0.55 + fract(floor(brick_uv.x) * 7.3 + row * 3.1) * 0.1, 0.28, 0.18);
	vec3 mortar_col = vec3(0.72, 0.70, 0.65);
	ALBEDO = mix(brick_base, mortar_col, mortar);
	ROUGHNESS = 0.9;
}
"""
	var wall_mat = ShaderMaterial.new()
	wall_mat.shader = wall_shader

	# --- Stone floor shader ---
	var floor_shader = Shader.new()
	floor_shader.code = """
shader_type spatial;
void fragment() {
	vec2 uv = UV * 12.0;
	float gx = floor(uv.x);
	float gy = floor(uv.y);
	float checker = mod(gx + gy, 2.0);
	float noise = fract(sin(gx * 127.1 + gy * 311.7) * 43758.5);
	vec3 col = mix(vec3(0.28, 0.28, 0.30), vec3(0.22, 0.22, 0.24), checker);
	col += (noise - 0.5) * 0.04;
	ALBEDO = col;
	ROUGHNESS = 1.0;
}
"""
	var floor_mat = ShaderMaterial.new()
	floor_mat.shader = floor_shader

	# --- Ceiling material ---
	var ceil_mat = StandardMaterial3D.new()
	ceil_mat.albedo_color = Color(0.15, 0.15, 0.18)
	ceil_mat.roughness = 1.0

	var grid = game_manager.grid
	var cols = grid[0].size()
	var rows = grid.size()
	var cs = Config.CELL_SIZE
	var wall_h = 3.0

	# Floor plane
	var floor_mesh = MeshInstance3D.new()
	var floor_plane = PlaneMesh.new()
	floor_plane.size = Vector2(cols * cs, rows * cs)
	floor_mesh.mesh = floor_plane
	floor_mesh.material_override = floor_mat
	floor_mesh.position = Vector3(cols * cs / 2.0, 0.0, rows * cs / 2.0)
	maze_node.add_child(floor_mesh)

	# Ceiling plane
	var ceil_mesh = MeshInstance3D.new()
	var ceil_plane = PlaneMesh.new()
	ceil_plane.size = Vector2(cols * cs, rows * cs)
	ceil_mesh.mesh = ceil_plane
	ceil_mesh.material_override = ceil_mat
	ceil_mesh.position = Vector3(cols * cs / 2.0, wall_h, rows * cs / 2.0)
	ceil_mesh.rotation.x = PI
	maze_node.add_child(ceil_mesh)

	# Walls with collision
	for r in range(rows):
		for c in range(cols):
			if grid[r][c] == 1:
				# Create static physics body for the wall
				var wall_body = StaticBody3D.new()
				wall_body.position = Vector3((c + 0.5) * cs, wall_h / 2.0, (r + 0.5) * cs)
				maze_node.add_child(wall_body)

				# Visual representation
				var wall_visual = CSGBox3D.new()
				wall_visual.size = Vector3(cs, wall_h, cs)
				wall_visual.material = wall_mat
				wall_body.add_child(wall_visual)

				# Collision shape
				var collision_shape = CollisionShape3D.new()
				var box_shape = BoxShape3D.new()
				box_shape.size = Vector3(cs, wall_h, cs)
				collision_shape.shape = box_shape
				wall_body.add_child(collision_shape)

func _create_exit() -> void:
	var exit = ExitDoor.new()
	add_child(exit)
	exit.name = "Exit"

	var init_pos = game_manager.exit_pos
	exit.position = Vector3((init_pos[0] + 0.5) * Config.CELL_SIZE, 0.0, (init_pos[1] + 0.5) * Config.CELL_SIZE)

func _create_safezone(pos: Array, index: int) -> void:
	var zone = SafeZone.new()
	add_child(zone)
	zone.name = "SafeZone_%d" % index
	zone.position = Vector3((pos[0] + 0.5) * Config.CELL_SIZE, 0.0, (pos[1] + 0.5) * Config.CELL_SIZE)

func _create_ui() -> void:
	var ui_layer = UIManager.new()
	add_child(ui_layer)
	ui_layer.name = "UI"
