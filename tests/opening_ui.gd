extends SceneTree
var app
var passed=0
var failures=[]
func _init() -> void: call_deferred("run")
func check(ok: bool,title: String) -> void:
 if ok: passed+=1
 else: failures.append(title);print("FAIL: "+title)
func find(node: Node,text: String):
 if node is Button and node.text==text: return node
 for child in node.get_children():
  var result=find(child,text)
  if result!=null: return result
 return null
func has_label(node: Node,text: String) -> bool:
 if node is Label and node.text==text: return true
 for child in node.get_children():
  if has_label(child,text): return true
 return false
func settle() -> void: await process_frame;await process_frame;await create_timer(.27).timeout
func click(text: String) -> void:
 var b=find(app,text)
 if b==null: check(false,"Missing button "+text);return
 if is_instance_valid(app.battle_hud) and is_instance_valid(app.side) and app.side.get_parent().is_ancestor_of(b) and not app.side.get_parent().visible:
  await click("Details")
  b=find(app,text)
 var parent=b.get_parent()
 while parent!=null:
  if parent is ScrollContainer: parent.ensure_control_visible(b)
  parent=parent.get_parent()
 await settle()
 for pressed in [true,false]:
  var e=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_LEFT;e.pressed=pressed;e.position=b.get_global_rect().get_center();root.push_input(e)
 await settle()
