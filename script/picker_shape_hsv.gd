extends PickerShape
class_name PickerShapeHSV

func _init() :
	super._init()
	available_shapes = 0b0111

func _update_shape() :
	match shape :
		ShapeType.SHAPE_RECTANGLE :
			uv_mat.shader = preload("res://resource/shader/hsv_rectangle.gdshader")
			uv_mat.set_shader_param("mode", 0)
			w_mat.shader = uv_mat.shader
			w_mat.set_shader_param("mode", 1)
			w_draw.show()
			
		ShapeType.SHAPE_CIRCLE :
			uv_mat.shader = preload("res://resource/shader/hsv_circle.gdshader")
			w_mat.shader = preload("res://resource/shader/hsv_rectangle.gdshader")
			w_mat.set_shader_param("mode", 3)
			w_mat.set_shader_param("c1", Color.WHITE)
			w_mat.set_shader_param("c2", Color.BLACK)
			w_draw.show()
			
		ShapeType.SHAPE_RECTANGLE_WHEEL :
			uv_mat.shader = preload("res://resource/shader/hsv_wheel.gdshader")
			w_draw.hide()

func _make_color() :
	var a := color.a
	match shape :
		ShapeType.SHAPE_RECTANGLE :
			color.h = w_input
			color.s = uv_input.x
			color.v = 1.0 - uv_input.y
			
		ShapeType.SHAPE_RECTANGLE_WHEEL :
			color.h = _linear2h(w_input)
			color.s = uv_input.x
			color.v = 1.0 - uv_input.y
			
		ShapeType.SHAPE_CIRCLE :
			color.h = _linear2h(uv_input.x)
			color.s = uv_input.y
			color.v = 1.0 - w_input
	color.a = a

func _reset_color() :
	match shape :
		ShapeType.SHAPE_RECTANGLE, ShapeType.SHAPE_RECTANGLE_WHEEL :
			w_input = color.h
			uv_input.x = color.s
			uv_input.y = 1.0 - color.v
			
		ShapeType.SHAPE_RECTANGLE_WHEEL :
			w_input = color.h * TAU
			uv_input.x = color.s
			uv_input.y = 1.0 - color.v
			
		ShapeType.SHAPE_CIRCLE :
			#var rad : float = color.h
			uv_input.x =  color.h * TAU
			uv_input.y = color.s
			w_input = 1.0 - color.v
		
	_update_uv_value()
	_update_w_value()
