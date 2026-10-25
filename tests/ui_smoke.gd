extends SceneTree
var app
var failures=[]

func _init() -> void:
 call_deferred("run")

func settle() -> void:
 await process_frame
 await process_frame

func find_button(node: Node,text: String):
 if node is Button and node.text==text: return node
 for child in node.get_children():
  var found=find_button(child,text)
  if found!=null: return found
 return null

func click(text: String) -> void:
 var b=find_button(app,text)
 if b==null:
  failures.append("Missing button: "+text)
  return
 var ancestor=b.get_parent()
 while ancestor!=null:
  if ancestor is ScrollContainer: ancestor.ensure_control_visible(b)
  ancestor=ancestor.get_parent()
 await settle()
 var pos=b.get_global_rect().get_center()
 var down=InputEventMouseButton.new()
 down.button_index=MOUSE_BUTTON_LEFT
 down.pressed=true
 down.position=pos
 root.push_input(down)
 var up=InputEventMouseButton.new()
 up.button_index=MOUSE_BUTTON_LEFT
 up.pressed=false
 up.position=pos
 root.push_input(up)
 await settle()

func capture(filename: String) -> void:
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://"+filename)

func select_sector(index: int) -> void:
 var view=app.map_view
 var point=view.offset+Vector2(index%16+0.5,int(index/16)+0.5)*32*view.zoom
 var down=InputEventMouseButton.new()
 down.button_index=MOUSE_BUTTON_LEFT;down.pressed=true;down.position=point
 view.input_event(down)
 var up=InputEventMouseButton.new()
 up.button_index=MOUSE_BUTTON_LEFT;up.pressed=false;up.position=point
 view.input_event(up)
 await settle()

func fight_with_buttons() -> void:
 var rounds=0
 while app.game.battle.outcome()=="ongoing" and rounds<30:
  var b=app.game.battle
  for fighter in b.t.units:
   if fighter.team!="company" or not b.can_act(fighter): continue
   app.battle_view.pick(app.battle_view.camera.unproject_position(Vector3(fighter.x,b.tile(fighter.x,fighter.y).elevation*0.5,fighter.y))*app.battle_view.size/Vector2(app.battle_view.viewport.size))
   await settle()
   if app.selected!=fighter.id:
    failures.append("Could not select "+fighter.id)
    continue
   var actions=0
   while b.can_act(fighter) and fighter.ap>0 and actions<16:
    actions+=1
    var provisions=app.game.Supplies.for_person(app.game.s,fighter.id)
    if fighter.person.bleeding>0 and fighter.ap>=5 and provisions.get("medicine",0)>0:
     await click("First aid self · 5 AP")
     continue
    var candidates=[]
    for other in b.t.units:
     if other.team!="company" and other.person.hp>10 and b.known("company",other.id): candidates.append(other)
    candidates.sort_custom(func(a,z):return b.distance(fighter,a)<b.distance(fighter,z))
    var weapon=app.Data.WEAPONS[app.Data.weapon(fighter.person)]
    if weapon.reach==0 and not fighter.person.loaded and fighter.ap>=weapon.reload and app.Data.ammo(fighter.person)>0:
     await click("Reload")
     continue
    var enemy=candidates[0] if not candidates.is_empty() else null
    if enemy!=null and b.distance(fighter,enemy)<=weapon.range and b.los(fighter,enemy) and fighter.ap>=weapon.ap:
     app.tactical_cell(enemy.x,enemy.y)
     await settle()
     await click("Confirm attack")
     continue
    var goal=enemy if enemy!=null else {"x":11,"y":6}
    var best={}
    var score=-9999
    for dy in range(-1,2):
     for dx in range(-1,2):
      var cell=b.tile(fighter.x+dx,fighter.y+dy)
      var cost=b.step_cost(fighter,b.tile(fighter.x,fighter.y),cell)
      if cost<0 or cost>fighter.ap: continue
      var value=-b.distance(cell,goal)*10-cost
      if value>score:
       score=value
       best=cell
    if best.is_empty(): break
    app.tactical_cell(best.x,best.y)
    await settle()
    await click("Confirm movement")
  if b.outcome()=="ongoing": await click("End turn")
  rounds+=1

