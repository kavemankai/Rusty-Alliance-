extends Node
# Read-only Android QA telemetry. Opt-in by creating user://mobile-qa.enabled in a debug build.
# The host drives real Android input; this observer never invokes game commands.
var elapsed=0.0
var frames=[]
var touch_events=[]
var last_frame_usec=0
func _input(event: InputEvent) -> void:
 if event is InputEventScreenTouch or event is InputEventScreenDrag:
  touch_events.append({"type":event.get_class(),"index":event.index,"x":event.position.x,"y":event.position.y,"pressed":event.pressed if event is InputEventScreenTouch else null})
  if touch_events.size()>20: touch_events.pop_front()
func _process(delta: float) -> void:
 var now=Time.get_ticks_usec()
 if last_frame_usec>0: frames.append((now-last_frame_usec)/1000.0)
 last_frame_usec=now
 if frames.size()>300: frames.pop_front()
 elapsed+=delta
 if elapsed<1.0: return
 elapsed=0.0
 var app=get_parent()
 var data={"ticks":Time.get_ticks_msec(),"screen":[DisplayServer.window_get_size().x,DisplayServer.window_get_size().y],"buttons":[],"scrolls":[],"game":null}
 data.safe_area=str(DisplayServer.get_display_safe_area());data.ui_rect=rect(app.ui)
 data.touch_events=touch_events
 collect(app,data)
 if app.game!=null:
  var c=app.game
  var state={"time":c.s.time,"funds":c.s.funds,"rng":c.s.rng,"selected_sector":app.sector,"squad_sector":c.s.squads.get(app.squad,{}).get("sector",-1),"route":c.s.squads.get(app.squad,{}).get("route",[]),"selected":app.selected,"tab":app.tab,"message":app.last_message,"phase":"strategic","hash":JSON.stringify(c.s).sha256_text(),"jobs":c.s.jobs,"mercs":{}}
  for id in c.s.mercs:
   var m=c.s.mercs[id];state.mercs[id]={"hired":m.hired,"hp":m.hp,"weapon":app.Data.weapon(m),"skills":{},"training_skill":m.training_skill,"training":m.training,"experience":m.experience}
   for key in app.Data.Skills.ALL: state.mercs[id].skills[key]=m[key]
  state.scenario=c.s.get("scenario","original")
  if is_instance_valid(app.map_view) and app.map_view.is_inside_tree():
   var map=app.map_view
   state.map={"fingers":map.fingers.size(),"dragged":map.dragged,"zoom":map.zoom,"offset":[map.offset.x,map.offset.y],"rect":rect(map),"sectors":{}}
   for id in ([17,18,34,84,100] if c.World.applies(c.s) else [17,18,34]):
    var local=map.point(id) if c.World.applies(c.s) else map.offset+Vector2(id%16+0.5,int(id/16)+0.5)*32*map.zoom
    var point=map.get_screen_transform()*local
    state.map.sectors[str(id)]=[point.x,point.y]
  if c.battle!=null and is_instance_valid(app.battle_view) and app.battle_view.is_inside_tree():
   state.phase=c.battle.t.phase;state.round=c.battle.t.round;state.turn=c.battle.t.turn;state.units=[]
   var view=app.battle_view
   state.board={"rect":rect(view),"zoom":view.camera.size,"position":[view.camera.position.x,view.camera.position.y,view.camera.position.z]}
   for u in c.battle.t.units:
    if u.team!="company" and not c.battle.known("company",u.id): continue
    var point=view.camera.unproject_position(Vector3(u.x,c.battle.tile(u.x,u.y).elevation*0.5+0.06,u.y))
    point=view.get_screen_transform()*(point*view.size/Vector2(view.viewport.size))
    state.units.append({"id":u.id,"team":u.team,"x":u.x,"y":u.y,"hp":u.person.hp,"ap":u.ap,"screen":[point.x,point.y]})
  data.game=state
 var ordered=frames.duplicate();ordered.sort()
 if not ordered.is_empty(): data.observed_frame_ms={"median":ordered[int(ordered.size()/2)],"p95":ordered[int((ordered.size()-1)*0.95)],"samples":ordered.size()}
 var f=FileAccess.open("user://mobile-qa.json.tmp",FileAccess.WRITE)
 if f!=null:
  f.store_string(JSON.stringify(data));f.close()
  DirAccess.rename_absolute(ProjectSettings.globalize_path("user://mobile-qa.json.tmp"),ProjectSettings.globalize_path("user://mobile-qa.json"))
func rect(control: Control) -> Array:
 var transform=control.get_screen_transform()
 var start=transform*Vector2.ZERO;var end=transform*control.size
 return [start.x,start.y,end.x-start.x,end.y-start.y]
func collect(node: Node,data: Dictionary) -> void:
 if node is Control and not node.is_visible_in_tree(): return
 if node is Button:
  var visible=node.get_global_rect();var parent=node.get_parent()
  while parent!=null:
   if parent is ScrollContainer: visible=visible.intersection(parent.get_global_rect())
   parent=parent.get_parent()
  var screen_rect=rect(node)
  var transform=node.get_viewport().get_screen_transform()
  var clip_start=transform*visible.position;var clip_end=transform*visible.end
  data.buttons.append({"text":node.text,"disabled":node.disabled,"rect":screen_rect,"clip":[clip_start.x,clip_start.y,clip_end.x-clip_start.x,clip_end.y-clip_start.y]})
 if node is ScrollContainer: data.scrolls.append({"rect":rect(node),"vertical":node.scroll_vertical})
 for child in node.get_children(true): collect(child,data)
