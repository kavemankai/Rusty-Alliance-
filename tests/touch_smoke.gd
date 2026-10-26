extends SceneTree
var passed=0
var failed=0
func _init() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
 if ok: passed+=1
 else: failed+=1;print("FAIL: "+label)
func run() -> void:
 preload("res://tests/touch_cases.gd").run(self)
 await process_frame
 await process_frame
 print("TOUCH: %d passed, %d failed" % [passed,failed]);quit(1 if failed else 0)
