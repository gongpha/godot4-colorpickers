extends AspectRatioContainer
class_name PickerShape

# Abstract Class of shape (no sliders)
# D O N T U S E I T D I R E C T L Y

const SQRT12 : float = 0.7071067811865475244008443621048490

const CURSOR := preload("res://resource/editor_data/color_picker_cursor.svg")

var hbox : HBoxContainer
var uv_draw : Control
var w_draw : Control
var uv : Control
var w : Control

var hide_w : bool = false

var uv_mat : ShaderMaterial
var w_mat : ShaderMaterial

# for circle
#	(deg, distance)
# else
#	(x, y)
var uv_input : Vector2

var w_input : float

enum ShapeType {
	SHAPE_RECTANGLE = 0,
	SHAPE_CIRCLE = 1,
	SHAPE_RECTANGLE_WHEEL = 2,
	SHAPE_TRIANGLE = 3
}
@export var shape : ShapeType = ShapeType.SHAPE_RECTANGLE :
	set(new_) : 
		shape = new_
		_set_shape(new_)
		

enum DraggingType {
	DRAGGING_NONE,
	DRAGGING_UV,
	DRAGGING_W,
}
var dragging : DraggingType = DraggingType.DRAGGING_NONE
var available_shapes : int = 0b0000

var color : Color

signal color_updated(col)

func _init() :
	minimum_size = Vector2(256 + 4 + 32, 256)
	
	hbox = HBoxContainer.new()
	#hbox.set_anchors_preset(Control.PRESET_WIDE)
	hbox.add_theme_constant_override("separation", 4)
	add_child(hbox)
	
	uv_mat = ShaderMaterial.new()
	uv_draw = Control.new()
	uv_draw.size_flags_horizontal = SIZE_EXPAND_FILL
	uv_draw.minimum_size = Vector2(256, 256)
	uv_draw.material = uv_mat
	uv_draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	uv_draw.connect("draw", Callable(self, "_draw_rect"), [uv_draw])
	hbox.add_child(uv_draw)
	
	uv = Control.new()
	uv.set_anchors_and_offsets_preset(Control.PRESET_WIDE)
	uv.connect("gui_input", Callable(self, "_uv_gui_input"))
	uv.connect("draw", Callable(self, "_uv_draw"))
	uv_draw.add_child(uv)
	
	w_mat = ShaderMaterial.new()
	w_draw = Control.new()
	w_draw.minimum_size = Vector2(32, 256)
	w_draw.material = w_mat
	w_draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	w_draw.connect("draw", Callable(self, "_draw_rect"), [w_draw])
	hbox.add_child(w_draw)
	
	w = Control.new()
	w.set_anchors_and_offsets_preset(Control.PRESET_WIDE)
	w.connect("gui_input", Callable(self, "_w_gui_input"))
	w.connect("draw", Callable(self, "_w_draw"))
	w_draw.add_child(w)
	
#	cursor = Control.new()
#	cursor.set_anchors_preset(Control.PRESET_WIDE)
#	cursor.connect("draw", Callable(self, "_cursor_draw"))
#	cursor.mouse_filter = Control.MOUSE_FILTER_IGNORE
#	add_child(cursor)
	
	_implement()
	_update_shape()
	_update_uv_value()
	_update_w_value()
	_update_control()
	_update_color()
	
func _get_wheel_uv_corner() -> Vector2 :
	var center : Vector2 = uv_draw.size / 2
	var ring_radius := Vector2(
		SQRT12 * uv_draw.size.x * 0.42,
		SQRT12 * uv_draw.size.y * 0.42
	)
	return Vector2(
		center.x - ring_radius.x,
		center.y - ring_radius.y
	)
	
func _get_wheel_uv_rect() -> Rect2 :
	var center : Vector2 = uv_draw.size / 2
	var ring_radius := Vector2(
		SQRT12 * uv_draw.size.x * 0.42,
		SQRT12 * uv_draw.size.y * 0.42
	)
	var corner := _get_wheel_uv_corner()
	return Rect2(corner, uv_draw.size - corner * 2)
	
func _uv_gui_input(event : InputEvent) :
	if event is InputEventMouseButton :
		if event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT :
			if shape == ShapeType.SHAPE_RECTANGLE_WHEEL :
				if !(_get_wheel_uv_rect().has_point(event.position)) :
					var center : Vector2 = uv.size / 2
					var dist : float = event.position.distance_to(center)
					if dist >= center.x * 0.84 and dist <= center.x :
						_set_w_input(event.position)
						dragging = DraggingType.DRAGGING_W
						return
					else :
						return
				
			_set_uv_input(event.position)
			dragging = DraggingType.DRAGGING_UV
		else :
			dragging = DraggingType.DRAGGING_NONE
	elif event is InputEventMouseMotion :
		if dragging == DraggingType.DRAGGING_UV :
			_set_uv_input(event.position)
		elif dragging == DraggingType.DRAGGING_W : # for wheel
			_set_w_input(event.position)
			
func _w_gui_input(event : InputEvent) :
	if event is InputEventMouseButton :
		if event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT :
			_set_w_input(event.position)
			dragging = DraggingType.DRAGGING_W
		else :
			dragging = DraggingType.DRAGGING_NONE
	elif event is InputEventMouseMotion :
		if dragging == DraggingType.DRAGGING_W :
			_set_w_input(event.position)
			
