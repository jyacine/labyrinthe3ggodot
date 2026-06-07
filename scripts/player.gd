extends CharacterBody3D

class_name Player

var game_manager: GameManager
var grid: Array
var camera_node: Camera3D
var current_grid_pos: Array

# Movement
var move_speed: float = 3.2
var rotation_speed: float = 2.3
var mouse_sensitivity: float = 0.003
var yaw: float = 0.0
var pitch: float = 0.0

# Buffered yaw delta from event-driven input (mouse look, touch drag).
# Applied once per physics frame so the facing direction used for movement
# and collision stays consistent within that frame (fixes chaotic turning
# near obstacles caused by yaw changing mid-frame from _input).
var _pending_yaw_delta: float = 0.0

# Collision
var player_radius: float = 0.28

# Touch input flags (set by UIManager mobile buttons)
var touch_forward: bool = false
var touch_backward: bool = false
var touch_turn_left: bool = false
var touch_turn_right: bool = false

# Touch look (right-side drag for camera)
var _touch_look_id: int = -1
var _touch_look_prev: Vector2 = Vector2.ZERO

# Touch turn (left-side drag for turning)
var _touch_turn_id: int = -1
var _touch_turn_prev: Vector2 = Vector2.ZERO

func _ready() -> void:
	game_manager = get_parent().get_node("GameManager")
	grid = game_manager.grid

	# Create collision shape for the player
	var collision_shape = CollisionShape3D.new()
	var capsule = CapsuleShape3D.new()
	capsule.radius = player_radius
	capsule.height = 1.8
	collision_shape.shape = capsule
	add_child(collision_shape)

	# Create camera node
	camera_node = Camera3D.new()
	add_child(camera_node)
	camera_node.position = Vector3(0, 1.6, 0)

	var init_pos = game_manager.player_pos
	var cs = Config.CELL_SIZE
	position = Vector3((init_pos[0] + 0.5) * cs, 0.0, (init_pos[1] + 0.5) * cs)
	current_grid_pos = init_pos.duplicate()

	if not OS.has_feature("web"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	if not game_manager.is_playing:
		return

	# Check safe zones — if touching any, become invisible
	var in_safezone = false
	var root = get_parent()
	for child in root.get_children():
		if child is SafeZone:
			var dist = position.distance_to(child.position)
			if dist <= 1.5:  # SafeZone._radius
				in_safezone = true
				break
	game_manager.is_invisible = in_safezone

	# --- Turn ---
	# Apply any buffered event-driven turn (mouse look / touch drag) first.
	# Doing this here — once per physics frame — ensures `yaw` only changes
	# at one well-defined point, so the movement direction computed below
	# always matches the rotation actually applied this frame.
	yaw += _pending_yaw_delta
	_pending_yaw_delta = 0.0

	var turn = 0.0
	if Input.is_key_pressed(KEY_Q) or touch_turn_left:
		turn -= rotation_speed * delta
	if Input.is_key_pressed(KEY_E) or touch_turn_right:
		turn += rotation_speed * delta
	yaw += turn
	rotation.y = yaw

	# --- Move (forward / backward only, no strafe) ---
	var move = 0.0
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W) or touch_forward:
		move += 1.0
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S) or touch_backward:
		move -= 1.0

	if move != 0.0:
		# Simple, reliable movement: calculate forward and try to move
		var forward = Vector3(-sin(yaw), 0, -cos(yaw))
		var movement = forward * move * move_speed * delta
		var new_pos = position + movement

		# Test the new position - if walkable, move there.
		if _is_walkable(new_pos):
			position = new_pos
		else:
			# Blocked along the straight line — slide along the wall by
			# trying each axis independently. Without this, any approach
			# that isn't perfectly parallel to the wall gets rejected
			# outright (even a few degrees off), because the single
			# diagonal test point dips into the wall cell. Sliding lets
			# you brush past at an angle instead of stopping dead.
			var slide_x = position + Vector3(movement.x, 0, 0)
			var slide_z = position + Vector3(0, 0, movement.z)
			if _is_walkable(slide_x):
				position = slide_x
			elif _is_walkable(slide_z):
				position = slide_z
			# else: blocked on both axes — stay put this frame

	current_grid_pos = [int(position.x / Config.CELL_SIZE), int(position.z / Config.CELL_SIZE)]

