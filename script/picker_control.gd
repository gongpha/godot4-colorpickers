extends VBoxContainer
class_name PickerControl

var shape_content : VBoxContainer # Or any BOXcontainer

var samples_hbox : HBoxContainer
var pick_button : Button
var sample_rect : ColorRect
var shape_button : MenuButton

var tab_hbox : HBoxContainer
var tab : HBoxContainer
var tab_more : MenuButton
var tab_content : VBoxContainer # Or any BOXcontainer
var colorized_option_id : int

var code_hex_hbox : HBoxContainer
var code_hex_line : LineEdit
var code_hex_toggle : Button
var use_hex : bool = true

var group : ButtonGroup

var current_mode : int = -1
var current_shape_mode : int = -1

class Mode :
	var button : Button
	var sliders : PickerSliders
	var shape : PickerShape

var modes : Array[Mode]

const I_pipette := preload("res://resource/editor_data/color_picker_pipette.svg")
const T_checker := preload("res://resource/editor_data/mini_checkerboard.svg")

###############

var color : Color
var old_color : Color

var colorized_sliders : bool = true :
	set(new_) :
		colorized_sliders = new_
		_update_appearance()
		
var display_old_color : bool = true :
	set = set_display_old_color
func _init() :
	#shape = PickerShape.new()
	#shape.size_flags_horizontal = SIZE_EXPAND_FILL
	#add_child(shape)
	
	group = ButtonGroup.new()
	
	shape_content = VBoxContainer.new()
	
	samples_hbox = HBoxContainer.new()
	samples_hbox.size_flags_horizontal = SIZE_EXPAND_FILL
	samples_hbox.add_theme_constant_override("separation", 4)
	pick_button = Button.new()
	pick_button.icon = I_pipette
	pick_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pick_button.minimum_size = Vector2(32, 32)
	
	shape_button = MenuButton.new()
	shape_button.flat = false
	shape_button.icon = null # soon(tm)
	shape_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shape_button.minimum_size = Vector2(32, 32)
	shape_button.get_popup().connect("id_pressed", Callable(self, "_shape_selected"))
	
	var popup := shape_button.get_popup()
	popup.add_radio_check_item("Rectangle", 0)
	popup.add_radio_check_item("Circle", 1)
	popup.add_radio_check_item("Rectangle Wheel", 2)
	popup.add_radio_check_item("Triangle", 3)
	
	sample_rect = ColorRect.new()
	sample_rect.size_flags_horizontal = SIZE_EXPAND_FILL
	sample_rect.connect("draw", Callable(self, "_sample_draw"))
	sample_rect.connect("gui_input", Callable(self, "_sample_input"))
	
	tab_hbox = HBoxContainer.new()
	tab = HBoxContainer.new()
	tab.size_flags_horizontal = SIZE_EXPAND_FILL
	
	tab_more = MenuButton.new()
	tab_more.flat = false
	tab_more.text = "..."
	tab_more.minimum_size = Vector2(32, 32)
	tab_more.get_popup().connect("id_pressed", Callable(self, "_mode_selected"))
	tab_content = VBoxContainer.new()
	tab_content.size_flags_horizontal = SIZE_EXPAND_FILL
	
	code_hex_hbox = HBoxContainer.new()
	code_hex_toggle = Button.new()
	code_hex_line = LineEdit.new()
	
	code_hex_toggle.minimum_size = Vector2(32, 32)
	code_hex_toggle.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	code_hex_toggle.connect("pressed", Callable(self, "_code_hex_toggle"))
	code_hex_toggle.text = '#'
	code_hex_line.size_flags_horizontal = SIZE_EXPAND_FILL
	
	#
	
	samples_hbox.add_child(pick_button)
	samples_hbox.add_child(sample_rect)
	samples_hbox.add_child(shape_button)
	
	tab_hbox.add_child(tab)
	tab_hbox.add_child(tab_more)
	
	code_hex_hbox.add_child(code_hex_toggle)
	code_hex_hbox.add_child(code_hex_line)
	
	add_child(shape_content)
	add_child(samples_hbox)
	add_child(tab_hbox)
	add_child(tab_content)
	add_child(code_hex_hbox)
	
	_implement_default_controls()
	
	_update_codehex()

func add_mode(sliders : PickerSliders, shape : PickerShape) :
	var mode := Mode.new()
	mode.sliders = sliders
	
	var call := Callable(self, "_set_color")
	
	sliders.set_anchors_and_offsets_preset(Control.PRESET_WIDE)
	sliders.connect("color_updated", call, [false, true])
	
	mode.shape = shape
	if !shape.is_connected("color_updated", call) :
		shape.connect("color_updated", call, [true, false])
	
	var button := Button.new()
	button.text = sliders.name
	button.focus_mode = Control.FOCUS_NONE
	button.size_flags_horizontal = SIZE_EXPAND_FILL
	
	button.add_theme_stylebox_override(
		"pressed",
		get_theme_stylebox("tab_selected", "TabContainer")
	)
	button.add_theme_stylebox_override(
		"normal",
		get_theme_stylebox("tab_unselected", "TabContainer")
	)
	button.add_theme_stylebox_override(
		"disabled",
		get_theme_stylebox("tab_disabled", "TabContainer")
	)
	button.add_theme_stylebox_override(
		"hover",
		get_theme_stylebox("tab_selected", "TabContainer")
	)
	button.toggle_mode = true
	button.button_group = group
	tab.add_child(button)
	
	mode.button = button
	
	modes.append(mode)
	_update_popup()
	
	var id := modes.size() - 1
	button.connect("pressed", Callable(self, "_mode_selected"), [id])
	
	if id == 0 :
		# select first
		_mode_selected(id)
		