func run() -> void:
 app=load("res://main.tscn").instantiate();root.add_child(app);await settle()
 check(find(app,"New Game")!=null and find(app,"New campaign")!=null,"Title preserves separate original and Greywake access")
 check(app.opening_view.get_child(0).texture.resource_path.ends_with("01_title_atmosphere_1920x1080.png"),"Supplied title scene is displayed")
 await click("New Game")
 check(app.opening_view.get_child(0).texture.resource_path.ends_with("02_hooded_employer_1920x1080.png"),"Supplied anonymous employer scene is displayed")
 app.save_slot="user://opening-ui-save.json";app.game.autosave_path="user://opening-ui-auto.json"
 check(app.Campaign.Opening.stage(app.game.s)=="EMPLOYER_BRIEFING","New Game enters employer briefing")
 await click("Continue briefing")
 check(app.game.s.opening_flow.dialogue_index==1,"Briefing advances actual saved dialogue index")
 await click("Enter tavern")
 check(app.Campaign.Opening.stage(app.game.s)=="TAVERN_RECRUITMENT","Skip briefing still enters recruitment")
 check(app.opening_view.canvas.texture.resource_path.ends_with("03_tavern_recruitment_interactive_v2.png"),"Supplied tavern atmosphere accompanies the real roster controls")
 for row in app.game.s.recruitment.templates: check(find(app,row.name)!=null,"Actual tavern choice "+row.id)
 for row in app.game.s.recruitment.templates:
  await click(row.name)
  for key in app.Data.Skills.ATTRIBUTES+app.Data.Skills.ALL:
   check(has_label(app,key.capitalize()+"  "+str(row.attributes.get(key,row.skills.get(key,0)))),"Native profile value "+row.id+"/"+key)
  check(has_label(app,"Hiring fee %d crowns · Daily wage %d" % [row.fee,row.wage]),"Native fee and wage "+row.id)
 check((app.Desktop.enabled() and find(app,"Set Sail").get_theme_stylebox("normal") is StyleBoxFlat) or (not app.Desktop.enabled() and find(app,"Set Sail").get_theme_stylebox("normal") is StyleBoxTexture),"Platform control skin is bound to real hiring/departure controls")
 check(find(app,"Set Sail").disabled,"Empty tableau company cannot depart")
 await click("Roderic")
 check(find(app,"Recruit Roderic").disabled,"Elite profile visible but unaffordable")
 await click("Militia Spearman");await click("Recruit Militia Spearman");await click("Recruit Militia Spearman")
 check(app.game.s.funds==2160 and not find(app,"Set Sail").disabled,"Illustrated recruiting pays canonical fees")
 await click("Save selection");await click("Mara");await click("Recruit Mara");await click("Load selection")
 check(app.game.s.funds==2160 and app.game.s.squads.first.members.size()==2,"Tavern load restores selected real company")
 await process_frame
 if DisplayServer.get_name()!="headless": root.get_texture().get_image().save_png("res://opening-tavern-preview.png")
 await click("Set Sail")
 check(app.Campaign.Opening.stage(app.game.s)=="COMPANY_CONFIRMATION","Set Sail opens real company confirmation")
 await click("Save");await click("Load")
 check(app.Campaign.Opening.stage(app.game.s)=="COMPANY_CONFIRMATION","Company confirmation survives UI save/load")
 await click("Confirm departure")
 check(app.Campaign.Opening.stage(app.game.s)=="BOAT_CROSSING" and app.game.s.funds==2160,"Boat uses existing embarkation without charging again")
 await click("Skip crossing");await click("Step ashore");await click("Open island map")
 check(app.Campaign.Opening.stage(app.game.s)=="GREYWAKE_CAMPAIGN" and app.game.s.time==480,"Presentation leads to persistent arrival without spending campaign time")
 await create_timer(.25).timeout
 check(app.map_view!=null and app.Campaign.World.applies(app.game.s),"Actual gridless island replaces staging view")
 if DisplayServer.get_name()!="headless": root.get_texture().get_image().save_png("res://opening-island-preview.png")
 await click("Deal with Dockside Trouble")
 check(app.game.battle!=null and app.game.battle.t.phase=="deployment","Opening reaches actual dockside tactical deployment")
 check(find(app,"Begin combat")!=null,"Normal deployment controls remain available")
 await click("Begin combat")
 check(find(app,"Next tip")!=null and find(app,"Hide tutorial")!=null,"Dismissible contextual tutorial is visible")
 var points=app.game.battle.t.units.filter(func(u):return u.team=="company")
 var actor=points[0]
 var t=app.game.battle.t
 var chosen=Vector2(actor.x,actor.y)
 var screen=app.battle_view.camera.unproject_position(Vector3(actor.x,.06,actor.y))
 var pos=app.battle_view.get_global_transform()*screen*app.battle_view.size/Vector2(app.battle_view.viewport.size)
 # Board selection is routed through the ordinary tactical callback.
 app.tactical_cell(actor.x,actor.y);await settle()
 check(app.game.s.opening_flow.tutorial_flags.get("select",false),"Real tactical selection advances saved tutorial guidance")
 await click("Next tip");await click("Hide tutorial")
 check(app.game.s.opening_flow.tutorial_dismissed and find(app,"Next tip")==null,"Guidance can be dismissed without blocking legal combat")
 await click("Save");await click("Load")
 check(app.game.s.opening_flow.tutorial_dismissed and app.game.battle!=null,"Tactical tutorial dismissal and encounter survive UI save/load")
 if DisplayServer.get_name()!="headless": root.get_texture().get_image().save_png("res://opening-dockside-preview.png")
 app.game.command("retreat");app.rebuild();await settle()
 check(app.game.battle==null and app.map_view!=null and app.game.s.opening_flow.outcome=="retreat","Withdrawal returns actual survivors to island")
 # Desktop middle-drag, wheel and cancellation remain native UI actions.
 var view=app.map_view;var prior_offset=view.offset;var centre=view.get_global_rect().get_center()
 var middle=InputEventMouseButton.new();middle.button_index=MOUSE_BUTTON_MIDDLE;middle.pressed=true;middle.position=centre;root.push_input(middle)
 var motion=InputEventMouseMotion.new();motion.position=centre+Vector2(30,15);motion.relative=Vector2(30,15);motion.button_mask=MOUSE_BUTTON_MASK_MIDDLE;root.push_input(motion)
 middle=InputEventMouseButton.new();middle.button_index=MOUSE_BUTTON_MIDDLE;middle.pressed=false;middle.position=centre+Vector2(30,15);root.push_input(middle);await settle()
 check(view.offset!=prior_offset,"Middle mouse drag pans gridless island")
 var old_zoom=view.zoom;var wheel=InputEventMouseButton.new();wheel.button_index=MOUSE_BUTTON_WHEEL_UP;wheel.pressed=true;wheel.position=centre;root.push_input(wheel);await settle()
 check(view.zoom>old_zoom,"Mouse wheel zooms gridless island")
 # Keyboard and right-click controls exercise the real opening and battle UI.
 app.menu();await settle();await click("New Game")
 app.save_slot="user://opening-ui-keyboard.json";app.game.autosave_path="user://opening-ui-keyboard-auto.json"
 var key=InputEventKey.new();key.pressed=true;key.keycode=KEY_ENTER;root.push_input(key);await settle()
 check(app.game.s.opening_flow.dialogue_index==1,"Enter advances briefing even with native UI focus")
 key=InputEventKey.new();key.pressed=true;key.keycode=KEY_ESCAPE;root.push_input(key);await settle()
 check(app.Campaign.Opening.stage(app.game.s)=="TAVERN_RECRUITMENT","Esc skips dialogue into required recruitment")
 var right=InputEventMouseButton.new();right.button_index=MOUSE_BUTTON_RIGHT;right.pressed=true;right.position=Vector2(300,300);root.push_input(right);await settle()
 check(app.tavern_selected=="" and find(app,"Recruit Militia Spearman")==null,"Right-click closes recruitment profile without altering company")
 await click("Militia Spearman");await click("Recruit Militia Spearman");await click("Recruit Militia Spearman");await click("Set Sail")
 key=InputEventKey.new();key.pressed=true;key.keycode=KEY_ESCAPE;root.push_input(key);await settle()
 check(app.Campaign.Opening.stage(app.game.s)=="TAVERN_RECRUITMENT" and app.game.s.funds==2160,"Esc cancels confirmation without losing fees or recruits")
 await click("Set Sail");await click("Confirm departure")
 key=InputEventKey.new();key.pressed=true;key.keycode=KEY_SPACE;root.push_input(key);await settle()
 check(app.Campaign.Opening.stage(app.game.s)=="GREYWAKE_ARRIVAL" and app.game.s.funds==2160,"Space skips crossing while preserving authoritative landing")
 await click("Step ashore");await click("Open island map");await click("Deal with Dockside Trouble");await click("Begin combat")
 var board=app.battle_view;var fighter=app.game.battle.t.units.filter(func(unit):return unit.team=="company")[0]
 var screen_point=board.get_global_transform()*(board.camera.unproject_position(Vector3(fighter.x,.06,fighter.y))*board.size/Vector2(board.viewport.size))
 for pressed in [true,false]:
  var tap=InputEventMouseButton.new();tap.button_index=MOUSE_BUTTON_LEFT;tap.pressed=pressed;tap.position=screen_point;root.push_input(tap)
 await settle()
 var round_before=app.game.battle.t.round
 if app.Desktop.enabled():
  check(app.battle_radial.visible,"Clicking a fighter opens the contextual radial")
  key=InputEventKey.new();key.pressed=true;key.keycode=KEY_SPACE;root.push_input(key);await settle()
  check(app.game.battle.t.round==round_before,"Space cannot end a turn through an open radial")
  key=InputEventKey.new();key.pressed=true;key.keycode=KEY_ESCAPE;root.push_input(key);await settle()
 key=InputEventKey.new();key.pressed=true;key.keycode=KEY_SPACE;root.push_input(key);await settle()
 check(app.game.battle.t.round==round_before+1 and app.game.s.opening_flow.tutorial_flags.get("turn",false),"Unfocused Space ends a real tactical turn and advances guidance")
 var camera_before=board.camera.position;var state_before=JSON.stringify(app.game.s);centre=board.get_global_rect().get_center()
 middle=InputEventMouseButton.new();middle.button_index=MOUSE_BUTTON_MIDDLE;middle.pressed=true;middle.position=centre;root.push_input(middle)
 motion=InputEventMouseMotion.new();motion.position=centre+Vector2(30,15);motion.relative=Vector2(30,15);motion.button_mask=MOUSE_BUTTON_MASK_MIDDLE;root.push_input(motion)
 middle=InputEventMouseButton.new();middle.button_index=MOUSE_BUTTON_MIDDLE;middle.pressed=false;middle.position=centre+Vector2(30,15);root.push_input(middle);await settle()
 check(board.camera.position!=camera_before and JSON.stringify(app.game.s)==state_before,"Middle-drag tactical camera does not mutate AP clock or combat state")
 var report={"passed":passed,"failed":failures.size(),"failures":failures}
 var f=FileAccess.open("res://opening-ui-results.json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"  "));f.close()
 print("OPENING_UI: "+JSON.stringify(report));app.queue_free();await settle();quit(0 if failures.is_empty() else 1)
