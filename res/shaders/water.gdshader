shader_type canvas_item;

uniform sampler2D noise: repeat_enable;
uniform vec4 wave_color: source_color = vec4(1.0);
uniform vec2 scroll = vec2(0.01);
uniform vec2 scroll_2 = vec2(0.01);

void fragment() {
	vec2 motion = vec2(sin(TIME), cos(TIME));
	vec2 noise_offset = vec2(0.25, 0.5);
	
	vec4 pixel_color = texture(TEXTURE, UV);
	vec4 noise_color = texture(noise, SCREEN_UV + scroll * motion);
	vec4 noise_color_2 = texture(noise, SCREEN_UV + noise_offset + scroll_2 * motion.yx);
	
	vec4 noise_combined = noise_color * noise_color_2;
	
	pixel_color = mix(pixel_color, wave_color, noise_combined.r);
	
	COLOR = noise_combined;
}