func _set_color(col : Color, update_sliders : bool, update_shape : bool) :
	if color == col :
		return
	color = col
	_reset_color(update_sliders, update_shape)
	
func _update_popup() :
	var popup := tab_more.get_popup()
	popup.clear()
	
	for m in modes :
		popup.add_radio_check_item(m.button.text)
		#var id := popup.item_count - 1
		
	popup.add_separator()
	popup.add_check_item("Colorized Sliders")
	colorized_option_id = popup.item_count - 1
	popup.set_item_checked(colorized_option_id, true)
		
	# reselect
	popup.set_item_checked(current_mode, true)
	
func _update_shape_popup() :
	if current_mode == -1 :
		return
		
	var popup := shape_button.get_popup()
	var mode : Mode = modes[current_mode]
	
	var first_available : int = -1
	
	for i in popup.item_count :
		if mode.shape.available_shapes & (1 << i) :
			# available
			popup.set_item_disabled(i, false)
			if first_available == -1 :
				first_available = i
		else :
			popup.set_item_disabled(i, true)
			if current_shape_mode == i :
				current_shape_mode == -1
			
	if current_shape_mode == -1 :
		if first_available != -1 :
			_shape_selected(first_available)
			return
			
	current_shape_mode = -2
	_shape_selected(-1)
		
func _mode_selected(id : int) :
	var popup := tab_more.get_popup()
	
	if id == colorized_option_id :
		colorized_sliders = !popup.is_item_checked(id)
		popup.set_item_checked(colorized_option_id, colorized_sliders)
		return
	
	if current_mode == id :
		return
	
	if current_mode != -1 :
		var mode := modes[current_mode]
		popup.set_item_checked(current_mode, false)
		mode.button.button_pressed = false
		tab_content.remove_child(mode.sliders)
		
	current_mode = id
	
	if current_mode != -1 :
		var mode := modes[current_mode]
		popup.set_item_checked(current_mode, true)
		mode.button.button_pressed = true
		tab_content.add_child(mode.sliders)
		
	_update_shape_popup()
		
	_reset_color(true, true)
	
func _shape_selected(id : int) :
	var popup := shape_button.get_popup()
	
	if current_shape_mode == id :
		return
	
	if current_shape_mode >= 0 :
		var mode := modes[current_shape_mode]
		popup.set_item_checked(current_shape_mode, false)
		shape_content.remove_child(mode.shape)
		
	current_shape_mode = id
	
	if current_shape_mode != -1 :
		var mode := modes[current_shape_mode]
		popup.set_item_checked(current_shape_mode, true)
		shape_content.add_child(mode.shape)
		mode.shape.shape = current_shape_mode
		
	_reset_color(true, true)
		
func _update_appearance() :
	for m in modes :
		(m as Mode).sliders.colorized_sliders = colorized_sliders
		
func _reset_color(update_sliders : bool, update_shape : bool) :
	var mode : Mode
		
	if current_mode != -1 :
		mode = modes[current_mode]
		
		if update_sliders :
			mode.sliders.set_color(color)
			#print("SLIDER")
			
		if update_shape :
			mode.shape.set_color(color)
			#print("SHAPE")
		
	_update_codehex()
	sample_rect.update()
		
func _code_hex_toggle() :
	use_hex = !use_hex
	if use_hex :
		code_hex_toggle.icon = null
		code_hex_toggle.text = '#'
		code_hex_line.editable = true
	else :
		code_hex_toggle.icon = preload("res://resource/editor_data/Script.svg")#get_theme_icon("Script") # + "EditorIcons" when in C++
		code_hex_toggle.text = String()
		code_hex_line.editable = false
	_update_codehex()
		
func _update_codehex() :
	if use_hex :
		code_hex_line.text = color.to_html()
	else :
		code_hex_line.text = ("Color(" +
			String.num(color.r, 3) + ", " +
			String.num(color.g, 3) + ", " +
			String.num(color.b, 3) + ")"
		)
		
func _sample_draw() :
	var rect_new : Rect2
	if display_old_color :
		rect_new = Rect2(
			sample_rect.size * Vector2(0.5, 0), sample_rect.size * Vector2(0.5, 1)
		)
		
		var rect_old := Rect2(
			Vector2(), sample_rect.size * Vector2(0.5, 1)
		)
		
		if old_color.a < 1.0 :
			sample_rect.draw_texture_rect(T_checker, rect_old, true)
		
		sample_rect.draw_rect(rect_old, old_color)
	else :
		rect_new = Rect2(
			Vector2(0, 0), sample_rect.size
		)
		
	if color.a < 1.0 :
		sample_rect.draw_texture_rect(T_checker, rect_new, true)
	sample_rect.draw_rect(rect_new, color)
	
func _sample_input(event) :
	if event is InputEventMouseButton :
		if event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT :
			var rect_old := Rect2(
				Vector2(), sample_rect.size * Vector2(0.5, 1)
			)
			
			if rect_old.has_point(event.position) :
				set_color(old_color)
				

func _implement_default_controls() :
	var sliders : PickerSliders = PickerSlidersRGBA.new()
	var shape : PickerShape = PickerShapeHSV.new()
	sliders.name = "RGB"
	add_mode(sliders, shape)
	
	sliders = PickerSlidersHSV.new()
	sliders.name = "HSV"
	add_mode(sliders, shape)

#######################

func _ready() :
	_reset_color(true, true)

func set_color(new_ : Color) :
	_set_color(new_, true, true)
	
func set_old_color(new_ : Color) :
	if old_color == new_ :
		return
	old_color = new_
	sample_rect.update()

func set_display_old_color(new_ : bool) :
	display_old_color = new_
	sample_rect.update()
