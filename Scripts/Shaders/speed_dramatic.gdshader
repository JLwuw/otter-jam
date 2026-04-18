shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap, repeat_disable;
uniform float strength : hint_range(0.0, 1.0, 0.01) = 0.0;
uniform vec2 velocity_dir = vec2(1.0, 0.0);
uniform float blur_strength : hint_range(0.0, 4.0, 0.01) = 1.4;
uniform float vignette_strength : hint_range(0.0, 1.0, 0.01) = 0.28;

void fragment() {
	vec2 dir = velocity_dir;
	float dir_len = length(dir);
	if (dir_len < 0.0001) {
		dir = vec2(1.0, 0.0);
	} else {
		dir /= dir_len;
	}

	vec2 center_uv = SCREEN_UV - vec2(0.5);
	float edge = smoothstep(0.12, 0.9, length(center_uv));
	float fx = clamp(strength, 0.0, 1.0) * edge;

	vec2 blur_step = SCREEN_PIXEL_SIZE * dir * blur_strength * fx * 9.0;
	vec3 col = texture(screen_texture, SCREEN_UV).rgb;
	col += texture(screen_texture, SCREEN_UV - blur_step * 1.0).rgb;
	col += texture(screen_texture, SCREEN_UV - blur_step * 2.0).rgb;
	col += texture(screen_texture, SCREEN_UV - blur_step * 3.0).rgb;
	col *= 0.25;

	float vignette = 1.0 - vignette_strength * fx * edge;
	col *= vignette;

	COLOR = vec4(col, 1.0);
}
