extends PickerSliders
class_name PickerSlidersRGBA

func _init() :
	#smaterial.set_shader_param("mode", 3)
	var shader := preload("res://resource/shader/hsv_rectangle.gdshader")
	
	var item : PickerSliders.SliderItem
	
	item = add_slider("R", "_set_r", shader, 255, 1)
	item.material.set_shader_param("mode", 4)
	
	item = add_slider("G", "_set_g", shader, 255, 1)
	item.material.set_shader_param("mode", 4)
	
	item = add_slider("B", "_set_b", shader, 255, 1)
	item.material.set_shader_param("mode", 4)
	
	item = add_slider("A", "_set_a", shader, 255, 1)
	item.material.set_shader_param("mode", 6)
	
	force_update_sliders()

func _set_r(item) : # bug : typing
	var g : float = get_slider_item(1).get_value() / 255.0
	var b : float = get_slider_item(2).get_value() / 255.0
	
	var c : Color
	c = Color(0.0, g, b)
	item.material.set_shader_param("c1", c)
	c = Color(1.0, g, b)
	item.material.set_shader_param("c2", c)
	
func _set_g(item) : # bug : typing
	var r : float = get_slider_item(0).get_value() / 255.0
	var b : float = get_slider_item(2).get_value() / 255.0
	
	var c : Color
	c = Color(r, 0.0, b)
	item.material.set_shader_param("c1", c)
	c = Color(r, 1.0, b)
	item.material.set_shader_param("c2", c)
	
func _set_b(item) : # bug : typing
	var r : float = get_slider_item(0).get_value() / 255.0
	var g : float = get_slider_item(1).get_value() / 255.0
	
	var c : Color
	c = Color(r, g, 0.0)
	item.material.set_shader_param("c1", c)
	c = Color(r, g, 1.0)
	item.material.set_shader_param("c2", c)
	
func _set_a(item) : # bug : typing
	var r : float = get_slider_item(0).get_value() / 255.0
	var g : float = get_slider_item(1).get_value() / 255.0
	var b : float = get_slider_item(2).get_value() / 255.0
	
	var c : Color
	c = Color(r, g, b, 0.0)
	item.material.set_shader_param("c1", c)
	c = Color(r, g, b, 1.0)
	item.material.set_shader_param("c2", c)

func _make_color() :
	color = Color(
		get_slider_item(0).get_value() / 255.0,
		get_slider_item(1).get_value() / 255.0,
		get_slider_item(2).get_value() / 255.0,
		get_slider_item(3).get_value() / 255.0
	)


func _reset_color() :
	updating = true
	get_slider_item(0).set_value(color.r * 255)
	get_slider_item(1).set_value(color.g * 255)
	get_slider_item(2).set_value(color.b * 255)
	get_slider_item(3).set_value(color.a * 255)
	updating = false
	
	force_update_sliders()
