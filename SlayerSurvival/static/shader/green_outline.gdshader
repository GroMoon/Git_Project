shader_type canvas_item;

// 아웃라인 색상 (연두색)
// Godot 4에서는 hint를 사용하지 않아도 되므로 hint 제거
uniform vec4 color = vec4(0.5, 1.0, 0.5, 1.0); 
// 아웃라인 두께 (픽셀 단위)
// 0부터 10까지 범위 내에서 조정 가능
uniform float width : hint_range(0, 10) = 1.0;
// 아웃라인 패턴: 0 = 다이아몬드, 1 = 원, 2 = 사각형
uniform int pattern : hint_range(0, 2) = 0; 
// 아웃라인을 내부에 적용할지 여부
uniform bool inside = false;
// inside가 false일 때만 유효한 옵션, 여백을 추가할지 여부
uniform bool add_margins = true; 

// 정점 쉐이더: 여백이 활성화된 경우, 각 정점의 위치를 아웃라인 두께만큼 이동
void vertex() {
	if (add_margins) {
		// UV 좌표는 [0,1] 범위이므로, 2배한 후 -1을 해서 [-1,1] 범위로 만든 후 width 만큼 오프셋을 적용
		VERTEX += (UV * 2.0 - 1.0) * width;
	}
}

// 주어진 UV 좌표에서, 주변에 대비되는(다른) 이웃이 있는지 확인하는 함수
bool hasContraryNeighbour(vec2 uv, vec2 texture_pixel_size, sampler2D texture) {
	for (float i = -ceil(width); i <= ceil(width); i++) {
		// x 좌표를 width 범위 내로 제한
		float x = abs(i) > width ? width * sign(i) : i;
		float offset;
		
		// 패턴에 따라 y 방향 오프셋 계산
		if (pattern == 0) { // 다이아몬드 모양
			offset = width - abs(x);
		} else if (pattern == 1) { // 원 모양
			offset = floor(sqrt(pow(width + 0.5, 2) - x * x));
		} else if (pattern == 2) { // 사각형 모양
			offset = width;
		}
		
		for (float j = -ceil(offset); j <= ceil(offset); j++) {
			// y 좌표를 offset 범위 내로 제한
			float y = abs(j) > offset ? offset * sign(j) : j;
			// 현재 UV에서 오프셋만큼 이동한 좌표
			vec2 xy = uv + texture_pixel_size * vec2(x, y);
			
			// xy가 0~1 범위를 벗어나거나, 해당 픽셀의 알파값이 0 이하이면(투명) 조건을 만족
			// 이 조건이 inside와 일치하면 true 반환
			if ((xy != clamp(xy, vec2(0.0), vec2(1.0)) || texture(texture, xy).a <= 0.0) == inside) {
				return true;
			}
		}
	}
	
	return false;
}

void fragment() {
	vec2 uv = UV;
	
	if (add_margins) {
		// 텍스처 픽셀 크기를 고려하여, 여백 추가 시 효과를 보정
		vec2 texture_pixel_size = vec2(1.0) / (vec2(1.0) / TEXTURE_PIXEL_SIZE + vec2(width * 2.0));
		
		// UV 좌표를 재계산: 여백만큼 이동한 후 원래 텍스처 좌표로 변환
		uv = (uv - texture_pixel_size * width) * TEXTURE_PIXEL_SIZE / texture_pixel_size;
		
		// UV 좌표가 0~1 범위를 벗어나면, 투명 처리
		if (uv != clamp(uv, vec2(0.0), vec2(1.0))) {
			COLOR.a = 0.0;
		} else {
			COLOR = texture(TEXTURE, uv);
		}
	} else {
		COLOR = texture(TEXTURE, uv);
	}
	
	// 현재 픽셀의 알파값이 존재하는지(> 0)와 inside 여부 및 주변 이웃 확인
	if ((COLOR.a > 0.0) == inside && hasContraryNeighbour(uv, TEXTURE_PIXEL_SIZE, TEXTURE)) {
		// inside가 true이면 원본 색상과 outline 색상을 혼합, false이면 outline 색상 적용
		COLOR.rgb = inside ? mix(COLOR.rgb, color.rgb, color.a) : color.rgb;
		// 알파값 조정: outline 색상의 알파값에 따라 최종 투명도 결정
		COLOR.a += (1.0 - COLOR.a) * color.a;
	}
}
