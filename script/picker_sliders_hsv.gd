extends PickerSliders
class_name PickerSlidersHSV

func _init() :
	super._init()
	#smaterial.set_shader_param("mode", 3)
	var shader := preload("res://resource/shader/hsv_rectangle.gdshader")
	
	var item : PickerSliders.SliderItem
	
	item = add_slider("H", StringName(), shader, 359, 1)
	item.material.set_shader_param("mode", 2)
	
	item = add_slider("S", "_set_s", shader, 100, 1)
	item.material.set_shader_param("mode", 4)
	
	item = add_slider("V", "_set_v", shader, 100, 1)
	item.material.set_shader_param("mode", 4)
	
	force_update_sliders()

func _set_s(item) : # bug : typing
	var h : float = get_slider_item(0).get_value() / 359.0
	var v : float = get_slider_item(2).get_value() / 100.0
	
	var c : Color
	c = c.from_hsv(h, 0.0, v)
	item.material.set_shader_param("c1", c)
	c = c.from_hsv(h, 1.0, v)
	item.material.set_shader_param("c2", c)
	
func _set_v(item) : # bug : typing
	var h : float = get_slider_item(0).get_value() / 359.0
	var s : float = get_slider_item(1).get_value() / 100.0
	
	var c : Color
	c = c.from_hsv(h, s, 0.0)
	item.material.set_shader_param("c1", c)
	c = c.from_hsv(h, s, 1.0)
	item.material.set_shader_param("c2", c)

func _make_color() :
	color = Color.from_hsv(
		get_slider_item(0).get_value() / 359.0,
		get_slider_item(1).get_value() / 100.0,
		get_slider_item(2).get_value() / 100.0
		#get_slider_item(3).get_value() / 255.0
	)
	
func _reset_color() :
	updating = true
	get_slider_item(0).set_value(color.h * 359)
	get_slider_item(1).set_value(color.s * 100)
	get_slider_item(2).set_value(color.v * 100)
	#get_slider_item(3).set_value(color.a)
	updating = false
	
	force_update_sliders()
