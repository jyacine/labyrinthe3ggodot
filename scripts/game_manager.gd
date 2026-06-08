extends Node

class_name GameManager

var grid: Array
var player_pos: Array
var exit_pos: Array
var monster_positions: Array   # split evenly: malak | bayan | kaltoum
var safezone_positions: Array
var time_left: float
var is_playing: bool
var is_invisible: bool         # true while player stands in a safe zone
var show_hint: bool

func _init() -> void:
	var maze_gen = MazeGenerator.new()
	grid = maze_gen.generate_maze(27, 27, 60)

	var spawns = maze_gen.pick_spawns(grid)
	player_pos   = spawns["player"]
	exit_pos     = spawns["exit"]

	# Monster count: 3 types (malak, bayan, kaltoum) × count_per_type
	# easy = 1 each = 3 total | medium = 2 each = 6 total | hard = 3 each = 9 total
	var count_per_type: int = 2  # default medium
	match Config.selected_level:
		"easy":   count_per_type = 1
		"medium": count_per_type = 2
		"hard":   count_per_type = 3
	var total_monsters: int = count_per_type * 3

	var all_m = spawns["monsters"]
	var floors = _get_floor_cells()
	floors.shuffle()
	var extra: Array = []
	var used = [player_pos, exit_pos] + all_m
	for f in floors:
		if f not in used:
			extra.append(f)
		if extra.size() >= 9:
			break
	# Slice to exact monster count needed
	var all_positions = all_m + extra
	monster_positions = all_positions.slice(0, total_monsters)

	# Safe zones (5 glowing spots spread across the maze)
	var safe_cands: Array = []
	var taken = [player_pos, exit_pos] + monster_positions
	for f in floors:
		if f not in taken:
			safe_cands.append(f)
	safe_cands.shuffle()
	safezone_positions = safe_cands.slice(0, 5)

	time_left   = 150.0
	is_playing  = true
	is_invisible = false
	show_hint   = false

func _process(delta: float) -> void:
	if not is_playing:
		return
	time_left -= delta
	if time_left <= 0:
		time_left  = 0
		is_playing = false

func _get_floor_cells() -> Array:
	var cells = []
	for r in range(grid.size()):
		for c in range(grid[r].size()):
			if grid[r][c] == 0:
				cells.append([c, r])
	return cells
