extends Node3D

class_name Monster

# References
var game_manager: GameManager
var player: Player
var grid: Array

# State
var current_path: Array = []
var path_timer: float = 0.0
var state: String = "patrol"  # patrol, chase, enrage
var current_grid_pos: Array

# Speeds — all slower than player (player = 3.2)
var patrol_speed: float = 1.0   # slow patrol
var chase_speed: float = 1.8    # still slower than player
var enrage_speed: float = 2.8   # nearly player speed when close to exit

# Detection
var detection_radius: float = Config.MONSTER_DETECTION_RADIUS
var catch_distance: float = Config.CATCH_DISTANCE
var enrage_steps: int = 30

# Patrol
var patrol_target: Array = []
var patrol_min_dist: float = 6

# Visual (ALL class-level vars must be declared before any func)
var mesh_instance: MeshInstance3D
var creeper_body_mat: StandardMaterial3D
var creeper_head: CSGBox3D

# Configurable per-monster type (set before add_child)
var face_texture_path: String  = "res://assets/janna.png"
var sound_patrol_path: String  = "res://assets/janna_sound.wav"
var sound_chase_path: String   = "res://assets/janna_sound.wav"
var body_color_normal: Color   = Color(0.25, 0.55, 0.15)
var body_color_chase: Color    = Color(0.55, 0.65, 0.10)
var body_color_enrage: Color   = Color(0.85, 0.20, 0.10)

# Audio
var audio_player: AudioStreamPlayer3D
var sound_patrol: AudioStream
var sound_chase: AudioStream
var sound_timer: float = 0.0
var sound_interval: float = 3.0

# ------------------------------------------------------------------ #

func _ready() -> void:
	var root = get_parent()
	game_manager = root.get_node("GameManager")
	player = root.get_node("Player")
	grid = game_manager.grid

	current_grid_pos = [1, 1]

	_build_creeper()
	mesh_instance = MeshInstance3D.new()

	# 3D positional audio
	sound_patrol = load(sound_patrol_path) as AudioStream
	sound_chase  = load(sound_chase_path)  as AudioStream

	audio_player = AudioStreamPlayer3D.new()
	audio_player.max_distance = Config.MONSTER_DETECTION_RADIUS * 1.5
	audio_player.unit_size = 4.0
	audio_player.volume_db = 0.0
	add_child(audio_player)

	# Stagger so multiple monsters don't growl simultaneously
	sound_timer = randf_range(0.0, sound_interval)

	_pick_patrol_target()

# ------------------------------------------------------------------ #

func _physics_process(delta: float) -> void:
	if not game_manager.is_playing:
		return

	var cs = Config.CELL_SIZE
	current_grid_pos = [int(position.x / cs), int(position.z / cs)]

	var dist_to_player = position.distance_to(player.position)
	var player_dist_to_exit = _grid_distance(player.get_grid_position(), game_manager.exit_pos)

	# Safe zone: player is completely invisible — always patrol, never catch
	if game_manager.is_invisible:
		state = "patrol"
	elif player_dist_to_exit <= enrage_steps:
		state = "enrage"
	elif dist_to_player <= detection_radius:
		state = "chase"
	else:
		state = "patrol"

	# Pathfinding
	path_timer -= delta
	if path_timer <= 0:
		path_timer = 0.35
		match state:
			"patrol":
				if current_grid_pos == patrol_target or _grid_distance(current_grid_pos, patrol_target) < 0.5:
					_pick_patrol_target()
				current_path = Pathfinding.astar(grid, current_grid_pos, patrol_target)
			"chase", "enrage":
				current_path = Pathfinding.astar(grid, current_grid_pos, player.get_grid_position())

	# Movement
	var current_speed = patrol_speed
	match state:
		"chase":   current_speed = chase_speed
		"enrage":  current_speed = enrage_speed

	if current_path.size() > 1:
		var target_grid = current_path[1]
		var cs2 = Config.CELL_SIZE
		var target_pos = Vector3((target_grid[0] + 0.5) * cs2, position.y, (target_grid[1] + 0.5) * cs2)
		var direction = (target_pos - position).normalized()
		var new_pos = position + direction * current_speed * delta
		if _is_valid_position(new_pos):
			position = new_pos

	# Sound
	_update_sound(delta, dist_to_player)

	# Face the player
	var look_dir = player.position - position
	look_dir.y = 0
	if look_dir.length() > 0.01:
		rotation.y = atan2(look_dir.x, look_dir.z)

	_update_creeper_color()

	if dist_to_player <= catch_distance and not game_manager.is_invisible:
		game_manager.is_playing = false

