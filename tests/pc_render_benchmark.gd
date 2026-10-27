extends SceneTree
const C=preload("res://sim/campaign.gd")
const Before=preload("res://tests/fixtures/pc_battle_view_before.gd")
const Current=preload("res://ui/battle_view.gd")
var passed=0
var failures=[]
func _init() -> void: call_deferred("run")
func check(ok: bool,title: String) -> void:
 if ok: passed+=1
 else: failures.append(title);print("FAIL: "+title)
func actor_ids(view) -> Array:
 var result=[]
 for child in view.geometry.get_children():
  if child.has_meta("actor_id"): result.append(child.get_instance_id())
 return result
func stats(samples: Array) -> Dictionary:
 samples.sort();return {"median_ms":samples[samples.size()/2],"p95_ms":samples[int(samples.size()*.95)]}
func run() -> void:
 var c=C.new();c.autosave_path="user://pc-render-benchmark-auto.json";c.configure_greywake_opening();c.command("opening_skip")
 for repeat in range(6): c.command("recruit_template",{"template":"militia_spearman"})
 for action in ["opening_confirm","opening_depart","opening_skip","opening_next","opening_next","dockside_start","confirm_deployment"]: check(c.command(action),"Benchmark canonical setup: "+action)
 var before=Before.new();before.battle=c.battle;before.size=Vector2(1280,720);before.position=Vector2(-10000,0);root.add_child(before)
 var current=Current.new();current.battle=c.battle;current.size=Vector2(1280,720);current.position=Vector2(-10000,1000);root.add_child(current)
 await process_frame;await process_frame
 # This measures CPU presentation work. Both render targets are disabled to avoid
 # GPU scheduling and window-focus limits contaminating the comparison.
 before.viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED;current.viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED
 var old_ids=actor_ids(before);var new_ids=actor_ids(current);var state=JSON.stringify(c.s)
 var old_samples=[];var new_samples=[]
 for repeat in range(30):
  var id=c.s.squads.first.members[repeat%6];before.selected=id;current.selected=id
  var start=Time.get_ticks_usec();before.redraw();old_samples.append((Time.get_ticks_usec()-start)/1000.0)
  start=Time.get_ticks_usec();current.redraw();new_samples.append((Time.get_ticks_usec()-start)/1000.0)
  await process_frame
 check(actor_ids(before)!=old_ids,"Baseline reconstruction occurs on selection redraw")
 check(actor_ids(current)==new_ids and current.actor_rebuilds==1,"Current renderer keeps actual actors across the same selections")
 check(JSON.stringify(c.s)==state,"Neither renderer changes authoritative campaign, RNG or inventory")
 var old_stats=stats(old_samples);var new_stats=stats(new_samples)
 check(new_stats.median_ms<old_stats.median_ms,"Measured cached selection CPU cost is lower than the previous renderer")
 var report={"passed":passed,"failed":failures.size(),"failures":failures,"baseline_commit":"90b0ce7","samples":30,"cpu":OS.get_processor_name(),"before":old_stats,"current":new_stats,"median_ratio":old_stats.median_ms/maxf(.001,new_stats.median_ms),"limits":"CPU redraw comparison on the same six-person campaign and geometry; GPU targets disabled. This is not a universal FPS or hardware guarantee; deferred node teardown is excluded."}
 var output=FileAccess.open("res://pc-render-benchmark-results.json",FileAccess.WRITE);output.store_string(JSON.stringify(report,"  "));output.close()
 print("PC_RENDER_BENCHMARK: "+JSON.stringify(report));before.queue_free();current.queue_free();await process_frame;await process_frame;quit(0 if failures.is_empty() else 1)
