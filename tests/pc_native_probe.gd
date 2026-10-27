extends Node
var app
var samples=[]
var warmup=60
func _ready() -> void:
 app=load("res://main.tscn").instantiate();app.desktop.path="user://pc-native-probe.cfg";add_child(app)
 app.start_greywake();app.game.autosave_path="user://pc-native-probe-auto.json";app.game.command("opening_skip")
 for repeat in range(6): app.game.command("recruit_template",{"template":"militia_spearman"})
 for action in ["opening_confirm","opening_depart","opening_skip","opening_next","opening_next","dockside_start","confirm_deployment"]: app.game.command(action)
 app.rebuild();get_window().size=Vector2i(1920,1080);get_window().grab_focus();app._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
func _process(delta: float) -> void:
 if warmup>0: warmup-=1;return
 samples.append(delta*1000)
 if samples.size()<120: return
 samples.sort()
 var report={"normal_scene_mainloop":true,"frames":samples.size(),"median_ms":samples[samples.size()/2],"p95_ms":samples[int(samples.size()*.95)],"engine_fps":Engine.get_frames_per_second(),"cap":Engine.max_fps,"focused":get_window().has_focus(),"render_pixels":[app.battle_view.viewport.size.x,app.battle_view.viewport.size.y]}
 var output=FileAccess.open("res://pc-native-probe-results.json",FileAccess.WRITE);output.store_string(JSON.stringify(report,"  "));output.close();print("PC_NATIVE_PROBE: "+JSON.stringify(report));get_tree().quit()
