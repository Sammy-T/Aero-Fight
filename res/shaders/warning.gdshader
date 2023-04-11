shader_type canvas_item;

uniform vec4 base_color: source_color = vec4(vec3(0.5), 1.0);

// https://godotshaders.com/snippet/squares/
vec4 square_rounded(vec2 uv, float width, float radius) {
	uv = uv * 2.0 - 1.0;
	
	radius *= width; // make radius go from 0-1 instead of 0-width
	vec2 abs_uv = abs(uv.xy) - radius;
	vec2 dist = vec2(max(abs_uv.xy, 0.0));
	float square = step(width - radius, length(dist));
	
	return vec4(vec3(square), 1.0);
}

void fragment() {
	vec4 color = base_color;
	
	vec4 square = 1.0 - square_rounded(UV, 0.9, 0.6);
	color.a = mix(0, base_color.a, square.r); // Mask out the square shape
	
	COLOR = color;
}
