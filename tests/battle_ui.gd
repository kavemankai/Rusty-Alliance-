extends SceneTree
var app
var passed=0
var failures=[]
func _init() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
 if ok: passed+=1
 else: failures.append(message);print("FAIL: "+message)
func frames() -> void: await process_frame;await process_frame;await process_frame
func click(control: Control) -> void:
 for pressed in [true,false]:
  var event=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed;event.position=control.get_global_rect().get_center();root.push_input(event)
 await frames()
func key(code: int) -> void:
 for pressed in [true,false]:
  var event=InputEventKey.new();event.keycode=code;event.pressed=pressed;root.push_input(event)
 await frames()
func tile_click(x: int,y: int,right: bool=false) -> void:
 var view=app.battle_view;var height=app.game.battle.Visibility.cell(app.game.battle,x,y).elevation*.5+.06
 var point=view.get_global_transform()*(view.camera.unproject_position(Vector3(x,height,y))*view.size/Vector2(view.viewport.size))
 for pressed in [true,false]:
  var event=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_RIGHT if right else MOUSE_BUTTON_LEFT;event.pressed=pressed;event.position=point;root.push_input(event)
 await frames()
func entry(prefix: String):
 for button in app.battle_radial.buttons:
  if str(button.get_meta("radial_entry","")).begins_with(prefix): return button
 return null
func choose(prefix: String) -> void:
 var found=entry(prefix)
 check(found!=null,"Radial offers "+prefix)
 if found!=null: await click(found)
func destination(actor) -> Dictionary:
 var b=app.game.battle
 for delta in [Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT,Vector2i.UP]:
  var x=actor.x+delta.x;var y=actor.y+delta.y
  if b.tile(x,y).is_empty() or b.at(x,y)!=null: continue
  var route=b.path(actor,x,y,true)
  if not route.path.is_empty() and route.cost>0 and route.cost<=actor.ap: return {"x":x,"y":y,"cost":route.cost}
 return {}
