shader_type canvas_item;

// 메뉴 뒤 배경: 게임 화면을 흐리게 + 어둡게
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float blur : hint_range(0.0, 5.0) = 2.5;
uniform vec4 tint : source_color = vec4(0.03, 0.02, 0.05, 0.62);

void fragment() {
	vec3 c = textureLod(screen_tex, SCREEN_UV, blur).rgb;
	// 가장자리를 조금 더 어둡게 (비네트)
	float v = smoothstep(0.85, 0.25, distance(SCREEN_UV, vec2(0.5)));
	c = mix(c, tint.rgb, tint.a) * mix(0.75, 1.0, v);
	COLOR = vec4(c, 1.0);
}
