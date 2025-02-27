shader_type canvas_item;

uniform vec4 hit_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
// blink_time 을 설정할 변수
uniform float blink_time : hint_range(0.0, 1.0) = 0.2;
uniform bool hit_flag = false;

void fragment() {
	// 텍스쳐 샘플링 (전체(사각형))
	vec4 default_color = texture(TEXTURE, UV);
	// TIME은 시간 (초단위로 증가, float), mod는 나눈 후 나머지 연산
	float time = mod(TIME, blink_time * 2.0);
	// default_color.a 는 색상의 알파값을 의미(색이 있는 텍스쳐만 변화시키기 위해)
	if (default_color.a > 0.0 && hit_flag) {
		if (time < blink_time) {
			COLOR = hit_color;
		}
		else {
			COLOR = vec4(0.5, 0.5, 0.5, 0.5);
		}
	} 
	else {
		COLOR = default_color;
	}
}