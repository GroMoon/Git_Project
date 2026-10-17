shader_type canvas_item;

// 피격 시 스프라이트를 단색으로 번쩍이게 한다 (0 = 원본, 1 = flash_color)
uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	vec4 base = texture(TEXTURE, UV) * COLOR;
	COLOR = vec4(mix(base.rgb, flash_color.rgb, flash), base.a);
}
