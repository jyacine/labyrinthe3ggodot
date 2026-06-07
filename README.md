# Labyrinthe 3D — Godot Edition

A first-person 3D maze escape game built with Godot 4.

## Installation

1. Install Godot 4.x from https://godotengine.org
2. Open Godot and select "Import Project"
3. Navigate to C:\work\game\labyrinthe3ggodot and select project.godot
4. The project will open in the editor

## Running

Press Play (F5) in the Godot editor, or use File → Run to launch.

## Controls

- **W/S** — Move forward/backward
- **A/D / ← / →** — Strafe left/right
- **Mouse** — Look around
- **Q/E** — Rotate (keyboard alternative)
- **H** — Toggle path hint
- **R** — Restart game
- **ESC** — Quit

## Game Features

- Procedurally generated 27×27 maze with multiple paths
- 3 monsters with patrol/chase AI and pathfinding
- Invisibility power-ups (5-second duration)
- 120-second countdown timer
- Exit door (green cube) — reach to win
- Minimap showing maze and entity positions
- Path hint system (shows shortest route to exit)

## Architecture

- **config.gd** — Global game constants
- **maze_generator.gd** — Procedural maze generation (iterative DFS)
- **pathfinding.gd** — A* pathfinding for monster AI
- **game_manager.gd** — Core game logic
- **player.gd** — FPS controller (keyboard + mouse)
- **monster.gd** — Monster AI (patrol/chase)
- **power_ball.gd** — Collectible item
- **ui_manager.gd** — HUD, timer, minimap, overlays
- **main.gd** — Scene setup and orchestration

## Gameplay

1. Game starts with a 150-second countdown timer
2. Navigate the maze from your starting position (top-left) to the exit (green door)
3. Avoid monsters that patrol the maze and will chase you if you get close
4. Collect golden power balls to become invisible for 5 seconds
5. Reach the exit before time runs out to win
6. Monsters will enrage (speed up) when you're within 30 steps of the exit
7. Use H to toggle a path hint showing the shortest route to the exit

## Winning and Losing

- **Win**: Reach the green exit door before time runs out
- **Lose**: Get caught by a monster or run out of time

Press R to restart or ESC to quit.
