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
func settle() -> void: await process_frame;await process_frame
func click(text: String) -> void:
 var b=find(app,text)
 if b==null: check(false,"Missing button "+text);return
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
 check(not find(app,"New Greywake campaign").disabled,"Production Greywake enabled")
 await click("New Greywake campaign")
 app.save_slot="user://greywake-ui-selection.json";app.game.autosave_path="user://greywake-ui-auto.json"
 check(app.game.s.scenario=="fall_of_greywake" and app.game.s.funds==2400,"New screen enters exact scenario and purse")
 check(find(app,"Depart for Dock Town").disabled,"No empty departure")
 check(find(app,"Hire Roderic").disabled and find(app,"Hire Ysra").disabled,"Both elites visible and unaffordable")
 await click("Hire Militia Spearman")
 check(find(app,"Depart for Dock Town").disabled,"One recruit still cannot depart")
 await click("Hire Militia Spearman")
 check(not find(app,"Depart for Dock Town").disabled and app.game.s.funds==2160,"Two individual paid recruits enable departure")
 var ids=app.game.s.squads.first.members.duplicate()
 await click("Hire Mara")
 check(find(app,"Hire Mara").disabled,"Named professional cannot be selected twice")
 await click("Save selection");await click("Hire Oswin");await click("Load selection")
 check(app.game.s.funds==1810 and app.game.s.squads.first.members.size()==3,"Opening save/load restores exact selection and fees")
 await click("Remove Hireling 00000001 · Militia Spearman · refund 120")
 check(app.game.s.funds==1930 and not app.game.s.mercs.has(ids[0]),"Opening cancellation refunds once")
 await click("Depart for Dock Town")
 check(app.game.s.opening_voyage.phase=="arrived" and app.game.s.squads.first.sector==17,"Controls land selected company at Dock Town")
 await click("Dock Town")
 check(find(app,"Recruitment harbour")!=null and app.map_view==null,"Staging port displayed without unfinished island map")
 await click("Save");await click("Load")
 check(app.game.s.opening_voyage.phase=="arrived" and app.game.s.funds==1930,"Landed company survives normal save/load controls")
 # Deterministic clock fixture only; buying uses real controls.
 app.game.advance(app.Campaign.Shipping.FIRST_ARRIVAL-app.game.s.time);app.change_tab("harbour");await settle()
 var v=app.game.s.shipping.vessels[0];var offer=v.offers[0]
 await click("Hire passenger "+offer.name)
 check(offer.status=="hired" and app.game.s.mercs.has(offer.candidate_id),"Actual harbour control hires saved passenger")
 check(find(app,"Hire passenger "+offer.name).disabled,"Hired offer disabled")
 var manifest=JSON.stringify(app.game.s.shipping)
 await click("Save");await click("Load")
 check(JSON.stringify(app.game.s.shipping)==manifest,"Vessel offers retain identity through UI save/load")
 app.Campaign.Shipping.set_closure(app.game,"Test closure");app.refresh();await settle()
 for o in app.game.s.shipping.vessels[0].offers: check(find(app,"Hire passenger "+o.name).disabled,"Blockade disables passenger purchase")
 app.Campaign.Shipping.set_closure(app.game,"");app.refresh();await settle()
 check(app.game.valid_save(app.game.s),"Rendered scenario remains valid")
 await click("Visit Dock Town")
 check(app.game.battle!=null and find(app,"Battle")!=null and app.tab=="sector","Dock Town visit exposes established tactical controls")
 await click("Company");await click("Battle")
 check(app.tab=="sector","Tactical panel can be restored from company management")
 await click("Leave sector")
 check(app.game.battle==null and find(app,"Dock Town")!=null,"Leaving tactical visit restores staging port")
 await process_frame
 if DisplayServer.get_name()!="headless": root.get_texture().get_image().save_png("res://greywake-ui-preview.png")
 var report={"passed":passed,"failed":failures.size(),"failures":failures}
 var f=FileAccess.open("res://greywake-ui-results.json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"  "));f.close()
 print("GREYWAKE_UI: "+JSON.stringify(report));app.queue_free();await settle();quit(0 if failures.is_empty() else 1)
