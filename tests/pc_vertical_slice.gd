extends SceneTree
var app
var passed=0
var failures=[]
var measurements={}
func _init() -> void: call_deferred("run")
func check(ok: bool,title: String) -> void:
 if ok: passed+=1
 else: failures.append(title);print("FAIL: "+title)
func settle() -> void: await process_frame;await process_frame;await create_timer(.32).timeout
func find(node: Node,title: String):
 if node is Button and (node.text==title or node.text.begins_with(title)): return node
 for child in node.get_children():
  var found=find(child,title)
  if found!=null: return found
 return null
func click(title: String) -> void:
 var button=find(app,title)
 if button==null: check(false,"Missing control "+title);return
 if is_instance_valid(app.battle_hud) and is_instance_valid(app.side) and app.side.get_parent().is_ancestor_of(button) and not app.side.get_parent().visible:
  await click("Details")
  button=find(app,title)
 var parent=button.get_parent()
 while parent!=null:
  if parent is ScrollContainer: parent.ensure_control_visible(button)
  parent=parent.get_parent()
 await settle()
 for pressed in [true,false]:
  var event=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed;event.position=button.get_global_rect().get_center();button.get_viewport().push_input(event)
 await settle()
func select_island(index: int) -> void:
 await key(KEY_M)
 var position=app.map_view.get_global_transform()*app.map_view.point(index)
 for pressed in [true,false]:
  var event=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed;event.position=position;root.push_input(event)
 await settle()
 check(app.sector==index,"Native island click selects sector "+str(index))
func travel_to(index: int) -> void:
 await select_island(index)
 await click("Travel to "+app.game.s.sectors[index].name)
 for step in range(5):
  if app.game.s.squads.first.route.is_empty(): break
  await click("+6 hours")
 check(app.game.s.squads.first.sector==index and app.game.s.encounter.is_empty(),"UI travel reaches "+app.game.s.sectors[index].name)
func key(code: int,shift: bool=false,ctrl: bool=false) -> void:
 for pressed in [true,false]:
  var event=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=pressed;event.shift_pressed=shift;event.ctrl_pressed=ctrl
  if code>=KEY_A and code<=KEY_Z: event.unicode=code if shift else code+32
  elif code==KEY_SPACE: event.unicode=32
  Input.parse_input_event(event);await create_timer(.04).timeout
 await settle()
func capture(name: String) -> void:
 app._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
 await settle();root.get_texture().get_image().save_png("res://pc-"+name+"-preview.png")
func state() -> String: return JSON.stringify(app.game.s)
func actors(view) -> Array:
 var ids=[]
 for child in view.geometry.get_children():
  if child.has_meta("actor_id"): ids.append(child.get_instance_id())
 return ids
