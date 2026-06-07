extends Node

class_name MazeGenerator

static func generate_maze(cols: int, rows: int, extra: int) -> Array:
	cols = _odd(cols)
	rows = _odd(rows)

	var grid = []
	for r in range(rows):
		grid.append([])
		for c in range(cols):
			grid[r].append(1)

	_carve(grid, rows, cols, 1, 1)
	_add_loops(grid, rows, cols, extra)

	return grid

static func _odd(n: int) -> int:
	return n if n % 2 == 1 else n - 1

static func _carve(grid: Array, rows: int, cols: int, start_r: int, start_c: int) -> void:
	var stack = [[start_r, start_c]]
	grid[start_r][start_c] = 0

	while stack.size() > 0:
		var cr = stack[-1][0]
		var cc = stack[-1][1]
		var dirs = [[-2, 0], [2, 0], [0, -2], [0, 2]]
		dirs.shuffle()

		var moved = false
		for dir in dirs:
			var dr = dir[0]
			var dc = dir[1]
			var nr = cr + dr
			var nc = cc + dc

			if nr > 0 and nr < rows - 1 and nc > 0 and nc < cols - 1 and grid[nr][nc] == 1:
				grid[cr + dr/2][cc + dc/2] = 0
				grid[nr][nc] = 0
				stack.append([nr, nc])
				moved = true
				break

		if not moved:
			stack.pop_back()

static func _add_loops(grid: Array, rows: int, cols: int, count: int) -> void:
	var candidates = []
	for r in range(1, rows - 1):
		for c in range(1, cols - 1):
			if grid[r][c] == 1:
				if (grid[r][c-1] == 0 and grid[r][c+1] == 0) or \
				   (grid[r-1][c] == 0 and grid[r+1][c] == 0):
					candidates.append([r, c])

	candidates.shuffle()
	for i in range(min(count, candidates.size())):
		var cell = candidates[i]
		grid[cell[0]][cell[1]] = 0

static func pick_spawns(grid: Array) -> Dictionary:
	var rows = grid.size()
	var cols = grid[0].size()
	var floors = _get_floor_cells(grid)

	# Player: top-left
	var tl = []
	for cell in floors:
		if cell[0] < cols / 3 and cell[1] < rows / 3:
			tl.append(cell)

	var player_cell = tl[randi() % tl.size()] if tl.size() > 0 else floors[randi() % floors.size()]

	# Exit: farthest from player
	var exit_cell = floors[0]
	var max_dist = 0.0
	for cell in floors:
		if cell != player_cell:
			var d = _distance(cell, player_cell)
			if d > max_dist:
				max_dist = d
				exit_cell = cell

	# Monsters: spread out, far from player
	var monster_cells = []
	var used = [player_cell, exit_cell]
	var cands = []
	for cell in floors:
		if cell not in used and _distance(cell, player_cell) > cols * 0.35:
			cands.append(cell)
	if cands.size() == 0:
		cands = floors.duplicate()

	for i in range(3):  # NUM_MONSTERS = 3
		if cands.size() == 0:
			break
		var best_cell = cands[0]
		var best_min_dist = 0.0
		for cell in cands:
			var min_d = INF
			for anchor in [player_cell] + monster_cells:
				var d = _distance(cell, anchor)
				if d < min_d:
					min_d = d
			if min_d > best_min_dist:
				best_min_dist = min_d
				best_cell = cell

		monster_cells.append(best_cell)
		used.append(best_cell)
		var new_cands = []
		for c in cands:
			if c != best_cell:
				new_cands.append(c)
		cands = new_cands

	return {
		"player": player_cell,
		"exit": exit_cell,
		"monsters": monster_cells
	}

static func _get_floor_cells(grid: Array) -> Array:
	var cells = []
	for r in range(grid.size()):
		for c in range(grid[r].size()):
			if grid[r][c] == 0:
				cells.append([c, r])
	return cells

static func _distance(a: Array, b: Array) -> float:
	return sqrt((a[0] - b[0]) ** 2 + (a[1] - b[1]) ** 2)