func run() -> void:
 app=load("res://main.tscn").instantiate()
 app.save_slot="user://ui-test-campaign.json"
 root.add_child(app)
 await settle()
 await click("New campaign")
 if app.game!=null: app.game.autosave_path="user://ui-test-autosave.json"
 if app.game==null:
  failures.append("New campaign did not start")
  print(failures)
  quit(1)
  return
 await capture("strategic-preview.png")
 await click("Company")
 await click("Ada · physician")
 await click("Hire · 100 crowns / 7 days")
 if not app.game.s.mercs.ada.hired: failures.append("Recruitment UI did not hire Ada")
 await click("Inventory")
 await click("Mara")
 var spare_sword={}
 for entry in app.game.s.stash:
  if entry.kind=="sword": spare_sword=entry;break
 await click("Take Sword · 100% condition")
 await click("Sword · 100% condition")
 await click("Give to Ada")
 await click("Ada")
 await click("Sword · 100% condition")
 await click("Equip carried item")
 if app.Data.equipped(app.game.s.mercs.ada,"weapon").get("id","")!=spare_sword.id: failures.append("Item UI did not transfer and equip the same sword")
 await capture("inventory-preview.png")
 await click("Spear · 100% condition")
 await click("Equip carried item")
 if app.Data.weapon(app.game.s.mercs.ada)!="spear": failures.append("Inventory UI did not restore carried spear")
 await click("Supplies")
 await click("Store 5 food in depot")
 if app.game.s.sectors[17].supplies.food!=5 or app.game.s.squads.first.supplies.food!=55: failures.append("Supply UI did not deposit real rations")
 await click("Load 5 food from depot")
 if app.game.s.sectors[17].supplies.food!=0 or app.game.s.squads.first.supplies.food!=60: failures.append("Supply UI did not restore rations from the depot")
 await click("Contracts")
 await click("Accept Clear Redbank")
 if app.game.s.jobs[0].status!="active": failures.append("Contract UI did not accept")
 await click("Map")
 var view=app.map_view
 var point=view.offset+Vector2(2.5,2.5)*32*view.zoom
 var d=InputEventMouseButton.new()
 d.button_index=MOUSE_BUTTON_LEFT; d.pressed=true; d.position=point
 view.input_event(d)
 var u=InputEventMouseButton.new()
 u.button_index=MOUSE_BUTTON_LEFT; u.pressed=false; u.position=point
 view.input_event(u)
 await settle()
 await click("Plot route to selected sector")
 await click("+6 hours")
 if app.game.s.encounter.is_empty(): failures.append("Travel UI did not create encounter")
 await click("Deploy company")
 if app.game.battle==null:
  failures.append("Deploy UI failed")
 else:
  if app.game.battle.t.phase!="deployment": failures.append("Contact skipped deployment review")
  await click(("● " if app.selected=="mara" else "")+"Mara · placed")
  var actor=app.game.battle.unit("mara")
  var ap_before=actor.ap
  app.battle_view.pick(app.battle_view.camera.unproject_position(Vector3(3,0,3))*app.battle_view.size/Vector2(app.battle_view.viewport.size))
  await settle()
  await click("Confirm placement")
  await click("Rotate facing · free")
  if actor.x!=3 or actor.y!=3 or actor.facing!=1 or actor.ap!=ap_before: failures.append("Deployment controls did not place and turn without AP cost")
  await click("Save")
  await click("Load")
  if app.game.battle.t.phase!="deployment" or app.game.battle.unit("mara").x!=3: failures.append("UI save/load lost unconfirmed formation")
  await capture("deployment-preview.png")
  await click("Begin combat")
  if app.game.battle.t.phase!="combat": failures.append("Begin combat did not confirm deployment")
  await click("End turn")
  if app.game.battle.t.round!=2: failures.append("End turn UI failed")
  await capture("tactical-preview.png")
  await click("Inventory")
  await click("Map")
  await click("Save")
  await click("Load")
  if app.game.battle==null: failures.append("UI save/load lost active battle")
  await fight_with_buttons()
  if app.game.battle.outcome()!="victory": failures.append("UI battle did not win")
  else:
   await click("Resolve")
   if app.game.s.jobs[0].status!="paid": failures.append("UI battle did not pay contract")
   await click("Save")
   await click("Load")
   if app.game.s.sectors[34].owner!="company": failures.append("UI victory did not persist")
 # A deterministic second campaign places an existing enemy patrol one sector
 # from Ashford. Recruitment, stocking, travel, time and defence all use controls.
 app.game=app.Campaign.new()
 app.game.autosave_path="user://ui-test-autosave.json"
 app.game.s.groups[0].sector=18
 app.game.s.groups[0].objective=17
 app.game.s.sectors[18].owner="bandits"
 app.sector=17;app.squad="first";app.selected="mara";app.tab="sector"
 app.rebuild()
 await settle()
 await click("Contracts")
 await click("Accept Defend Ashford from the raiders")
 await click("Inventory")
 await click("Buy food · 20 crowns")
 await click("Buy food · 20 crowns")
 await click("Map")
 for i in range(3): await click("Recruit levy · 80 crowns")
 await click("Supplies")
 await click("20")
 for i in range(3): await click("Store 20 food in depot")
 await click("5")
 await click("Store 5 medicine in depot")
 if app.game.s.sectors[17].supplies.food!=60 or app.game.Garrison.strength(app.game.s.sectors[17])!=3: failures.append("UI did not recruit and stock a real garrison")
 await capture("supplies-preview.png")
 await click("Map")
 await select_sector(1)
 await click("Plot route to selected sector")
 await click("+1 hour")
 for i in range(3): await click("+6 hours")
 if app.game.s.encounter.is_empty() or app.game.s.encounter.squad!="": failures.append("Strategic attack did not create a garrison-only contact")
 await click("Deploy garrison")
 if app.game.battle==null: failures.append("Garrison deployment UI failed")
 else:
  if app.target!="": failures.append("New garrison battle retained a stale enemy selection")
  if app.game.battle.t.phase!="deployment": failures.append("Garrison did not enter deployment")
  var levy=app.game.battle.unit(app.selected)
  var old_ap=levy.ap
  app.battle_view.pick(app.battle_view.camera.unproject_position(Vector3(3,0,3))*app.battle_view.size/Vector2(app.battle_view.viewport.size))
  await settle()
  await click("Confirm placement")
  if levy.x!=3 or levy.y!=3 or levy.ap!=old_ap: failures.append("Garrison placement control failed")
  await click("Save")
  await click("Load")
  if app.game.battle.t.phase!="deployment": failures.append("UI save/load skipped garrison deployment")
  await click("Begin combat")
  await capture("garrison-preview.png")
  await click("Save")
  await click("Load")
  if app.game.battle.unit("mara")!=null: failures.append("Remote mercenary teleported into garrison defence")
  await fight_with_buttons()
  if app.game.battle.outcome()!="victory": failures.append("Garrison UI defence did not win")
  else:
   await click("Resolve")
   var survivors=app.game.Garrison.strength(app.game.s.sectors[17])
   await click("Save")
   await click("Load")
   if app.game.s.sectors[17].owner!="company" or app.game.s.squads.first.sector!=1 or app.game.Garrison.strength(app.game.s.sectors[17])!=survivors: failures.append("Garrison victory did not persist correctly")
   if app.game.s.jobs[6].status!="paid": failures.append("Garrison victory did not fulfil settlement defence")
 # A third campaign exercises pickup, freight, ordered patrol and return using
 # controls. The quiet-road fixture removes hostile forces, never sets results.
 app.game=app.Campaign.new()
 app.game.autosave_path="user://ui-test-autosave.json"
 app.game.s.groups=[]
 app.sector=17;app.squad="first";app.selected="mara";app.tab="sector"
 app.rebuild()
 await settle()
 await click("Contracts")
 await click("Accept Escort the Willow provisions")
 await click("Accept Patrol the western road")
 if app.game.s.jobs[4].cargo!=20 or app.game.s.jobs[5].status!="active": failures.append("Road work UI did not assign freight and patrol")
 await capture("contracts-preview.png")
 await click("Map")
 await select_sector(33)
 await click("Plot route to selected sector")
 await click("+6 hours")
 await click("Save")
 await click("Load")
 if app.game.s.jobs[5].step!=1 or app.game.s.jobs[4].cargo!=20: failures.append("UI save/load lost road objective progress")
 for index in [49,81,17]:
  await select_sector(index)
  await click("Plot route to selected sector")
  await click("+6 hours")
  if not app.game.s.squads.first.route.is_empty(): await click("+6 hours")
 if app.game.s.jobs[4].status!="paid" or app.game.s.jobs[5].status!="paid" or app.game.s.sectors[49].supplies.food!=20: failures.append("UI road route did not fulfil delivery and ordered patrol")
 await click("Save")
 await click("Load")
 if app.game.s.jobs[5].status!="paid": failures.append("UI lost paid patrol after reload")
 var result={"failed":failures.size(),"failures":failures,"scope":"Desktop controls: review/place/face/save/confirm company and garrison deployment, company and item management, supply deposit/load, capture contract battle, then recruit and stock levies, march company away, advance to an actual strategic attack, garrison-only defence, settlement defence payment, escorted freight, ordered patrol return and active/paid save/load"}
 var report=FileAccess.open("res://ui-test-results.json",FileAccess.WRITE)
 report.store_string(JSON.stringify(result,"  "))
 report.close()
 print("UI_SMOKE: "+JSON.stringify(result))
 app.queue_free()
 await settle()
 quit(0 if failures.is_empty() else 1)
