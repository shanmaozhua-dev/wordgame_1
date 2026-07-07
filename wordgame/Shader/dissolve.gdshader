shader_type canvas_item;

//  noise texture (see Dissolve.material for GUI Generated one or Main.gd::_on_reseed_noise_pressed() for scripted one)
uniform sampler2D noise_tex : source_color;
// position (time) of burning
uniform float time : hint_range(0, 1);
uniform float stagger_amount: hint_range(0, 1) = 0.;
//uniform float speed: hint_range(0.01, 1) = .5;
//uniform vec2 size;
//uniform vec2 start_position = vec2(.5,.5);
uniform float direction : hint_range(0, 360);
uniform int pixels : hint_range(1, 60) = 30;
uniform bool reverse = false;

float map(float value, float min1, float max1, float min2, float max2) {
  return min2 + (value - min1) * (max2 - min2) / (max1 - min1);
}

void fragment()
{
	COLOR = texture(TEXTURE, UV);
	
//	float pixels = 30.0;

	vec2 size = 1./TEXTURE_PIXEL_SIZE;
	
	vec2 grid_size = size/60.0;

	vec2 gv = fract(UV*grid_size);
	vec2 id = floor(UV*grid_size)/grid_size;
	
	vec2 pixel_uv = gv;
	pixel_uv -= mod(pixel_uv, vec2(1.0/float(pixels), 1.0/float(pixels)));
	
	float rand = texture(noise_tex, id).r;
	
	pixel_uv += rand*123.321;
	
	// rotate
    float radian = 3.1415926 * 2. * rand;
    float s = sin(radian);
    float c = cos(radian);
    mat2 rotate = mat2(vec2(c, -s), vec2(s, c));
	pixel_uv *= rotate;
	
	float r = texture(noise_tex, pixel_uv).r;
	
//	r = 2. * ( r - .5) + .5; //加深對比
	r = clamp(r, 0.01, 1.);
	
	vec2 dir = vec2(cos(radians(direction)), sin(radians(direction)));
	dir.x /= size.y/size.x;
	dir = normalize(dir);
	vec2 start_position = dir * -1.;
	float start_time = dot(id-start_position, dir);
	
	float max_time =  
		max(max(dot(vec2(0,0)-start_position, dir),
		dot(vec2(1,0)-start_position, dir)),
		max(dot(vec2(0,1)-start_position, dir),
		dot(vec2(1,1)-start_position, dir)));
	float min_time =  
		min(min(dot(vec2(0,0)-start_position, dir),
		dot(vec2(1,0)-start_position, dir)),
		min(dot(vec2(0,1)-start_position, dir),
		dot(vec2(1,1)-start_position, dir)));
	min_time = max(min_time, 0.);
		
	start_time = map(start_time, min_time, max_time, 0., 1.); // 0 ~ 1
	
	// 動畫佔 0.2
	stagger_amount; //1-0 -> 0.01-1
	float ani_time = max(0.01, 1.-stagger_amount);
	start_time = start_time * (1.-ani_time); // 0.0 ~ 0.8
	float t = time - start_time; // -0.8 ~ 1.0
	float p = clamp(t*(1./ani_time), 0., 1);
	
	//COLOR.rgb = mix(COLOR.rgb, vec3(0), step(r,p));
	
	if(reverse) {
		COLOR.a = mix(0., COLOR.a, step(r,p));
	} else {
		COLOR.a = mix(COLOR.a, 0., step(r,p));
	}
	
	
	// 要有個值p ： t=0 時 p=0, t=0.2時 p=1
	// r 0~1 每個pixel不同
	// p>r
	
//	COLOR.rgb = vec3(step(0., start_time));
	
}
