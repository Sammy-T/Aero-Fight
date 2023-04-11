shader_type canvas_item;

uniform vec4 base_color: source_color = vec4(vec3(0.5), 1.0);

// https://godotshaders.com/snippet/circle/
float circle(vec2 position, float radius, float feather) {
	return smoothstep(radius, radius + feather, dot(position, position) * 4.0);
}

void fragment() {
	vec4 color = base_color;
	
	float circle_shape = 1.0 - circle(UV - 0.5, 0.9, 0.05);
	color.a = mix(0, base_color.a, circle_shape); // Mask out the circle shape
	
	COLOR = color;
}