func _input(event: InputEvent) -> void:
	# --- Mouse click to capture ---
	if event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	# --- Mouse look (desktop) ---
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# Buffer the yaw change instead of applying it immediately — _input
		# can fire multiple times between physics ticks, and we only want
		# `yaw` (which drives both rotation and movement direction) to move
		# once per physics frame, in _physics_process.
		_pending_yaw_delta -= event.relative.x * mouse_sensitivity
		pitch -= event.relative.y * mouse_sensitivity
		pitch  = clamp(pitch, -PI / 3.0, PI / 3.0)
		camera_node.rotation.x = pitch

	# --- Touch input: left side only (for turning) ---
	if event is InputEventScreenTouch:
		var half_w = get_viewport().get_visible_rect().size.x / 2.0
		if event.position.x < half_w:
			# Left side: turning
			if event.pressed:
				_touch_turn_id   = event.index
				_touch_turn_prev = event.position
			elif event.index == _touch_turn_id:
				_touch_turn_id = -1

	# Left side drag: turn (horizontal movement only)
	if event is InputEventScreenDrag and event.index == _touch_turn_id:
		var half_w = get_viewport().get_visible_rect().size.x / 2.0
		if event.position.x < half_w:
			# Compute the delta ourselves from position instead of trusting
			# event.relative — Godot has a known bug (godotengine/godot#94346,
			# #33470) where `relative` gets scaled up (~2x with two touches,
			# ~3x with three) whenever more than one finger is on screen at
			# once. Since turning-while-moving means the FWD/BACK button
			# (one touch) and the turn drag (a second touch) are active
			# together, `relative` would come back inflated and snap the
			# yaw to a wildly different value — the "abrupt/chaotic" turn.
			# Tracking our own previous position sidesteps the bug entirely.
			var dx = (event.position.x - _touch_turn_prev.x) * mouse_sensitivity * 2.0
			_touch_turn_prev = event.position
			# Buffered (see note in the mouse-look handler above) so touch
			# drags on mobile don't yank `yaw` mid-frame and desync the
			# movement direction from what gets rendered/collision-tested.
			_pending_yaw_delta -= dx

	# --- Keys ---
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if OS.has_feature("web"):
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			else:
				get_tree().quit()
		if event.keycode == KEY_H:
			game_manager.show_hint = not game_manager.show_hint

func _is_walkable(pos: Vector3) -> bool:
	var cs = Config.CELL_SIZE
	var r = player_radius

	# True circle-vs-cell distance check: keeps the player's capsule (and the
	# camera riding on it) at least `player_radius` away from any wall, in
	# every direction — not just blocked when the bare center point crosses a
	# cell boundary. That's what was letting the camera poke into wall
	# geometry and "see behind" walls when you pressed into them.
	#
	# Unlike a 4-corner bounding-box test, this measures the real distance
	# from the circle's center to the nearest point on each nearby wall
	# cell, so it doesn't falsely block glancing approaches either — you can
	# still slide smoothly along a wall at any angle, right up to the point
	# where the capsule would actually touch it.
	var min_cx = int(floor((pos.x - r) / cs))
	var max_cx = int(floor((pos.x + r) / cs))
	var min_cz = int(floor((pos.z - r) / cs))
	var max_cz = int(floor((pos.z + r) / cs))

	for cz in range(min_cz, max_cz + 1):
		for cx in range(min_cx, max_cx + 1):
			if cx < 0 or cx >= grid[0].size() or cz < 0 or cz >= grid.size():
				return false
			if grid[cz][cx] != 1:
				continue
			var closest_x = clamp(pos.x, cx * cs, (cx + 1) * cs)
			var closest_z = clamp(pos.z, cz * cs, (cz + 1) * cs)
			var dx = pos.x - closest_x
			var dz = pos.z - closest_z
			if dx * dx + dz * dz < r * r:
				return false

	return true

func get_grid_position() -> Array:
	return current_grid_pos
