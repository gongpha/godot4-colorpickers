extends Container
class_name PickerShape

# Abstract Class of shape (no sliders)
# D O N T U S E I T D I R E C T L Y

const CURSOR := preload("res://resource/editor_data/color_picker_cursor.svg")

var hbox : HBoxContainer
var uv : ColorRect
var w : ColorRect
var cursor : Control

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
	SHAPE_RECTAGLE_WHEEL = 2,
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

@export_flags("Rectangle", "Circle", "Rectangle Wheel", "Triangle") var available_shapes : int = 0b0000

var color : Color

signal color_updated(col)

func _init() :
	minimum_size = Vector2(256 + 4 + 32, 256)
	
	hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_WIDE)
	hbox.add_theme_constant_override("separation", 4)
	add_child(hbox)
	
	uv_mat = ShaderMaterial.new()
	uv = ColorRect.new()
	uv.size_flags_horizontal = SIZE_EXPAND_FILL
	uv.minimum_size = Vector2(256, 256)
	uv.material = uv_mat
	uv.connect("gui_input", Callable(self, "_uv_gui_input"))
	hbox.add_child(uv)
	
	w_mat = ShaderMaterial.new()
	w = ColorRect.new()
	w.minimum_size = Vector2(32, 256)
	w.material = w_mat
	w.connect("gui_input", Callable(self, "_w_gui_input"))
	hbox.add_child(w)
	
	cursor = Control.new()
	cursor.set_anchors_preset(Control.PRESET_WIDE)
	cursor.connect("draw", Callable(self, "_cursor_draw"))
	cursor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cursor)
	
	_implement()
	_update_shape()
	_update_uv_value()
	_update_w_value()
	_update_color()
	
func _uv_gui_input(event : InputEvent) :
	if event is InputEventMouseButton :
		if event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT :
			_set_uv_input(event.position)
			dragging = DraggingType.DRAGGING_UV
		else :
			dragging = DraggingType.DRAGGING_NONE
	elif event is InputEventMouseMotion :
		if dragging == DraggingType.DRAGGING_UV :
			_set_uv_input(event.position)
			
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
			var center : Vector2 = uv.size / 2
			var dist : float = clamp(mouse_pos.distance_to(center) / center.x, 0, 1)
			
			uv_input = Vector2(center.angle_to_point(mouse_pos), dist)
		_ :
			# else       This is Vector2
			uv_input = (mouse_pos / uv.size).clamp(Vector2(), Vector2.ONE)
	
	_update_uv_value()
	_update_color()
	cursor.update()
	
func _set_w_input(mouse_pos : Vector2) :
	w_input = clamp(mouse_pos.y / uv.size.y, 0, 1)
	
	_update_w_value()
	_update_color()
	cursor.update()
	
func _cursor_draw() :
	match shape :
		ShapeType.SHAPE_CIRCLE :
			var center : Vector2 = uv.size / 2
			var pos : Vector2
			pos.x = 0.5 + (0.5 * cos(uv_input.x) * uv_input.y)
			pos.y = 0.5 + (0.5 * sin(uv_input.x) * uv_input.y)
			cursor.draw_texture(CURSOR, uv.position + uv.size * pos - (CURSOR.get_size() / 2))
		_ :
			cursor.draw_texture(CURSOR, uv.position + uv.size * uv_input - (CURSOR.get_size() / 2))
	cursor.draw_line(
		w.position + Vector2(0, w_input * w.size.y),
		w.position + Vector2(w.size.x, w_input * w.size.y),
		Color.WHITE
	)
	
func _update_uv_value() :
	uv_mat.set_shader_param("uv", uv_input)
	w_mat.set_shader_param("uv", uv_input)
	
func _update_w_value() :
	uv_mat.set_shader_param("w", w_input)
	
func _update_color() :
	_make_color()
	emit_signal("color_updated", color)
	
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
	
##########################################
func _update_shape() :
	pass
	
func _implement() :
	pass

func _make_color() :
	return

func _reset_color() :
	return
