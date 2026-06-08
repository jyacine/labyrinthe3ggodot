extends CanvasLayer

class_name UIManager

var game_manager: GameManager
var player: Player
var timer_label: Label
var minimap_rect: TextureRect
var overlay_panel: Panel
var overlay_label: Label
var minimap_image: Image
var minimap_texture: ImageTexture

# Minimap
var minimap_cell_size: int = 4
var minimap_margin: int = 8

var click_overlay: Panel
var click_label: Label

# Mobile buttons (forward/backward only)
var btn_forward: Button
var btn_backward: Button

# Overlay buttons
var btn_retry: Button

func _ready() -> void:
	var root = get_parent()
	game_manager = root.get_node("GameManager")
	player = root.get_node("Player")

	# "Click to play" overlay — shown on web until user clicks
	if OS.has_feature("web"):
		click_overlay = Panel.new()
		click_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		var bg = StyleBoxFlat.new()
		bg.bg_color = Color(0, 0, 0, 0.75)
		click_overlay.add_theme_stylebox_override("panel", bg)
		add_child(click_overlay)

		click_label = Label.new()
		click_label.text = "Tap to play\n\nButtons = Move   Drag right side = Look\nSafe zones (golden light) = hide from monsters\nH = Hint   R = Restart"
		click_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		click_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		click_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		click_label.add_theme_font_size_override("font_size", 28)
		click_label.add_theme_color_override("font_color", Color.WHITE)
		add_child(click_label)

	# Timer label (top-right so it doesn't overlap minimap)
	timer_label = Label.new()
	timer_label.anchor_left = 1.0
	timer_label.anchor_right = 1.0
	timer_label.offset_left = -160
	timer_label.offset_top = 10
	timer_label.add_theme_font_size_override("font_size", 24)
	add_child(timer_label)

	# Hint label (bottom of screen)
	var hint_label = Label.new()
	hint_label.anchor_top = 1.0
	hint_label.anchor_bottom = 1.0
	hint_label.offset_top = -30
	hint_label.offset_left = 10
	hint_label.text = "Safe zone = invisible to monsters   H=Hint  R=Restart"
	hint_label.add_theme_font_size_override("font_size", 14)
	add_child(hint_label)

	# Minimap
	minimap_rect = TextureRect.new()
	minimap_rect.position = Vector2(minimap_margin, minimap_margin)
	minimap_rect.size = Vector2(
		game_manager.grid[0].size() * minimap_cell_size,
		game_manager.grid.size() * minimap_cell_size
	)
	add_child(minimap_rect)

	_create_minimap()

	# Overlay (for win/lose)
	overlay_panel = Panel.new()
	overlay_panel.anchor_left = 0.5
	overlay_panel.anchor_top = 0.5
	overlay_panel.anchor_right = 0.5
	overlay_panel.anchor_bottom = 0.5
	overlay_panel.offset_left = -200
	overlay_panel.offset_top = -100
	overlay_panel.offset_right = 200
	overlay_panel.offset_bottom = 100
	overlay_panel.visible = false
	add_child(overlay_panel)

	overlay_label = Label.new()
	overlay_label.anchor_left = 0.5
	overlay_label.anchor_top = 0.5
	overlay_label.anchor_right = 0.5
	overlay_label.anchor_bottom = 0.5
	overlay_label.add_theme_font_size_override("font_size", 32)
	overlay_label.text = ""
	add_child(overlay_label)

	_create_mobile_buttons()

func _process(delta: float) -> void:
	# Hide click/tap overlay once interaction happens
	if click_overlay and click_overlay.visible:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED or Input.is_anything_pressed():
			click_overlay.visible = false
			if click_label:
				click_label.visible = false

	# Update timer
	timer_label.text = "Time: %.1f" % game_manager.time_left

	if game_manager.is_invisible:
		timer_label.add_theme_color_override("font_color", Color.YELLOW)
	else:
		timer_label.add_theme_color_override("font_color", Color.WHITE)

	# Update minimap
	_update_minimap()

	# Check win/lose conditions
	if not game_manager.is_playing:
		_show_overlay()

func _create_mobile_buttons() -> void:
	var sz = 120
	var margin = 20

	# RIGHT TOP: FORWARD button (FWD on top)
	btn_forward = _make_btn("FWD", 0, 0, sz)
	btn_forward.anchor_left   = 1.0
	btn_forward.anchor_top    = 1.0
	btn_forward.anchor_right  = 1.0
	btn_forward.anchor_bottom = 1.0
	btn_forward.offset_left   = -(sz + margin)
	btn_forward.offset_right  = -margin
	btn_forward.offset_top    = -360
	btn_forward.offset_bottom = -260
	add_child(btn_forward)

	# RIGHT BOTTOM: BACKWARD button (BACK on bottom)
	btn_backward = _make_btn("BACK", 0, 0, sz)
	btn_backward.anchor_left   = 1.0
	btn_backward.anchor_top    = 1.0
	btn_backward.anchor_right  = 1.0
	btn_backward.anchor_bottom = 1.0
	btn_backward.offset_left   = -(sz + margin)
	btn_backward.offset_right  = -margin
	btn_backward.offset_top    = -240
	btn_backward.offset_bottom = -140
	add_child(btn_backward)

	# Wire signals
	btn_forward.button_down.connect(func(): player.touch_forward = true)
	btn_forward.button_up.connect(func():   player.touch_forward = false)
	btn_backward.button_down.connect(func(): player.touch_backward = true)
	btn_backward.button_up.connect(func():   player.touch_backward = false)

