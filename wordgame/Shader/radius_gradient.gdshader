shader_type canvas_item;
//render_mode blend_add;

uniform sampler2D gradient;
uniform float pixels : hint_range(1, 60) = 30.0;

void fragment() {
	vec2 pixel_uv = UV;
	pixel_uv -= mod(pixel_uv, vec2(1.0/pixels, 1.0/pixels));
	
	float d = length(2.0 * pixel_uv - 1.0);
	vec4 col = texture(gradient, vec2(1.0-d, 0));
	
	COLOR = col;
}
