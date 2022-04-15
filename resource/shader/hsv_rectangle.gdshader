shader_type canvas_item;

// new shader (-w-)
// can use as UV and W

vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec3 checker(vec2 sps, vec2 suv) {
	// checker
	vec2 ps = 1.0 / sps;
	vec2 uv = suv;
	uv.x *= ps.x / ps.y;
	float result = sign(mod(dot(vec2(1.0), step(vec2(0.5), fract(uv * 64.0))), 2.0));
	return vec3(mix(0.5, 1.0, result));
}

vec4 put_color_bg(vec4 c, vec2 sps, vec2 suv) {
	return mix(vec4(checker(sps, suv), 1.0), c, c.w);
}

uniform int mode;

uniform float w;
uniform vec4 c1;
uniform vec4 c2;

/*
	mode :
		0 = HSV UV (use C1.x)
		1 = HSV (VERTICAL) 
		2 = HSV (HORIZONTAL)
		3 = LINEAR (VERTICAL) (use C1, C2)
		4 = LINEAR (HORIZONTAL) (use C1, C2)
		5 = LINEAR WITH CHECKER (VERTICAL) (use C1, C2)
		6 = LINEAR WITH CHECKER (HORIZONTAL) (use C1, C2)
*/

void fragment()
{
	// I hope using if-else for uniform won't hit performance as much
	
	if (mode == 0) {
		COLOR.xyz = hsv2rgb(vec3(
			w,
			UV.x,
			1.0 - UV.y
		));
	} else if (mode == 1) {
		COLOR.xyz = hsv2rgb(vec3(
			UV.y,
			1.0,
			1.0
		));
	} else if (mode == 2) {
		COLOR.xyz = hsv2rgb(vec3(
			UV.x,
			1.0,
			1.0
		));
	} else if (mode == 3) {
		COLOR = mix(
			c1,
			c2,
			UV.y
		);
	} else if (mode == 4) {
		COLOR = mix(
			c1,
			c2,
			UV.x
		);
	} else if (mode == 5) {
		COLOR = mix(
			put_color_bg(c1, SCREEN_PIXEL_SIZE, SCREEN_UV),
			put_color_bg(c2, SCREEN_PIXEL_SIZE, SCREEN_UV),
			UV.y
		);
	} else if (mode == 6) {
		COLOR = mix(
			put_color_bg(c1, SCREEN_PIXEL_SIZE, SCREEN_UV),
			put_color_bg(c2, SCREEN_PIXEL_SIZE, SCREEN_UV),
			UV.x
		);
	}
}