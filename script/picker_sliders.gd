extends VBoxContainer
class_name PickerSliders

# ABSTRCT Sliders group. NO shape ^-^

var color : Color
		
var updating : bool = false

@export var colorized_sliders : bool = true :
	set(new_) :
		if colorized_sliders == new_ :
			return
			
		colorized_sliders = new_
		
		for s in sliders :
			s.set_coloring(colorized_sliders)
		alpha_slider.set_coloring(colorized_sliders)
			
@export var edit_alpha : bool = true :
	set(new_) :
		if edit_alpha == new_ :
			return
		
		edit_alpha = new_
		
		_update_alpha_visibility()
			
####################

var hsep : HSeparator

class SliderItem :
	var bg : Panel
	var hbox : HBoxContainer
	var slider : HSlider
	var spin_box : SpinBox
	var update_call : StringName#Callable
		
	var empty : StyleBoxEmpty
	var color_panel : StyleBox
	var grabber : Texture2D
	
	var material : ShaderMaterial
	
	func get_value() -> float :
		return slider.value
		
	func set_value(val : float) :
		slider.value = val
		spin_box.value = val
		
	func set_coloring(yes : bool) :
		if yes and material != null :
			bg.add_theme_stylebox_override("panel", color_panel)
			slider.add_theme_stylebox_override("slider", empty)
			slider.add_theme_icon_override("grabber", grabber)
			slider.add_theme_icon_override("grabber_highlight", grabber)
			slider.add_theme_icon_override("grabber_disabled", grabber)
		else :
			bg.add_theme_stylebox_override("panel", empty)
			slider.remove_theme_stylebox_override("slider")
			slider.remove_theme_icon_override("grabber")
			slider.remove_theme_icon_override("grabber_highlight")
			slider.remove_theme_icon_override("grabber_disabled")

var sliders : Array[SliderItem]
var alpha_slider : SliderItem
var empty := StyleBoxEmpty.new()

var default_slider_panel : StyleBox = preload("res://resource/theme_element/slider_panel.tres")
var default_slider_grabber : Texture2D = preload("res://resource/editor_data/color_picker_cursor.svg")

# CONSTANT
const C_label_width : int = 16

signal color_updated(col)

func _init() :
	hsep = HSeparator.new()
	add_child(hsep)
	
	alpha_slider = _create_slider(
		"A",
		"_set_a",
		preload("res://resource/shader/hsv_rectangle.gdshader"),
		255,
		1
	)
	
	add_child(alpha_slider.hbox)
	alpha_slider.material.set_shader_parameter("mode", 6)
	
	alpha_slider.set_value(color.a * 255)

func add_slider(
	label_text : String,
	update_call : StringName,#update_call : Callable, << Callable still Buggy
	shader : Shader,
	max_val : float,
	step : float
) -> SliderItem :
	var item := _create_slider(label_text, update_call, shader, max_val, step)
	if item :
		sliders.append(item)
		add_child(item.hbox)
		move_child(item.hbox, hsep.get_index())
	return item
	
func _create_slider(
	label_text : String,
	update_call : StringName,#update_call : Callable, << Callable still Buggy
	shader : Shader,
	max_val : float,
	step : float
) -> SliderItem :
	var item := SliderItem.new()
	item.empty = empty
	item.grabber = default_slider_grabber
	item.color_panel = default_slider_panel
	
	item.hbox = HBoxContainer.new()
	item.hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	var label := Label.new()
	label.text = label_text
	label.size_flags_vertical = SIZE_EXPAND_FILL
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_custom_minimum_size(Vector2(C_label_width, 0))
	
	var bg = Panel.new()
	if shader :
		var smaterial := ShaderMaterial.new()
		smaterial.shader = shader
		item.material = smaterial
		bg.material = smaterial
		
	bg.size_flags_horizontal = SIZE_EXPAND_FILL
	bg.size_flags_vertical = SIZE_SHRINK_CENTER
	bg.custom_minimum_size = Vector2(0, 16)
	
	item.bg = bg
	
	
	var slider := HSlider.new()
	slider.max_value = max_val
	slider.step = step
	slider.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	slider.value_changed.connect(_slider_val_changed.bind(item))
	item.slider = slider
		
	bg.add_child(slider)
	
	var spinbox := SpinBox.new()
	spinbox.max_value = max_val
	spinbox.step = step
	slider.share(spinbox)
	item.spin_box = spinbox
	
	item.hbox.add_child(label)
	item.hbox.add_child(bg)
	item.hbox.add_child(item.spin_box)
	
	item.update_call = update_call
	
	item.set_coloring(colorized_sliders)
	return item

func get_slider_item(idx : int) -> SliderItem :
	return sliders[idx]
	
func force_update_sliders() :
	_update_all_sliders()
	
func set_color(new_ : Color) :
	if color == new_ :
		return
	color = new_
	
	alpha_slider.set_value(color.a * 255)
	_reset_color()

##########################################

func _slider_val_changed(val : float, item : SliderItem) :
	if updating :
		return
		
	_update_color()
	_update_all_sliders()
	
	
func _update_color() :
	_make_color()
	color.a = alpha_slider.get_value() / 255.0
	
	emit_signal("color_updated", color)
	
func _update_all_sliders() :
	for i in sliders :
		if i.update_call != StringName() :
			call(i.update_call, i)
			#item.update_call.call(item) U_U (B U G)
			
	_update_alpha()
			
func _update_alpha() :
	if not edit_alpha :
		return
		
	var c := color
	c.a = 0
	alpha_slider.material.set_shader_parameter("c1", c)
	c.a = 1
	alpha_slider.material.set_shader_parameter("c2", c)
	
func _update_alpha_visibility() :
	alpha_slider.hbox.visible = edit_alpha
	hsep.visible = edit_alpha
	
	_update_alpha()

###########################################

func _reset_color() :
	return

func _make_color() :
	return
