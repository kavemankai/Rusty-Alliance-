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
  await click("End turn")
  if app.game.battle.t.round!=2: failures.append("End turn UI failed")
  await capture("tactical-preview.png")
  await click("Inventory")
  await click("Map")
  await click("Save")
  await click("Load")
  if app.game.battle==null: failures.append("UI save/load lost active battle")
  var rounds=0
  while app.game.battle.outcome()=="ongoing" and rounds<30:
   var b=app.game.battle
   for fighter in b.t.units:
    if fighter.team!="company" or not b.can_act(fighter): continue
    app.battle_view.pick(app.battle_view.camera.unproject_position(Vector3(fighter.x,b.tile(fighter.x,fighter.y).elevation*0.5,fighter.y))*app.battle_view.size/Vector2(app.battle_view.viewport.size))
    await settle()
    var actions=0
    while b.can_act(fighter) and fighter.ap>0 and actions<16:
     actions+=1
     var candidates=[]
     for other in b.t.units:
      if other.team!="company" and other.person.hp>10 and b.known("company",other.id): candidates.append(other)
     candidates.sort_custom(func(a,z):return b.distance(fighter,a)<b.distance(fighter,z))
     var weapon=app.Data.WEAPONS[fighter.person.weapon]
     if weapon.reach==0 and not fighter.person.loaded and fighter.ap>=weapon.reload and fighter.person.ammo>0:
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
  if app.game.battle.outcome()!="victory": failures.append("UI battle did not win")
  else:
   await click("Resolve")
   if app.game.s.jobs[0].status!="paid": failures.append("UI battle did not pay contract")
   await click("Save")
   await click("Load")
   if app.game.s.sectors[34].owner!="company": failures.append("UI victory did not persist")
 var result={"failed":failures.size(),"failures":failures,"scope":"Desktop normal controls: recruit, contract, route, battle, payment, active-battle and post-victory save/load"}
 var report=FileAccess.open("res://ui-test-results.json",FileAccess.WRITE)
 report.store_string(JSON.stringify(result,"  "))
 report.close()
 print("UI_SMOKE: "+JSON.stringify(result))
 app.queue_free()
 await settle()
 quit(0 if failures.is_empty() else 1)
