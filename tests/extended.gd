extends SceneTree
const Campaign=preload("res://sim/campaign.gd")
const Field=preload("res://tests/exploration_cases.gd")
var checks=[]
var failed=0
var campaigns=[]
func _init() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
 checks.append({"name":label,"passed":ok})
 if not ok: failed+=1;print("FAIL: "+label)
func play(c) -> int:
 var rounds=0;var b=c.battle
 while b.outcome()=="ongoing" and rounds<60:
  for u in b.t.units:
   if u.team=="company" and b.can_act(u): b.ai_unit(u)
  if b.outcome()=="ongoing": b.end_turn()
  rounds+=1
 if b.outcome()=="ongoing": c.command("retreat")
 else: c.command("resolve")
 return rounds
func run() -> void:
 var started=Time.get_ticks_msec()
 # Different costs, elevation, obstacles, occupants, stance and movement modes.
 for seed_value in range(12):
  var c=Field.field();c.command("confirm_deployment");var b=c.battle
  b.build_map(18,14)
  var rng=RandomNumberGenerator.new();rng.seed=seed_value+100
  for cell in b.t.tiles:
   cell.cost=rng.randi_range(1,4);cell.elevation=rng.randi_range(0,2);cell.block=rng.randf()<0.13
  var u=b.unit("mara");u.x=1;u.y=1;u.stance=["stand","crouch","prone"][seed_value%3];u.mode=["walk","run","cautious"][int(seed_value/3)%3]
  b.tile(1,1).block=false;b.tile(16,12).block=false
  var reference=b.path_reference(u,16,12);var heap=b.path_heap(u,16,12)
  check(reference.cost==heap.cost,"Heap and reference agree on minimum AP: seed "+str(seed_value))
  var previous=b.tile(u.x,u.y);var paid=0
  for index in heap.path:
   var step=b.step_cost(u,previous,b.t.tiles[index]);check(step>0,"Heap route contains legal paid step");paid+=step;previous=b.t.tiles[index]
  check(heap.cost<0 or paid==heap.cost,"Heap route preview equals execution cost")
  b.t.fog.company={}
  for cell in b.t.tiles:
   if rng.randf()<0.5: b.t.fog.company[str(cell.y*18+cell.x)]=cell.duplicate()
  check(b.path_reference(u,16,12,true).cost==b.path_heap(u,16,12,true).cost,"Charted path solver preserves hidden-terrain rules: "+str(seed_value))
 for seed_value in [731,947,1291,1877,2081,3163]:
  var c=Campaign.new(seed_value);c.autosave_path="user://extended-autosave-"+str(seed_value)+".json"
  c.record(120000,"Extended scenario reserve")
  c.s.squads.first.supplies={"food":20000,"medicine":2000,"tools":2000}
  c.command("hire",{"id":"ada"});c.command("assignment",{"id":"ada","value":"training"})
  var target=c.s.time+45*1440;var turns=0;var battles=0;var last_day=-1;var loops=0
  while c.s.time<target and loops<700:
   loops+=1
   if c.battle!=null:
    c.command("confirm_deployment");turns+=play(c);battles+=1
   elif not c.s.encounter.is_empty():
    if not c.command("enter"): check(false,"Long campaign encounter enters");break
   else:
    c.command("advance",{"minutes":mini(360,target-c.s.time)})
   var day=int(c.s.time/1440)
   if day!=last_day and c.battle==null:
    last_day=day
    check(c.valid_save(c.s),"Long campaign invariants: seed %d day %d" % [seed_value,day])
    if day%5==0:
     var path="user://extended-checkpoint-"+str(seed_value)+".json"
     check(c.save_to(path),"Long campaign checkpoint writes")
     var loaded=Campaign.new(seed_value);loaded.autosave_path=c.autosave_path
     check(loaded.load_from(path) and JSON.stringify(loaded.s)==JSON.stringify(c.s),"Long campaign checkpoint preserves all state")
     # Replay the next interval in two detached instances to catch PRNG/event drift.
     var clone=Campaign.new(seed_value);clone.autosave_path=c.autosave_path+".clone"
     check(clone.load_from(path),"Replay checkpoint loads")
     loaded.command("advance",{"minutes":60});clone.command("advance",{"minutes":60})
     check(JSON.stringify(loaded.s)==JSON.stringify(clone.s),"Checkpoint replay is deterministic")
     c=loaded
  check(c.s.time>=target,"45-day campaign completes: "+str(seed_value))
  campaigns.append({"seed":seed_value,"days":45,"time":c.s.time,"battles":battles,"rounds":turns,"iterations":loops,"funds":c.s.funds,"ledger_rows":c.s.ledger.size(),"groups":c.s.groups.size()})
  print("CAMPAIGN: "+JSON.stringify(campaigns[-1]))
 var report={"engine":Engine.get_version_info().string,"passed":checks.size()-failed,"failed":failed,"elapsed_seconds":(Time.get_ticks_msec()-started)/1000.0,"campaigns":campaigns,"checks":checks}
 var f=FileAccess.open("res://extended-results.json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"  "));f.close()
 print("EXTENDED: %d passed, %d failed" % [checks.size()-failed,failed]);quit(1 if failed else 0)
