shader_type canvas_item;

uniform float health : hint_range(0.0, 1.0); // 체력 (0 ~ 1 사이 값)
uniform bool fatal_flag = false;

void fragment() {
	// 픽셀 화면 설정
	vec2 uv = SCREEN_UV; // 현재 픽셀의 화면 좌표 (0 ~ 1)
	float border = 0.07;
	if (fatal_flag){
		float edge_dist = min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y));
		float wave = (sin(TIME * 2.0) + 1.0) * 0.5; // TIME * () 값을 조절하면 깜빡임 속도 조절 가능
		float flicker = smoothstep(0.0, 1.0, wave); // 부드러운 깜빡임 효과
		float intensity = smoothstep(border, 0.0, edge_dist) * (1.0 - health) * flicker;
		// 최종 색상 (빨간색)
		COLOR = vec4(1.0, 0.0, 0.0, intensity);
	}
}