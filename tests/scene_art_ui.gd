extends SceneTree
var app
var passed=0
var failures=[]
func _init() -> void: call_deferred("run")
func check(ok: bool,title: String) -> void:
 if ok: passed+=1
 else: failures.append(title);print("FAIL: "+title)
func find(node: Node,title: String):
 if node is Button and node.text==title: return node
 for child in node.get_children():
  var found=find(child,title)
  if found!=null: return found
 return null
func settle() -> void: await process_frame;await process_frame;await create_timer(.35).timeout
func click(title: String) -> void:
 var button=find(app,title)
 if button==null: check(false,"Missing "+title);return
 for pressed in [true,false]:
  var event=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed;event.position=button.get_global_rect().get_center();root.push_input(event)
 await settle()
func capture(name: String) -> void: root.get_texture().get_image().save_png("res://scene-art-"+name+"-preview.png")
func run() -> void:
 app=load("res://main.tscn").instantiate();root.add_child(app);await settle();capture("title")
 await click("New Game");app.game.autosave_path="user://scene-art-ui-auto.json";app.save_slot="user://scene-art-ui.json";capture("employer")
 await click("Enter tavern")
 # A normal six-person paid fixture exercises the maximum layout, not free units.
 for index in range(6): check(app.game.command("recruit_template",{"template":"militia_spearman"}),"Paid fixture hire "+str(index))
 app.rebuild();await settle()
 var viewport=root.get_visible_rect()
 for row in app.game.s.recruitment.templates:
  check(viewport.encloses(find(app,row.name).get_global_rect()),"Six-person roster choice is on screen: "+row.id)
 for index in range(6):
  var remove=find(app,"Remove #"+str(index+1).pad_zeros(8))
  check(remove!=null and viewport.encloses(remove.get_global_rect()),"Each full-company removal identifies an on-screen individual: "+str(index+1))
 check(viewport.encloses(find(app,"Set Sail").get_global_rect()),"Full company departure remains on screen")
 check(app.game.s.funds==1680 and app.game.s.squads.first.members.size()==6,"Maximum layout retains exact real fees and six individuals")
 capture("tavern")
 await click("Set Sail");await click("Confirm departure");capture("crossing")
 await click("Skip crossing");capture("arrival")
 await click("Step ashore");await click("Open island map");await click("Harbour");capture("harbour")
 check(app.game.s.squads.first.sector==17 and app.game.s.time==480,"Scenic flow retains actual landing sector and campaign clock")
 var before=JSON.stringify(app.game.s)
 app.rebuild();await settle()
 check(JSON.stringify(app.game.s)==before,"Harbour illustration refresh does not mutate simulation or RNG")
 var report={"passed":passed,"failed":failures.size(),"failures":failures}
 var file=FileAccess.open("res://scene-art-ui-results.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close()
 print("SCENE_ART_UI: "+JSON.stringify(report));app.queue_free();await settle();quit(0 if failures.is_empty() else 1)