func run() -> void:
 app=load("res://main.tscn").instantiate();app.desktop.path="user://battle-ui-test-settings.cfg";root.add_child(app);await frames()
 app.start_greywake();app.game.autosave_path="user://battle-ui-test-auto.json";app.save_slot="user://battle-ui-test-save.json";app.game.command("opening_skip")
 for i in range(6): check(app.game.command("recruit_template",{"template":"militia_crossbowman" if i==0 else "militia_spearman"}),"Paid canonical fixture hire")
 for action in ["opening_confirm","opening_depart","opening_skip","opening_next","opening_next","dockside_start","confirm_deployment"]: check(app.game.command(action),"Canonical setup "+action)
 app.rebuild();await frames()
 var b=app.game.battle;var actor=b.unit(app.selected)
 for spec in [[1280,720,1.0],[1600,900,1.0],[1920,1080,1.0],[1280,720,1.3]]:
  root.size=Vector2i(spec[0],spec[1]);app.desktop.ui_scale=spec[2];app.apply_desktop_theme();app.rebuild();await frames()
  check(root.size==Vector2i(spec[0],spec[1]),"Actual window size is retained")
  check(not app.side.get_parent().visible,"Battle defaults to an unobstructed field")
  check(app.battle_view.size.x>=root.size.x-5,"Battlefield spans the window")
  check(app.crew.get_child_count()==6 and app.battle_hud.get_global_rect().position.y>=app.battle_view.get_global_rect().end.y,"Actual company portraits sit below the battlefield")
  for child in app.crew.get_children(): check(root.get_visible_rect().encloses(child.get_global_rect()),"Every crew portrait remains accessible")
  check(root.get_visible_rect().encloses(app.action_dock.get_global_rect()),"Primary preview controls stay in bounds")
  check(root.get_visible_rect().encloses(app.battle_hud.overview.get_global_rect()),"Knowledge-limited overview stays in bounds")
  var dest=destination(b.unit(app.selected));check(not dest.is_empty(),"Legal move context exists")
  if not dest.is_empty():
   await tile_click(dest.x,dest.y)
   check(app.battle_radial.visible,"A real battlefield click opens the radial")
   for button in app.battle_radial.buttons: check(root.get_visible_rect().encloses(button.get_global_rect()),"Radial choices remain in bounds")
   await key(KEY_ESCAPE)
 root.size=Vector2i(1600,900);app.desktop.ui_scale=1;app.apply_desktop_theme();app.rebuild();await frames();actor=b.unit(app.selected)
 var other=app.fighters()[1]
 await tile_click(other.x,other.y)
 check(app.selected==other.id and app.battle_view.selected==other.id,"Clicking a fighter changes the active world highlight")
 for card in app.crew.get_children(): check(card.button_pressed==(card.name=="crew_"+other.id),"World selection synchronizes the bottom portrait highlight")
 await key(KEY_ESCAPE);app.select_fighter(0);await frames();actor=b.unit(app.selected)
 var dest=destination(actor);var ap=actor.ap;var rng=app.game.s.rng;var funds=app.game.s.funds
 await tile_click(dest.x,dest.y)
 check(actor.ap==ap and app.game.s.rng==rng and app.game.s.funds==funds,"Opening move options spends no AP, money or RNG")
 await choose("Move\n")
 check(actor.x==dest.x and actor.y==dest.y and actor.ap==ap-dest.cost and not app.battle_radial.visible,"Radial move spends the exact previewed AP once")
 dest=destination(actor);await tile_click(dest.x,dest.y);ap=actor.ap;actor.ap=0;var snapshot=JSON.stringify(app.game.s)
 await choose("Move\n")
 check(JSON.stringify(app.game.s)==snapshot and not app.battle_radial.visible,"A stale radial action fails without partial mutation")
 actor.ap=ap;app.refresh();app.end_player_turn();await frames()
 var victim=null
 for enemy in b.t.units:
  if enemy.team!="company" and enemy.person.hp>0 and b.known("company",enemy.id) and (victim==null or enemy.person.hp>victim.person.hp): victim=enemy
 check(victim!=null,"A real currently visible enemy is available")
 if victim!=null:
  await tile_click(victim.x,victim.y)
  check(app.target==victim.id and victim.id in app.battle_view.highlighted_units(),"Visible selected target receives the world highlight")
  check(app.selected in app.battle_view.highlighted_units(),"Active fighter remains independently highlighted")
  var round_before=b.t.round;var before=JSON.stringify(app.game.s);await key(KEY_SPACE);await key(KEY_G)
  check(b.t.round==round_before and JSON.stringify(app.game.s)==before,"Open radial blocks turn/guard shortcuts")
  var aiming_ap=actor.ap;var aiming_ammo=app.Data.ammo(actor.person)
  await choose("Attack options");await choose("Aim +")
  check(app.aim==1 and actor.ap==aiming_ap and app.Data.ammo(actor.person)==aiming_ammo and JSON.stringify(app.game.s)==before,"Radial aiming changes only the shared preview")
  await tile_click(victim.x,victim.y);var cost=b.Combat.cost(actor,app.aim);ap=actor.ap;var ammo=app.Data.ammo(actor.person)
  await choose("Attack\n")
  check(actor.ap==ap-cost and app.Data.ammo(actor.person)==ammo-1 and not actor.person.loaded,"Radial attack uses canonical AP and one owned bolt")
  await tile_click(actor.x,actor.y);await choose("Stance / pace");ap=actor.ap;await choose("Crouch")
  check(actor.stance=="crouch" and actor.ap==ap-2,"Radial stance uses the existing two-AP command")
  app.battle_view.highlight_target=victim.id;b.t.knowledge.company[victim.id].visible=false
  check(victim.id not in app.battle_view.highlighted_units() and victim.id not in app.battle_hud.overview.marker_ids(),"Unseen enemies have no target highlight or overview marker")
  app.target=victim.id;app.show_panel();check(app.target=="","Hidden target details are cleared")
  await tile_click(victim.x,victim.y,true)
  check(app.target=="" and entry("Attack\n")==null,"Right-clicking unseen ground cannot expose a target or attack offer")
  await key(KEY_ESCAPE)
 await click(app.battle_hud.details_button)
 check(app.side.get_parent().visible,"Details button exposes the complete existing inspector")
 await click(app.battle_hud.details_button);check(not app.side.get_parent().visible,"Details closes without replacing the bottom HUD")
 var before_overview=JSON.stringify(app.game.s);var camera=app.battle_view.camera.position
 await click(app.battle_hud.overview)
 check(app.battle_view.camera.position!=camera and JSON.stringify(app.game.s)==before_overview,"Overview recenters camera without simulation mutation")
 app._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
 check(not app.battle_radial.visible,"Losing focus dismisses contextual UI")
 app._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
 check(app.game.valid_save(app.game.s) and app.game.Items.ownership_error(app.game.s)=="","HUD and radial retain valid identities and owned inventories")
 var report={"passed":passed,"failed":failures.size(),"failures":failures}
 var out=FileAccess.open("res://battle-ui-results.json",FileAccess.WRITE);out.store_string(JSON.stringify(report,"  "));out.close();print("BATTLE_UI: "+JSON.stringify(report));app.queue_free();await frames();quit(0 if failures.is_empty() else 1)
