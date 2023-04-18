shader_type canvas_item;

uniform sampler2D noise: repeat_enable;
uniform vec4 wave_color: source_color = vec4(1.0);
uniform vec2 scroll = vec2(0.01);
uniform vec2 scroll_2 = vec2(0.01);

varying vec2 world_pos;
varying vec2 world_offset;

void vertex() {
	// Calculate the world offset scaled according to the size of the noise texture
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
	world_offset = world_pos / vec2(textureSize(noise, 0));
}

void fragment() {
	vec4 pixel_color = texture(TEXTURE, UV);
	
	vec2 motion = vec2(sin(TIME), cos(TIME));
	vec2 noise_uv = SCREEN_UV + world_offset;
	vec2 noise_2_offset = vec2(0.25, 0.5);
	
	// Sample and combine the noise textures
	// (Use an offset so we can re-use the noise texture without using a second texture)
	vec4 noise_color = texture(noise, noise_uv + scroll * motion);
	vec4 noise_color_2 = texture(noise, noise_uv + noise_2_offset + scroll_2 * motion.yx);
	
	vec4 noise_combined = noise_color * noise_color_2;
	
	// Use the combined noise value to interpolate between
	// the base texture's color and the wave color
	pixel_color = mix(pixel_color, wave_color, noise_combined.r);
	
	COLOR = pixel_color;
}
