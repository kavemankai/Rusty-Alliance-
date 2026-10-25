extends SceneTree
const Field=preload("res://tests/exploration_cases.gd")
var report={"engine":Engine.get_version_info().string,"cpu":OS.get_processor_name(),"headless":DisplayServer.get_name()=="headless","maps":[]}
func _init() -> void: call_deferred("run")
func ms(begin: int) -> float: return (Time.get_ticks_usec()-begin)/1000.0
func run() -> void:
 for size in [32,80,160]:
  var c=Field.field();c.command("confirm_deployment");var b=c.battle
  b.build_map(size,size)
  b.t.fog={"company":{},"enemy":{}};b.fog_signature=-1;b.fog_observers={}
  var index=0
  for u in b.t.units:
   u.x=1 if u.team=="company" else size-3;u.y=2+index*2;index+=1
  var row={"size":size,"tiles":size*size}
  var begin=Time.get_ticks_usec();var path=b.path(b.unit("mara"),size-2,size-2)
  row.path_ms=ms(begin);row.path_cost=path.cost;row.steps=path.path.size()
  begin=Time.get_ticks_usec();b.refresh_knowledge();row.visibility_cold_ms=ms(begin)
  begin=Time.get_ticks_usec()
  for repeat in range(3): b.refresh_knowledge()
  row.visibility_cached_ms=ms(begin)/3
  if not report.headless:
   var view=preload("res://ui/battle_view.gd").new();view.battle=b;view.size=Vector2(850,580)
   for cell in b.t.tiles: b.t.fog.company[str(cell.y*size+cell.x)]=cell.duplicate()
   begin=Time.get_ticks_usec();root.add_child(view);row.render_build_ms=ms(begin)
   await process_frame;await process_frame
   var frames=[]
   for frame in range(40):
    begin=Time.get_ticks_usec();await process_frame;frames.append(ms(begin))
   frames.sort();row.frame_median_ms=frames[20];row.frame_p95_ms=frames[37]
   view.selected="oswin";view.preview=path.path
   begin=Time.get_ticks_usec();view.redraw();row.redraw_ms=ms(begin)
   row.scene_nodes=view.geometry.get_child_count()
   view.queue_free();await process_frame
  report.maps.append(row)
 var suffix="baseline" if "--baseline" in OS.get_cmdline_user_args() else "current"
 var f=FileAccess.open("res://profile-"+suffix+".json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"  "));f.close()
 print("PROFILE: "+JSON.stringify(report));quit()