func run() -> void:
 app=load("res://main.tscn").instantiate();app.desktop.path="user://pc-acceptance-settings.cfg"
 if FileAccess.file_exists(app.desktop.path): DirAccess.remove_absolute(ProjectSettings.globalize_path(app.desktop.path))
 root.add_child(app);await settle()
 check(root.content_scale_mode==Window.CONTENT_SCALE_MODE_DISABLED,"PC layout uses native window coordinates")
 check(Engine.max_fps==60,"Desktop defaults cap the frame rate at 60")
 await key(KEY_F1)
 check(app.PC.modal(app) and app.game==null,"Help works from the title without creating a campaign")
 for child in app.ui.get_children():
  if child is AcceptDialog and child!=app.confirm and child.visible: child.hide();child.queue_free()
 await click("New Game");app.game.autosave_path="user://pc-acceptance-auto.json";app.save_slot="user://pc-acceptance-save.json"
 await key(KEY_ENTER)
 check(app.game.s.opening_flow.dialogue_index==1,"Enter advances actual briefing")
 await click("Enter tavern")
 for repeat in range(6): check(app.game.command("recruit_template",{"template":"militia_crossbowman" if repeat==0 else "militia_spearman"}),"Paid canonical recruit "+str(repeat))
 app.rebuild();await settle()
 for dimensions in [Vector2i(1280,720),Vector2i(1600,900),Vector2i(1920,1080)]:
  root.size=dimensions;await settle();check(root.size==dimensions,"Requested window size is retained: "+str(dimensions));var rect=root.get_visible_rect()
  for template in app.game.s.recruitment.templates: check(rect.encloses(find(app,template.name).get_global_rect()),"Roster accessible at "+str(dimensions)+": "+template.id)
  check(rect.encloses(find(app,"Set Sail").get_global_rect()),"Six-person departure accessible at "+str(dimensions))
 root.size=Vector2i(1280,720);app.desktop.ui_scale=1.3;app.apply_desktop_theme();app.rebuild();await settle()
 check(root.get_visible_rect().encloses(find(app,"Set Sail").get_global_rect()),"Large UI setting retains departure at minimum resolution")
 app.desktop.ui_scale=1.0;app.apply_desktop_theme();root.size=Vector2i(1600,900);app.rebuild();await settle();await capture("tavern")
 await click("Set Sail")
 find(app,"Return to tavern").grab_focus();await key(KEY_ENTER)
 check(app.game.s.opening_flow.stage=="TAVERN_RECRUITMENT" and app.game.s.funds==1660,"Enter respects a focused Return button instead of committing departure")
 await click("Set Sail");await key(KEY_ENTER);await key(KEY_SPACE);await key(KEY_ENTER);await key(KEY_ENTER)
 check(app.game.s.opening_flow.stage=="GREYWAKE_CAMPAIGN" and app.game.s.funds==1660,"Keyboard departure/crossing preserves exact paid six-person company")
 await key(KEY_F5)
 check(FileAccess.file_exists(app.save_slot),"F5 saves the active scenario slot")
 var before=state();await key(KEY_F9);await key(KEY_G)
 check(app.confirm.visible and state()==before,"Load confirmation blocks gameplay hotkeys without mutation")
 app.confirm.get_cancel_button().pressed.emit();await settle()
 check(state()==before,"Cancelling quickload preserves the complete campaign")
 await click("Deal with Dockside Trouble")
 var available=app.fighters();var view=app.battle_view
 check(available.size()==6 and app.crew.get_child_count()==6,"Tactical crew strip shows the actual six-person company")
 check(root.get_visible_rect().encloses(app.action_dock.get_global_rect()),"Primary action dock stays on screen")
 view.pan_screen(Vector2(80,30));var position=view.camera.position
 await key(KEY_ENTER)
 check(app.game.battle.t.phase=="combat" and app.battle_view.camera.position.is_equal_approx(position),"Enter begins real combat and preserves deployment camera")
 await click("Details")
 var splitter=app.content;var old_width=splitter.get_child(1).size.x;var snapshot=state()
 var handle=Vector2(splitter.get_child(0).get_global_rect().end.x+6,splitter.get_global_rect().get_center().y)
 var down=InputEventMouseButton.new();down.button_index=MOUSE_BUTTON_LEFT;down.pressed=true;down.position=handle;root.push_input(down)
 var drag=InputEventMouseMotion.new();drag.button_mask=MOUSE_BUTTON_MASK_LEFT;drag.position=handle-Vector2(100,0);drag.relative=Vector2(-100,0);root.push_input(drag)
 var up=InputEventMouseButton.new();up.button_index=MOUSE_BUTTON_LEFT;up.position=drag.position;root.push_input(up);await settle()
 check(splitter.get_child(1).size.x>old_width+60,"Mouse drag resizes the PC inspector")
 var retained=splitter.get_child(1).size.x;app.rebuild();await settle()
 check(absf(app.content.get_child(1).size.x-retained)<3 and state()==snapshot,"Inspector width and authoritative state survive UI rebuild")
 await key(KEY_2)
 check(app.selected==available[1].id,"Number key selects the corresponding persistent individual")
 await key(KEY_TAB)
 check(app.selected==available[2].id,"Tab cycles company fighters")
 await key(KEY_TAB,true)
 check(app.selected==available[1].id,"Shift+Tab cycles back")
 before=state();var camera_before=app.battle_view.camera.position
 var press=InputEventKey.new();press.keycode=KEY_W;press.pressed=true;root.push_input(press);await create_timer(.2).timeout
 var release=InputEventKey.new();release.keycode=KEY_W;root.push_input(release);await settle()
 check(app.battle_view.camera.position!=camera_before and state()==before,"WASD pans camera without spending AP or campaign time")
 await key(KEY_F);await key(KEY_HOME)
 check(state()==before,"Center/reset camera do not mutate simulation or RNG")
 var actor=app.game.battle.unit(app.selected);var destination={}
 for offset in [Vector2i(1,0),Vector2i(0,1),Vector2i(-1,0),Vector2i(0,-1)]:
  var tile=app.game.battle.tile(actor.x+offset.x,actor.y+offset.y)
  if tile.is_empty(): continue
  if app.game.battle.at(tile.x,tile.y)==null:
   var route=app.game.battle.path(actor,tile.x,tile.y,true)
   if not route.path.is_empty() and route.cost>0 and route.cost<=actor.ap: destination={"x":tile.x,"y":tile.y,"cost":route.cost};break
 check(not destination.is_empty(),"Fixture has a legitimate previewed move")
 if not destination.is_empty():
  app.tactical_cell(destination.x,destination.y);await settle();var ap=actor.ap
  check(app.preview_caption.text.contains(str(destination.cost)+" AP"),"Persistent action dock shows the authoritative route cost")
  await key(KEY_ENTER)
  check(actor.x==destination.x and actor.y==destination.y and actor.ap==ap-destination.cost,"Enter executes preview once with the exact AP cost")
 before=state();await key(KEY_R)
 check(state()==before,"Invalid reload shortcut cannot mutate a melee fighter")
 await key(KEY_G)
 check(app.game.battle.unit(app.selected).guard,"Guard shortcut prepares the real defence state")
 var round_before=app.game.battle.t.round;await key(KEY_SPACE)
 check(app.game.battle.t.round==round_before+1 and app.game.battle.t.turn=="company" and app.game.s.time==480,"Space runs enemy AI once without advancing campaign time")
 await key(KEY_1);var shooter=app.game.battle.unit(app.selected);var victim=null
 for enemy in app.game.battle.t.units:
  if enemy.team!="company" and enemy.person.hp>0 and app.game.battle.known("company",enemy.id) and app.game.battle.los(shooter,enemy) and app.game.battle.distance(shooter,enemy)<=app.Data.WEAPONS.crossbow.range: victim=enemy;break
 check(victim!=null,"Real visible crossbow target is available after enemy movement")
 if victim!=null:
  app.tactical_cell(victim.x,victim.y);await settle()
  var chance=app.game.battle.hit_chance(shooter,victim,0);var cost=app.game.battle.Combat.cost(shooter,0);var ammo=app.Data.ammo(shooter.person);var ap_before=shooter.ap
  check(app.preview_caption.text.contains(str(chance)+"%") and app.battle_view.highlight_target==victim.id,"PC preview identifies the actual target and authoritative hit chance")
  await key(KEY_ENTER)
  check(shooter.ap==ap_before-cost and app.Data.ammo(shooter.person)==ammo-1 and not shooter.person.loaded,"Enter fires once, spending the exact AP and one owned bolt")
  ap_before=shooter.ap;await key(KEY_R)
  check(shooter.person.loaded and shooter.ap==ap_before-app.Data.WEAPONS.crossbow.reload,"Reload shortcut spends the actual crossbow reload AP")
 var repeat_round=app.game.battle.t.round;var echo=InputEventKey.new();echo.pressed=true;echo.echo=true;echo.keycode=KEY_SPACE;root.push_input(echo);await settle()
 check(app.game.battle.t.round==repeat_round,"Key-repeat cannot end additional turns")

 # Text entry must never also act as camera/guard/end-turn input.
 var field=LineEdit.new();app.ui.add_child(field);field.grab_focus();await settle();before=state()
 for code in [KEY_R,KEY_G,KEY_SPACE,KEY_I,KEY_W]: await key(code)
 check(state()==before and app.pan_keys.is_empty(),"Typing is isolated from gameplay shortcuts and camera keys")
 field.queue_free();await settle();app.get_viewport().gui_release_focus()
 app.tactical_cell(8,8);await key(KEY_ESCAPE)
 check(app.destination.is_empty() and app.tab=="sector","First Escape cancels the current preview")
 await key(KEY_ESCAPE)
 check(app.tab=="settings" and app.auto_minutes==0,"Second Escape opens the paused PC settings")
 await click("Guard key:");await key(KEY_Y)
 check(app.desktop.keys.guard==KEY_Y and app.binding_action=="","Binding capture remaps Guard")
 await key(KEY_F11);check(root.mode==Window.MODE_FULLSCREEN,"Fullscreen shortcut changes the actual PC window")
 await key(KEY_F11);check(root.mode==Window.MODE_WINDOWED,"Fullscreen shortcut restores windowed play")
 var prefs=app.Desktop.new();prefs.path=app.desktop.path;prefs.load_settings()
 check(prefs.keys.guard==KEY_Y,"Remapped bindings survive a preferences reload")
 await key(KEY_ESCAPE)
 check(app.tab=="sector","Escape returns from PC settings")
 var camera_state=app.battle_view.camera.position;app.battle_view.camera.size=15;await key(KEY_F5)
 var saved=state();app.battle_action("stance",{"value":"crouch"});await key(KEY_F9)
 app.confirm.get_ok_button().pressed.emit();await settle()
 check(state()==saved and app.battle_view.camera.position.is_equal_approx(camera_state) and app.battle_view.camera.size==15,"Confirmed quickload restores exact battle state and retains camera")
 for dimensions in [Vector2i(1280,720),Vector2i(1920,1080)]:
  root.size=dimensions;await settle();view=app.battle_view;view.update_render_size();await settle()
  check(view.viewport.size.x>=int(view.size.x*.98) and view.viewport.size.y>=int(view.size.y*.98),"Battle texture follows native board resolution at "+str(dimensions))
  check(root.get_visible_rect().encloses(app.action_dock.get_global_rect()),"Combat controls remain visible at "+str(dimensions))
 view=app.battle_view;var ids=actors(view);var redraws=view.actor_rebuilds;var terrain=view.terrain_rebuilds;var timer=Time.get_ticks_usec()
 for repeat in range(100): view.selected=available[repeat%available.size()].id;view.redraw()
 measurements.cached_100_redraw_ms=(Time.get_ticks_usec()-timer)/1000.0
 check(actors(view)==ids and view.actor_rebuilds==redraws and view.terrain_rebuilds==terrain,"Repeated selection redraws reuse actual actors and terrain")
 var full=view.viewport.size;view.render_scale=.5;view.update_render_size()
 check(view.viewport.size.x<=int(full.x*.51),"Battle resolution setting changes real render-target pixels")
 view.render_scale=1;view.update_render_size();app._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
 check(app.background_paused and Engine.max_fps==15 and view.viewport.render_target_update_mode==SubViewport.UPDATE_DISABLED,"Focus loss pauses automatic advancement and disables tactical rendering")
 app._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
 check(not app.background_paused and Engine.max_fps==app.desktop.frame_limit,"Focus return restores chosen cap without resuming travel")
 view.reset_camera();await capture("combat")
 if root.has_method("grab_focus"): root.call("grab_focus");await settle()
 measurements.window_focused=root.has_focus();measurements.screen_refresh_hz=DisplayServer.screen_get_refresh_rate()
 var sampler=preload("res://tests/pc_frame_sampler.gd").new();app.add_child(sampler);sampler.start()
 var start_frames=Engine.get_process_frames();var frame_start=Time.get_ticks_usec()
 for frame in range(90): await process_frame
 var samples=sampler.finish();sampler.queue_free();samples.sort()
 measurements.idle_frame_median_ms=samples[samples.size()/2];measurements.idle_frame_p95_ms=samples[int(samples.size()*.95)]
 measurements.idle_process_fps=(Engine.get_process_frames()-start_frames)*1000000.0/(Time.get_ticks_usec()-frame_start);measurements.frame_samples=samples.size()
 measurements.render_pixels=[view.viewport.size.x,view.viewport.size.y];measurements.actor_rebuilds=view.actor_rebuilds
 var before_withdraw=app.game.s.funds
 await click("Retreat")
 check(app.confirm.visible,"Retreat opens the actual confirmation dialog")
 app.confirm.get_ok_button().grab_focus();await key(KEY_ENTER)
 check(app.game.s.funds==before_withdraw,"Confirmed withdrawal provides no free reward")
 check(app.game.battle==null and app.game.s.opening_flow.outcome=="retreat","Desktop battle returns persistent withdrawal to campaign")
 await capture("map")
 var survivors=app.game.s.squads.first.members.duplicate()
 await travel_to(84);await key(KEY_J);await click("Accept Harth farm-road rounds")
 check(app.game.s.jobs.filter(func(j):return j.id==app.game.Opening.WORK_JOB)[0].status=="active","Contracts UI accepts ordinary paid recovery at Harth")
 await travel_to(100);await travel_to(84)
 var payments=app.game.s.ledger.filter(func(row):return row.reason=="Contract: Harth farm-road rounds")
 check(payments.size()==1 and app.game.s.jobs.filter(func(j):return j.id==app.game.Opening.WORK_JOB)[0].status=="paid","PC recovery route pays exactly once through normal accounting")
 check(app.game.s.squads.first.members==survivors and app.game.valid_save(app.game.s) and app.game.Items.ownership_error(app.game.s)=="","Recovery preserves surviving identities, owned equipment and valid saves")
 await key(KEY_F5)
 var recovered=state();await key(KEY_F9);app.confirm.get_ok_button().grab_focus();await key(KEY_ENTER)
 check(state()==recovered,"PC quickload preserves completed recovery and payment")
 # A second paid company completes the normal battle with legal engine actions;
 # keyboard outcome resolution must use that real result, not a forced victory.
 var winning=app.Campaign.new(731);winning.autosave_path="user://pc-win-auto.json"
 winning.configure_greywake_opening();winning.command("opening_skip")
 for id in ["mara","oswin","bram"]: winning.command("hire",{"id":"greywake-named-"+id})
 for action in ["opening_confirm","opening_depart","opening_skip","opening_next","opening_next","dockside_start","confirm_deployment"]: winning.command(action)
 app.game=winning;app.selected="";app.tab="sector";app.view_memory={};app.rebuild();await settle()
 var rounds=0;var battle=winning.battle
 while battle.outcome()=="ongoing" and rounds<50:
  for unit in battle.t.units:
   if unit.team=="company" and battle.can_act(unit): battle.ai_unit(unit)
  if battle.outcome()=="ongoing": battle.end_turn()
  rounds+=1
 check(battle.outcome()=="victory","Paid company reaches victory using legal combat actions")
 app.refresh();app.get_viewport().gui_release_focus();var funds_before=winning.s.funds;await key(KEY_ENTER)
 check(winning.battle==null and winning.s.opening_flow.outcome=="victory" and winning.s.funds==funds_before+180,"Enter resolves the actual victory and pays exactly 180 crowns")
 var resolved=state();await key(KEY_ENTER)
 check(state()==resolved and winning.valid_save(winning.s) and winning.Items.ownership_error(winning.s)=="","Repeated confirm cannot pay twice or duplicate equipment")
 var report={"passed":passed,"failed":failures.size(),"failures":failures,"measurements":measurements,"scope":"Desktop native UI events, canonical commands, six paid recruits, real tactical turns, persistence and renderer behaviour; no forced victory."}
 var output=FileAccess.open("res://pc-vertical-slice-results.json",FileAccess.WRITE);output.store_string(JSON.stringify(report,"  "));output.close()
 print("PC_VERTICAL_SLICE: "+JSON.stringify(report));app.queue_free();await settle();quit(0 if failures.is_empty() else 1)