# ------------------------------------------------------------------ #

func _pick_patrol_target() -> void:
	var floors = _get_floor_cells()
	var valid_targets = []
	for cell in floors:
		if _grid_distance(current_grid_pos, cell) > patrol_min_dist:
			valid_targets.append(cell)
	if valid_targets.size() > 0:
		patrol_target = valid_targets[randi() % valid_targets.size()]
	else:
		patrol_target = floors[randi() % floors.size()]

func _grid_distance(a: Array, b: Array) -> float:
	return sqrt((a[0] - b[0]) ** 2 + (a[1] - b[1]) ** 2)

func _is_valid_position(pos: Vector3) -> bool:
	var cs = Config.CELL_SIZE
	var grid_x = int(pos.x / cs)
	var grid_z = int(pos.z / cs)
	if grid_x < 0 or grid_x >= grid[0].size() or grid_z < 0 or grid_z >= grid.size():
		return false
	return grid[grid_z][grid_x] == 0

func _get_floor_cells() -> Array:
	var cells = []
	for r in range(grid.size()):
		for c in range(grid[r].size()):
			if grid[r][c] == 0:
				cells.append([c, r])
	return cells

# ------------------------------------------------------------------ #

func _update_sound(delta: float, dist_to_player: float) -> void:
	if audio_player == null:
		return
	sound_timer -= delta
	match state:
		"enrage": sound_interval = 0.8
		"chase":  sound_interval = 1.8
		_:        sound_interval = 3.5

	if sound_timer <= 0.0:
		sound_timer = sound_interval
		if state == "patrol":
			audio_player.stream = sound_patrol
		else:
			audio_player.stream = sound_chase
		var max_dist = Config.MONSTER_DETECTION_RADIUS
		var closeness = clamp(1.0 - dist_to_player / max_dist, 0.0, 1.0)
		audio_player.volume_db = lerp(-20.0, 6.0, closeness)
		audio_player.play()

# ------------------------------------------------------------------ #

func _build_creeper() -> void:
	var green = Color(0.25, 0.55, 0.15)
	var dark  = Color(0.10, 0.28, 0.06)

	creeper_body_mat = StandardMaterial3D.new()
	creeper_body_mat.albedo_color = green

	var dark_mat = StandardMaterial3D.new()
	dark_mat.albedo_color = dark

	var body = CSGBox3D.new()
	body.size = Vector3(0.45, 0.55, 0.30)
	body.position = Vector3(0, 0.55, 0)
	body.material = creeper_body_mat
	add_child(body)

	for lp in [Vector3(-0.12, 0.15, -0.09), Vector3(0.12, 0.15, -0.09),
			   Vector3(-0.12, 0.15,  0.09), Vector3(0.12, 0.15,  0.09)]:
		var leg = CSGBox3D.new()
		leg.size = Vector3(0.17, 0.30, 0.17)
		leg.position = lp
		leg.material = creeper_body_mat
		add_child(leg)

	creeper_head = CSGBox3D.new()
	creeper_head.size = Vector3(0.45, 0.45, 0.45)
	creeper_head.position = Vector3(0, 1.08, 0)
	creeper_head.material = creeper_body_mat
	add_child(creeper_head)

	# Janna face quad on the front face (+Z = player-facing side)
	var face_quad = MeshInstance3D.new()
	var quad_mesh = QuadMesh.new()
	quad_mesh.size = Vector2(0.40, 0.40)
	face_quad.mesh = quad_mesh
	face_quad.position = Vector3(0, 1.08, 0.226)

	var face_mat = StandardMaterial3D.new()
	face_mat.albedo_color = Color.WHITE
	face_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	face_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	if ResourceLoader.exists(face_texture_path):
		var face_tex = load(face_texture_path) as Texture2D
		if face_tex:
			face_mat.albedo_texture = face_tex
	face_quad.set_surface_override_material(0, face_mat)
	add_child(face_quad)

func _update_creeper_color() -> void:
	if creeper_body_mat == null:
		return
	match state:
		"enrage": creeper_body_mat.albedo_color = body_color_enrage
		"chase":  creeper_body_mat.albedo_color = body_color_chase
		_:        creeper_body_mat.albedo_color = body_color_normal
