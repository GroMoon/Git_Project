extends PanelContainer

class_name InfoSlot

## 무기/패시브 아이콘 슬롯. 마우스를 올리면 정보 창(이름·레벨·설명·다음 레벨·스탯·진화 조건)을 띄움
## Godot 툴팁을 사용하므로 게임이 멈춰 있는 일시정지 메뉴에서도 동작 (창 모양은 테마의 TooltipPanel)

var player
var upgrade_id := ""

func _make_custom_tooltip(_for_text: String) -> Object:
	if player == null or upgrade_id == "" or not is_instance_valid(player):
		return null
	return GameUI.upgrade_info(player, upgrade_id)
