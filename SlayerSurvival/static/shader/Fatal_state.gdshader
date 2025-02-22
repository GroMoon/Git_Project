shader_type canvas_item;

uniform float health : hint_range(0.0, 1.0); // 체력 (0 ~ 1 사이 값)

void fragment() {
	vec2 uv = SCREEN_UV; // 현재 픽셀의 화면 좌표 (0 ~ 1)
	// 두께 설정 (0.1은 테두리 두께)
	float border = 0.1;
	// 화면 가장자리에서 가까운 거리 계산
	float edge_dist = min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y));
	// 체력이 낮을수록 테두리가 강하게 표시됨
	float intensity = smoothstep(border, 0.0, edge_dist) * (1.0 - health);
	// 최종 색상 (빨간색)
	COLOR = vec4(1.0, 0.0, 0.0, intensity);
}