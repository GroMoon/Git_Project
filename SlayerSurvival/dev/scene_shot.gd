extends Node

## 씬 하나를 띄워 스크린샷 저장 (UI 확인용, 창 모드 실행)
## Godot --path . res://dev/scene_shot.tscn -- --scene=res://dynamic/5_title_screen/menu.tscn --out=/tmp/menu.png
##   --call=메서드이름 (씬 루트에서 호출, 예: _on_cave_button_pressed)  --wait=초  --hover=버튼 경로(포커스)

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	var opts = {"scene": "", "out": "user://shot.png", "call": "", "wait": "0.8", "focus": ""}
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--") and arg.contains("="):
			var kv = arg.substr(2).split("=", true, 1)
			opts[kv[0]] = kv[1]
	var scene = load(opts["scene"]).instantiate()
	get_tree().root.add_child.call_deferred(scene)
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().current_scene = scene
	for m in String(opts["call"]).split(",", false):
		if scene.has_method(m):
			scene.call(m)
		await get_tree().process_frame
	if opts["focus"] != "":
		var n = scene.get_node_or_null(opts["focus"])
		if n is Control:
			n.grab_focus()
	await get_tree().create_timer(float(opts["wait"]), true).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(opts["out"])
	print("saved ", opts["out"])
	get_tree().quit()