func _make_btn(label: String, ox: int, oy: int, sz: int) -> Button:
	var btn = Button.new()
	btn.text = label
	btn.offset_left   = ox
	btn.offset_top    = oy
	btn.offset_right  = ox + sz
	btn.offset_bottom = oy + sz

	# Font and text styling
	btn.add_theme_font_size_override("font_size", 18)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", Color.YELLOW)
	btn.add_theme_color_override("font_hover_color", Color.LIGHT_GRAY)

	# Semi-transparent dark background
	var style = StyleBoxFlat.new()
	style.bg_color      = Color(0.1, 0.1, 0.1, 0.7)
	style.border_color  = Color.WHITE
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left     = 8
	style.corner_radius_top_right    = 8
	style.corner_radius_bottom_left  = 8
	style.corner_radius_bottom_right = 8

	btn.add_theme_stylebox_override("normal",  style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.add_theme_stylebox_override("hover",   style)
	return btn

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			get_tree().reload_current_scene()
		elif event.keycode == KEY_ESCAPE and not OS.has_feature("web"):
			get_tree().quit()

func _create_minimap() -> void:
	var grid = game_manager.grid
	var width = grid[0].size() * minimap_cell_size
	var height = grid.size() * minimap_cell_size

	minimap_image = Image.create(width, height, false, Image.FORMAT_RGB8)

	# Draw maze
	for r in range(grid.size()):
		for c in range(grid[r].size()):
			var color = Color.WHITE if grid[r][c] == 0 else Color.BLACK
			for dy in range(minimap_cell_size):
				for dx in range(minimap_cell_size):
					var px = c * minimap_cell_size + dx
					var py = r * minimap_cell_size + dy
					if px < width and py < height:
						minimap_image.set_pixel(px, py, color)

	minimap_texture = ImageTexture.create_from_image(minimap_image)
	minimap_rect.texture = minimap_texture

func _update_minimap() -> void:
	if minimap_texture == null:
		return

	# Redraw minimap with player and entities
	# Draw maze (walls dark, floors light)
	var grid = game_manager.grid
	for r in range(grid.size()):
		for c in range(grid[r].size()):
			var color = Color(0.7, 0.7, 0.7) if grid[r][c] == 0 else Color(0.15, 0.15, 0.15)
			for dy in range(minimap_cell_size):
				for dx in range(minimap_cell_size):
					var px = c * minimap_cell_size + dx
					var py = r * minimap_cell_size + dy
					if px < minimap_image.get_width() and py < minimap_image.get_height():
						minimap_image.set_pixel(px, py, color)

	# Draw exit
	var exit_grid = game_manager.exit_pos
	_draw_minimap_point(exit_grid[0], exit_grid[1], Color.GREEN, 2)

	# Draw player (bigger dot + bright cyan for clear visibility)
	var player_grid = player.get_grid_position()
	_draw_minimap_point(player_grid[0], player_grid[1], Color.CYAN, 4)

	# Draw monsters
	var monsters = get_tree().get_nodes_in_group("monsters")
	for monster in monsters:
		var m_grid = monster.current_grid_pos
		_draw_minimap_point(m_grid[0], m_grid[1], Color.RED, 1)

	# Draw safe zones (yellow)
	var root = player.get_parent()
	for child in root.get_children():
		if child.name.begins_with("SafeZone"):
			var cell_x = int(child.position.x / Config.CELL_SIZE)
			var cell_y = int(child.position.z / Config.CELL_SIZE)
			_draw_minimap_point(cell_x, cell_y, Color.YELLOW, 2)

	minimap_texture = ImageTexture.create_from_image(minimap_image)
	minimap_rect.texture = minimap_texture

func _draw_minimap_point(grid_x: int, grid_y: int, color: Color, size: int) -> void:
	var width = minimap_image.get_width()
	var height = minimap_image.get_height()

	for dy in range(-size, size + 1):
		for dx in range(-size, size + 1):
			var px = grid_x * minimap_cell_size + minimap_cell_size / 2 + dx
			var py = grid_y * minimap_cell_size + minimap_cell_size / 2 + dy
			if px >= 0 and px < width and py >= 0 and py < height:
				minimap_image.set_pixel(px, py, color)

func _show_overlay() -> void:
	overlay_panel.visible = true

	var is_win = game_manager.time_left < 0 or player.get_grid_position() == game_manager.exit_pos

	if is_win:
		overlay_label.text = "YOU WIN!"
		overlay_label.add_theme_color_override("font_color", Color.GREEN)
	else:
		overlay_label.text = "GAME OVER!"
		overlay_label.add_theme_color_override("font_color", Color.RED)

	overlay_label.anchor_left = 0.5
	overlay_label.anchor_top = 0.5
	overlay_label.anchor_right = 0.5
	overlay_label.anchor_bottom = 0.5
	overlay_label.offset_left = -200
	overlay_label.offset_top = -120
	overlay_label.offset_right = 200
	overlay_label.offset_bottom = -50

	# Add retry button if not already created
	if btn_retry == null:
		btn_retry = Button.new()
		btn_retry.text = "RETRY"
		btn_retry.anchor_left = 0.5
		btn_retry.anchor_top = 0.5
		btn_retry.anchor_right = 0.5
		btn_retry.anchor_bottom = 0.5
		btn_retry.offset_left = -60
		btn_retry.offset_top = 20
		btn_retry.offset_right = 60
		btn_retry.offset_bottom = 70
		btn_retry.add_theme_font_size_override("font_size", 24)
		btn_retry.add_theme_color_override("font_color", Color.WHITE)
		btn_retry.button_down.connect(func(): get_tree().reload_current_scene())
		overlay_panel.add_child(btn_retry)

	btn_retry.visible = true
