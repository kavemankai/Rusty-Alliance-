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
 var state=JSON.stringify(app.game.s)
 for spec in [[1280,720,1.0],[1600,900,1.0],[1920,1080,1.0],[1280,720,1.3]]:
  root.size=Vector2i(spec[0],spec[1]);app.desktop.ui_scale=spec[2];app.apply_desktop_theme();app.rebuild();await frames()
  var view=app.opening_view
  check(root.size==Vector2i(spec[0],spec[1]),"Actual requested window dimensions")
  check(view.canvas.hotspots.size()==12,"All twelve people have scene hit regions")
  var picture=view.canvas.picture_rect()
  for row in app.game.s.recruitment.templates:
   check(view.candidate_controls[row.id].size()==2,"Image and name share one canonical ID: "+row.id)
   var image=view.canvas.hotspots[row.id]
   check(picture.encloses(image.get_rect()) and root.get_visible_rect().encloses(image.get_global_rect()),"Uncropped on-screen scene region: "+row.id)
   for other in view.canvas.hotspots:
    if other!=row.id: check(not image.get_rect().intersects(view.canvas.hotspots[other].get_rect()),"Independent non-overlapping people: "+row.id+"/"+other)
   for button in view.candidate_controls[row.id]:
    for pressed in [true,false]:
     var event=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed;event.position=button.get_global_rect().get_center();root.push_input(event)
    await frames()
    check(app.opening_view==view,"Selection keeps the same live screen")
    check(app.tavern_selected==row.id and view.profile_box.get_child(0).text==row.name,"Image/name opens matching profile: "+row.id)
    for id in view.candidate_controls:
     for control in view.candidate_controls[id]: check(control.button_pressed==(id==row.id),"Only matching image/name highlighted: "+id)
    var selected_style=button.get_theme_stylebox("normal")
    check(selected_style.shadow_size>0 and selected_style.shadow_color.a>0,"Persistent soft selection glow")
 check(JSON.stringify(app.game.s)==state,"Browsing profiles never mutates authoritative campaign state")
 var report={"passed":passed,"failed":failed.size(),"failures":failed}
 var output=FileAccess.open("res://tavern-selection-results.json",FileAccess.WRITE);output.store_string(JSON.stringify(report,"  "));output.close()
 print("TAVERN_SELECTION: "+JSON.stringify({"passed":passed,"failed":failed.size(),"failures":failed}));app.queue_free();await frames();quit(0 if failed.is_empty() else 1)
