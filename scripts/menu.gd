extends CanvasLayer

func _ready() -> void:
	# Background
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.05, 0.05, 0.10)
	add_child(bg)

	# Title
	var title = Label.new()
	title.text = "LABYRINTHE 3D"
	title.anchor_left   = 0.5
	title.anchor_right  = 0.5
	title.anchor_top    = 0.0
	title.anchor_bottom = 0.0
	title.offset_left   = -250
	title.offset_right  = 250
	title.offset_top    = 80
	title.offset_bottom = 160
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
	add_child(title)

	# Subtitle
	var sub = Label.new()
	sub.text = "Select Difficulty"
	sub.anchor_left   = 0.5
	sub.anchor_right  = 0.5
	sub.anchor_top    = 0.0
	sub.anchor_bottom = 0.0
	sub.offset_left   = -200
	sub.offset_right  = 200
	sub.offset_top    = 170
	sub.offset_bottom = 220
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 24)
	sub.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	add_child(sub)

	# Level buttons
	_add_level_button("EASY",   "",  Color(0.15, 0.65, 0.25), "easy",   280)
	_add_level_button("MEDIUM", "",  Color(0.75, 0.55, 0.05), "medium", 420)
	_add_level_button("HARD",   "",  Color(0.75, 0.15, 0.10), "hard",   560)

func _add_level_button(label: String, desc: String, color: Color, level: String, y: int) -> void:
	var btn = Button.new()
	btn.text = label
	btn.anchor_left   = 0.5
	btn.anchor_right  = 0.5
	btn.anchor_top    = 0.0
	btn.anchor_bottom = 0.0
	btn.offset_left   = -160
	btn.offset_right  = 160
	btn.offset_top    = y
	btn.offset_bottom = y + 70
	btn.add_theme_font_size_override("font_size", 28)
	btn.add_theme_color_override("font_color", Color.WHITE)

	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = color.lightened(0.3)
	style.border_width_left   = 2
	style.border_width_right  = 2
	style.border_width_top    = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left     = 10
	style.corner_radius_top_right    = 10
	style.corner_radius_bottom_left  = 10
	style.corner_radius_bottom_right = 10
	btn.add_theme_stylebox_override("normal",  style)

	var style_hover = style.duplicate()
	style_hover.bg_color = color.lightened(0.15)
	btn.add_theme_stylebox_override("hover", style_hover)

	var style_pressed = style.duplicate()
	style_pressed.bg_color = color.darkened(0.2)
	btn.add_theme_stylebox_override("pressed", style_pressed)

	add_child(btn)

	# Description label below button
	var desc_label = Label.new()
	desc_label.text = desc
	desc_label.anchor_left   = 0.5
	desc_label.anchor_right  = 0.5
	desc_label.anchor_top    = 0.0
	desc_label.anchor_bottom = 0.0
	desc_label.offset_left   = -200
	desc_label.offset_right  = 200
	desc_label.offset_top    = y + 75
	desc_label.offset_bottom = y + 105
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.add_theme_font_size_override("font_size", 16)
	desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	add_child(desc_label)

	# Wire up: set level and load game
	btn.pressed.connect(func():
		Config.selected_level = level
		get_tree().change_scene_to_file("res://scenes/Main.tscn")
	)
