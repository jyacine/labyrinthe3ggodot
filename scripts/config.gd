extends Node

# Grid/Maze
const MAZE_COLS = 27
const MAZE_ROWS = 27
const EXTRA_PASSAGES = 60
const CELL_SIZE = 2.0  # 2 units per grid cell — wider passages

# Player
const PLAYER_SPEED = 3.2
const PLAYER_ROTATION_SPEED = 2.3
const PLAYER_RADIUS = 0.28
const MOUSE_SENSITIVITY = 0.003

# Monsters
const NUM_MONSTERS = 3
const MONSTER_PATROL_SPEED = 1.4
const MONSTER_CHASE_SPEED = 2.1
const MONSTER_ENRAGE_SPEED = 3.4
const MONSTER_DETECTION_RADIUS = 13.0  # scaled x2 for wider world
const CATCH_DISTANCE = 1.1              # scaled x2
const PATHFIND_INTERVAL = 0.35
const PATROL_MIN_DIST = 6

# Power balls
const NUM_POWERBALLS = 5
const INVISIBILITY_DURATION = 5.0

# Game
const GAME_DURATION = 150
const ENRAGE_PATH_STEPS = 30

# Level selection (set from menu before game starts)
# "easy"   = 1x malak + 1x bayan + 1x kaltoum  (3 monsters)
# "medium" = 2x malak + 2x bayan + 2x kaltoum  (6 monsters)
# "hard"   = 3x malak + 3x bayan + 3x kaltoum  (9 monsters)
var selected_level: String = "medium"

# UI/Rendering
const FPS = 60
const MINIMAP_CELL_SIZE = 4
const MINIMAP_MARGIN = 8
