extends SceneTree
var app
var passed=0
var failures=[]
func _init() -> void: call_deferred("run")
func check(ok: bool,title: String) -> void:
 if ok: passed+=1
 else: failures.append(title);print("FAIL: "+title)
func settle() -> void: await process_frame;await process_frame
func camera_mouse(view: Control,tactical: bool) -> void:
 var before=JSON.stringify(app.game.s);var position=view.get_global_rect().get_center()
 var original=view.camera.position if tactical else view.offset
 var zoom=view.camera.size if tactical else view.zoom
 var down=InputEventMouseButton.new();down.button_index=MOUSE_BUTTON_MIDDLE;down.pressed=true;down.position=position;root.push_input(down)
 var drag=InputEventMouseMotion.new();drag.button_mask=MOUSE_BUTTON_MASK_MIDDLE;drag.position=position+Vector2(50,25);drag.relative=Vector2(50,25);root.push_input(drag)
 var up=InputEventMouseButton.new();up.button_index=MOUSE_BUTTON_MIDDLE;up.position=drag.position;root.push_input(up);await settle()
 check((view.camera.position if tactical else view.offset)!=original and JSON.stringify(app.game.s)==before,"Middle mouse pans the actual "+("battle" if tactical else "island")+" without simulation changes")
 for pressed in [true,false]:
  var wheel=InputEventMouseButton.new();wheel.button_index=MOUSE_BUTTON_WHEEL_UP;wheel.pressed=pressed;wheel.position=position;root.push_input(wheel)
 await settle()
 check((view.camera.size if tactical else view.zoom)!=zoom and JSON.stringify(app.game.s)==before,"Mouse wheel zooms the actual "+("battle" if tactical else "island")+" without simulation changes")
 view.reset_camera();await settle()
func run() -> void:
 app=load("res://main.tscn").instantiate();app.desktop.path="user://pc-camera-test.cfg";root.add_child(app);await settle();root.size=Vector2i(1600,900)
 app.start_greywake();app.game.autosave_path="user://pc-camera-test-auto.json";app.game.command("opening_skip")
 for repeat in range(2): app.game.command("recruit_template",{"template":"militia_spearman"})
 for action in ["opening_confirm","opening_depart","opening_skip","opening_next","opening_next","dockside_start","confirm_deployment"]: check(app.game.command(action),"Paid fixture "+action)
 app.rebuild();await settle();await camera_mouse(app.battle_view,true)
 check(app.game.command("retreat"),"Legitimate withdrawal")
 app.rebuild();await settle();await camera_mouse(app.map_view,false)
 app.auto_minutes=60;app._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
 var time=app.game.s.time;await create_timer(.4).timeout
 check(app.auto_minutes==0 and app.game.s.time==time,"Focus loss stops the active campaign clock")
 app._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN);await create_timer(.4).timeout
 check(app.auto_minutes==0 and app.game.s.time==time,"Focus return never resumes the campaign clock")
 var report={"passed":passed,"failed":failures.size(),"failures":failures,"scope":"Headless native Control GUI mouse events and focus-clock behaviour; display/fullscreen/performance use the separate graphical runs."}
 var out=FileAccess.open("res://pc-camera-results.json",FileAccess.WRITE);out.store_string(JSON.stringify(report,"  "));out.close();print("PC_CAMERA: "+JSON.stringify(report));app.queue_free();await settle();quit(0 if failures.is_empty() else 1)
