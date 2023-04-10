shader_type canvas_item;

uniform vec4 base_color: source_color = vec4(vec3(0), 1.0);
uniform vec3 line_color: source_color = vec3(1.0);

// https://godotshaders.com/snippet/circle/
float circle(vec2 position, float radius, float feather) {
	return smoothstep(radius, radius + feather, dot(position, position) * 4.0);
}

float circle_outline(vec2 position, float radius, float feather, float width) {
	float outer = circle(position, radius, feather);
	float inner = circle(position, radius - width, feather);
	return inner - outer;
}

// This works but I should've just made an image. I do NOT understand shaders.
void fragment() {
	vec4 color = vec4(vec3(0), 1.0);
	
	vec2 center = UV - 0.5;
	float circle_1 = circle_outline(center, 0.9, 0.05, 0.05);
	float circle_2 = circle_outline(center, 0.45, 0.04, 0.04);
	float circle_3 = circle_outline(center, 0.15, 0.02, 0.03);
	
	// Add the circles together
	color.rgb += circle_1 + circle_2 + circle_3;
	
	float line_width = 0.0035;
	float line_v = 1.0 - step(line_width, abs(UV.x - 0.5));
	float line_h = 1.0 - step(line_width, abs(UV.y - 0.5));
	
	// Add the lines
	color.rgb += line_v + line_h;
	
	// Mix the base and line colors together based on the combined shape values
	color.rgb = mix(base_color.rgb, line_color, color.r);
	
	// Mix the color's alpha to mask out the circle shape
	float circle_shape = circle(UV - 0.5, 1.0, 0.05);
	color.a = mix(0, base_color.a, 1.0 - circle_shape);
	
	COLOR = color;
}
