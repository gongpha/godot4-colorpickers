extends VBoxContainer
class_name PickerSliders

# ABSTRCT Sliders group. NO shape ^-^

var color : Color = Color(0, 0, 0, 0)
		
var updating : bool = false

var colorized_sliders : bool = true :
	set(new_) :
		if colorized_sliders == new_ :
			return
			
		colorized_sliders = new_
		
		for s in sliders :
			s.set_coloring(colorized_sliders)

class SliderItem :
	var bg : Panel
	var hbox : HBoxContainer
	var slider : HSlider
	var spin_box : SpinBox
	var update_call : StringName#Callable
		
	var empty : StyleBoxEmpty
	var grabber : Texture2D
	
	var material : ShaderMaterial
	
	func get_value() -> float :
		return slider.value
		
	func set_value(val : float) :
		slider.value = val
		spin_box.value = val
		
	func set_coloring(yes : bool) :
		if yes and material != null :
			bg.remove_theme_stylebox_override("panel")
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
var empty := StyleBoxEmpty.new()

var default_slider_panel : StyleBox = preload("res://resource/theme_element/slider_panel.tres")
var default_slider_grabber : Texture2D = preload("res://resource/editor_data/color_picker_cursor.svg")

# CONSTANT
const C_label_width : int = 16

signal color_updated(col)

func add_slider(
	label_text : String,
	update_call : StringName,#update_call : Callable, << Callable still Buggy
	shader : Shader,
	max_val : float,
	step : float
) -> SliderItem :
	var item := SliderItem.new()
	item.empty = empty
	item.grabber = default_slider_grabber
	
	item.hbox = HBoxContainer.new()
	item.hbox.set_anchors_and_offsets_preset(Control.PRESET_WIDE)
	
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
	bg.minimum_size = Vector2(0, 16)
	bg.add_theme_stylebox_override("panel", default_slider_panel)
	
	item.bg = bg
	
	
	var slider := HSlider.new()
	slider.max_value = max_val
	slider.step = step
	slider.set_anchors_and_offsets_preset(Control.PRESET_WIDE)
	
	slider.connect("value_changed", Callable(self, "_slider_val_changed"), [item])
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
	
	sliders.append(item)
	
	add_child(item.hbox)
	
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
	_reset_color()

##########################################

func _slider_val_changed(val : float, item : SliderItem) :
	if updating :
		return
		
	_update_all_sliders()
	_update_color()
	
func _update_color() :
	_make_color()
	emit_signal("color_updated", color)
	
func _update_all_sliders() :
	for i in sliders :
		if i.update_call != StringName() :
			call(i.update_call, i)
			#item.update_call.call(item) U_U (B U G)

###########################################

func _reset_color() :
	return

func _make_color() :
	return
