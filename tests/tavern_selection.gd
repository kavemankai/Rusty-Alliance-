extends SceneTree
var app
var failed=[]
var passed=0
func _init() -> void: call_deferred("run")
func check(ok: bool,what: String) -> void:
 if ok: passed+=1
 else: failed.append(what)
func frames() -> void: await process_frame;await process_frame;await process_frame
func run() -> void:
 app=load("res://main.tscn").instantiate();app.desktop.path="user://tavern-selection-probe.cfg";root.add_child(app);await frames()
 app.start_greywake();app.game.autosave_path="user://tavern-selection-probe-auto.json";app.game.command("opening_skip");app.rebuild();await frames()
 var state=JSON.stringify(app.game.s);var view=app.opening_view
 for row in app.game.s.recruitment.templates:
  var button=view.candidate_controls[row.id][0]
  for pressed in [true,false]:
   var event=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed;event.position=button.get_global_rect().get_center();root.push_input(event)
  await frames()
  check(app.opening_view==view,"Selection keeps the same live screen")
  check(app.tavern_selected==row.id and view.profile_box.get_child(0).text==row.name,"Selected profile matches "+row.id)
  for id in view.candidate_controls:
   for control in view.candidate_controls[id]: check(control.button_pressed==(id==row.id),"Only selected candidate highlighted: "+id)
  var selected_style=button.get_theme_stylebox("normal")
  check(selected_style.shadow_size>0 and selected_style.shadow_color.a>0,"Soft persistent selection glow")
 check(JSON.stringify(app.game.s)==state,"Browsing profiles never mutates authoritative campaign state")
 print("TAVERN_SELECTION: "+JSON.stringify({"passed":passed,"failed":failed.size(),"failures":failed}));app.queue_free();await frames();quit(0 if failed.is_empty() else 1)