func _set_uv_input(mouse_pos : Vector2) :
	match shape :
		ShapeType.SHAPE_CIRCLE :
			var center : Vector2 = uv_draw.size / 2
			var dist : float = clamp(mouse_pos.distance_to(center) / center.x, 0, 1)
			
			uv_input = Vector2(center.angle_to_point(mouse_pos), dist)
		ShapeType.SHAPE_RECTANGLE_WHEEL :
			var corner := _get_wheel_uv_corner()
			var rect := Rect2(corner, uv_draw.size - corner * 2)
			
			mouse_pos -= corner
			uv_input = (mouse_pos / rect.size).clamp(Vector2(), Vector2.ONE)
		_ :
			# else       This is Vector2
			uv_input = (mouse_pos / uv_draw.size).clamp(Vector2(), Vector2.ONE)
	
	_update_uv_value()
	_update_color()
	_update_control()
	
func _set_w_input(mouse_pos : Vector2) :
	if shape == ShapeType.SHAPE_RECTANGLE_WHEEL :
		var center : Vector2 = uv_draw.size / 2
		w_input = center.angle_to_point(mouse_pos)
	else :
		w_input = clamp(mouse_pos.y / uv_draw.size.y, 0, 1)
	
	_update_w_value()
	_update_color()
	_update_control()
	
func _linear2h(rad : float) -> float :
	return (rad if rad >= 0 else (TAU + rad)) / TAU
	
func _uv_draw() :
	match shape :
		ShapeType.SHAPE_CIRCLE :
			var center : Vector2 = uv_draw.size / 2
			var pos : Vector2
			pos.x = 0.5 + (0.5 * cos(uv_input.x) * uv_input.y)
			pos.y = 0.5 + (0.5 * sin(uv_input.x) * uv_input.y)
			uv.draw_texture(CURSOR, uv_draw.size * pos - (CURSOR.get_size() / 2))
		ShapeType.SHAPE_RECTANGLE_WHEEL :
			var points : PackedVector2Array
			var colors : PackedColorArray
			var colors2 : PackedColorArray
			var center : Vector2 = uv.size / 2.0
			#var col : Color = color;
			
			uv.draw_circle(center, 3, Color.RED)
			
			points.resize(4)
			colors.resize(4)
			colors2.resize(4)
			
			var ring_radius := Vector2(
				SQRT12 * uv.size.x * 0.42,
				SQRT12 * uv.size.y * 0.42
			)

			points.set(0, center - Vector2(ring_radius.x, ring_radius.y))
			points.set(1, center + Vector2(ring_radius.x, -ring_radius.y))
			points.set(2, center + Vector2(ring_radius.x, ring_radius.y))
			points.set(3, center + Vector2(-ring_radius.x, ring_radius.y))
			colors.set(0, Color(1, 1, 1, 1))
			colors.set(1, Color(1, 1, 1, 1))
			colors.set(2, Color(0, 0, 0, 1))
			colors.set(3, Color(0, 0, 0, 1))
			uv.draw_polygon(points, colors)
			
			var h := _linear2h(w_input)

			var col := Color.from_hsv(h, 1, 1)
			col.a = 0
			colors2.set(0, col)
			col.a = 1
			colors2.set(1, col)
			col = col.from_hsv(h, 1, 0)
			# col.a = 1
			colors2.set(2, col)
			col.a = 0
			colors2.set(3, col)
			uv.draw_polygon(points, colors2)
			
			# line
			var pos := Vector2(
				0.5 + 0.5 * cos(w_input) * 0.92,
				0.5 + 0.5 * sin(w_input) * 0.92
			)
			uv.draw_texture(CURSOR, (uv.size * pos - (CURSOR.get_size() / 2)).round())
			
			uv.draw_texture(CURSOR, points[0] + ring_radius * 2 * uv_input - (CURSOR.get_size() / 2))
		_ :
			uv.draw_texture(CURSOR, uv.size * uv_input - (CURSOR.get_size() / 2))
	
func _w_draw() :
	w.draw_line(
		Vector2(0, w_input * w_draw.size.y),
		Vector2(w_draw.size.x, w_input * w_draw.size.y),
		Color.WHITE
	)
	
func _draw_rect(control : Control) :
	control.draw_rect(Rect2(Vector2(), control.size), Color.WHITE)
	
func _update_uv_value() :
	uv_mat.set_shader_param("uv", uv_input)
	w_mat.set_shader_param("uv", uv_input)
	
func _update_w_value() :
	uv_mat.set_shader_param("w", w_input)
	w_mat.set_shader_param("w", w_input)
	
func _update_color() :
	_make_color()
	emit_signal("color_updated", color)
	
func _update_control() :
	uv_draw.update()
	w_draw.update()
	uv.update()
	w.update()
	
func _set_shape(new_ : int) :
	#cursor.update()
	_update_shape()
	_reset_color()
	_update_color()
	
##########################################

func set_color(new_ : Color) :
	if color == new_ :
		return
	color = new_
	_reset_color()
	_update_control()

# should internal ? O^O
# for contacting between
func set_color_hsv(hsv : Vector3) :
	pass
	
##########################################
func _update_shape() :
	pass
	
func _implement() :
	pass

func _make_color() :
	return

func _reset_color() :
	return
