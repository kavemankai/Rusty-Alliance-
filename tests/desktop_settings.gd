extends SceneTree
const D=preload("res://ui/desktop.gd")
var passed=0
var failures=[]
func _init() -> void: call_deferred("run")
func check(ok: bool,title: String) -> void:
 if ok: passed+=1
 else: failures.append(title);print("FAIL: "+title)
func run() -> void:
 var path="user://desktop-settings-unit.cfg"
 var prefs=D.new();prefs.path=path;prefs.fullscreen=true;prefs.ui_scale=1.15;prefs.render_scale=.75;prefs.frame_limit=120;prefs.vsync=false
 check(prefs.bind_key("guard",KEY_Y)=="","A free key can be assigned")
 check(prefs.save_settings()==OK,"Display and binding preferences save independently")
 var restored=D.new();restored.path=path;restored.load_settings()
 for field in ["fullscreen","ui_scale","render_scale","frame_limit","vsync","keys"]: check(restored.get(field)==prefs.get(field),"Preference survives reload: "+field)
 var before=restored.keys.duplicate()
 check(restored.bind_key("guard",KEY_ESCAPE)!="" and restored.keys==before,"Escape cannot be accidentally rebound")
 check(restored.bind_key("guard",KEY_W)!="" and restored.keys==before,"Camera keys are protected from conflicts")
 check(restored.bind_key("guard",KEY_R)!="" and restored.keys==before,"Duplicate action keys fail without changing bindings")
 var config=ConfigFile.new();config.set_value("keys","guard",KEY_R);config.set_value("display","ui_scale",100);config.set_value("display","render_scale",.01);config.set_value("display","frame_limit",-99);config.set_value("display","fullscreen","not a boolean");config.save(path)
 restored=D.new();restored.path=path;restored.load_settings()
 check(restored.keys==D.DEFAULT_KEYS,"Corrupt duplicate bindings fall back to coherent defaults")
 check(restored.ui_scale==1.3 and restored.render_scale==.5,"Out-of-range display values are bounded")
 check(restored.frame_limit==60 and not restored.fullscreen,"Invalid frame cap and fullscreen values keep safe defaults")
 config=ConfigFile.new();config.set_value("display","ui_scale",NAN);config.set_value("display","render_scale",INF);config.save(path)
 restored=D.new();restored.path=path;restored.load_settings()
 check(is_finite(restored.ui_scale) and is_finite(restored.render_scale),"Nonfinite display values cannot corrupt the UI")
 var event=InputEventKey.new();event.keycode=KEY_F5
 check(restored.matches("save",event),"Restored save binding matches real input events")
 event.ctrl_pressed=true
 check(not restored.matches("save",event),"Modifier differences are not silently ignored")
 DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
 var report={"passed":passed,"failed":failures.size(),"failures":failures}
 var file=FileAccess.open("res://desktop-settings-results.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close()
 print("DESKTOP_SETTINGS: "+JSON.stringify(report));quit(0 if failures.is_empty() else 1)
