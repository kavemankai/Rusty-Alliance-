extends SceneTree
var app
var failures=[]
func _init() -> void: call_deferred("run")
func check(ok: bool,text: String) -> void:
 if not ok: failures.append(text)
func button(node: Node,text: String):
 if node is Button and node.text==text: return node
 for child in node.get_children():
  var found=button(child,text)
  if found!=null: return found
 return null
func settle() -> void: await process_frame;await process_frame
func click(text: String) -> void:
 var target=button(app,text)
 if target==null: failures.append("Missing button: "+text);return
 if is_instance_valid(app.battle_hud) and is_instance_valid(app.side) and app.side.get_parent().is_ancestor_of(target) and not app.side.get_parent().visible:
  await click("Details")
  target=button(app,text)
 var parent=target.get_parent()
 while parent!=null:
  if parent is ScrollContainer: parent.ensure_control_visible(target)
  parent=parent.get_parent()
 await settle()
 for pressed in [true,false]:
  var event=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed
  event.position=target.get_global_rect().get_center();root.push_input(event)
 await settle()
func run() -> void:
 app=load("res://main.tscn").instantiate();root.add_child(app);await settle()
 check(not ResourceLoader.has_cached("res://assets/quaternius/characters/glTF/Warrior.gltf"),"Main menu does not eagerly load tactical 3D characters")
 if app.Campaign.Recruitment.workshop_templates().is_empty(): check(button(app,"New Greywake campaign").disabled,"Missing workshop roster never launches a fabricated Greywake campaign")
 await click("New campaign")
 app.save_slot="user://skills-ui-original.json";app.game.autosave_path="user://skills-ui-original-auto.json"
 await click("Company");await click("● Mara · soldier");await click("Train Stealth")
 check(app.game.s.mercs.mara.training_skill=="stealth" and app.game.s.mercs.mara.assignment=="training","Actual controls select Stealth training")
 await click("+1 hour")
 var progress=app.game.s.mercs.mara.training
 await click("Train Fieldcraft");check(app.game.s.mercs.mara.training==0,"Changing skills does not transfer partial training credit")
 await click("Train Stealth");check(app.game.s.mercs.mara.training==progress,"Switching back retains individual skill progress")
 await click("Save");await click("Load")
 check(app.game.s.mercs.mara.training_skill=="stealth" and app.game.s.mercs.mara.training==progress,"Training selection/progress survives normal save/load controls")
 var candidate=app.Campaign.new()
 candidate.configure_new_greywake(preload("res://tests/skills.gd").synthetic_roster())
 app.game=candidate;app.selected="";app.tab="company";app.squad="first"
 app.save_slot="user://skills-ui-greywake.json";app.game.autosave_path="user://skills-ui-greywake-auto.json";app.rebuild();await settle()
 await click("Recruit Test cheap0 · 50 crowns");await click("Recruit Test cheap0 · 50 crowns")
 check(app.game.s.squads.first.members.size()==2 and app.game.s.funds==2300,"Repeatable UI hires create and pay for two individuals")
 var first=app.game.s.squads.first.members[0]
 var recruit=app.game.s.mercs[first]
 await click(recruit.name+" · soldier");await click("Train Athletics")
 check(recruit.training_skill=="athletics","Generated fighter can choose an individual training skill")
 await click("Save");await click("Load")
 check(app.game.s.mercs[first].training_skill=="athletics" and app.game.s.squads.first.members.size()==2,"Greywake UI reload preserves individual IDs, company and training")
 app.open_greywake("user://skills-ui-greywake.json");await settle()
 check(app.game.s.get("scenario")=="greywake" and app.save_slot=="user://greywake.json" and app.game.autosave_path=="user://greywake-autosave.json","Scenario loader restores Greywake with separate save/autosave defaults")
 app.save_slot="user://skills-ui-greywake.json";app.game.autosave_path="user://skills-ui-greywake-auto.json"
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://skills-ui-preview.png")
 var result={"failed":failures.size(),"failures":failures,"roster_source":"synthetic test fixture only"}
 var f=FileAccess.open("res://skills-ui-results.json",FileAccess.WRITE);f.store_string(JSON.stringify(result,"  "));f.close()
 print("SKILLS_UI: "+JSON.stringify(result));app.queue_free();await settle();quit(0 if failures.is_empty() else 1)
