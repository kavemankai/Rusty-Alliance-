extends SceneTree
const C=preload("res://sim/campaign.gd")
var passed=0
var failures=[]
func _init() -> void: call_deferred("run")
func check(ok: bool,title: String) -> void:
 if ok: passed+=1
 else: failures.append(title);print("FAIL: "+title)
func run() -> void:
 var c=C.new();c.autosave_path="user://island-test-auto.json";c.configure_greywake_opening()
 c.command("opening_skip")
 for i in range(2):c.command("recruit_template",{"template":"militia_spearman"})
 c.command("opening_confirm");c.command("opening_depart");c.command("opening_skip");c.command("opening_next");c.command("opening_next")
 check(c.s.sectors.size()==256 and C.World.content().mask.size()==10,"Island retains compatible backing and authored 10x10 region")
 var count=0
 for id in range(256):
  var land=C.World.land(id)
  if land: count+=1
  for n in c.neighbors(id):check(C.World.land(n),"No company/army edge into sea from "+str(id))
  var route=c.strategic_path(17,id,c.s.squads.first)
  if not land: check(route.is_empty(),"Water/off-island route blocked: "+str(id))
  elif id!=17: check(not route.is_empty() and route.all(func(n):return C.World.land(n)),"Authored land is connected: "+str(id))
 check(count==62,"Exactly 62 playable land sectors")
 for location in C.World.content().locations:check(C.World.land(int(location.sector)) and c.s.sectors[int(location.sector)].name==location.name,"Location references real land: "+location.id)
 check(c.s.squads.first.sector==17 and c.s.sectors[17].name=="Dock Town","Dock Town is authored starting port")
 var before=JSON.stringify(c.s)
 check(not c.command("route",{"sector":0}) and JSON.stringify(c.s)==before,"Failed sea route spends no time or state")
 check(c.command("route",{"sector":84}) and c.advance(1000) and c.s.squads.first.sector==84,"Actual overland travel reaches Harth")
 check(c.save_to("user://island-route-check.json"),"Island route and sectors save")
 var loaded=C.new();check(loaded.load_from("user://island-route-check.json") and loaded.s==c.s,"Island persistent geography loads exactly")
 var corrupt=c.s.duplicate(true);corrupt.squads.first.sector=0
 check(not c.valid_save(corrupt),"Saved company cannot occupy sea")
 corrupt=c.s.duplicate(true);corrupt.sectors[0].greywake_land=true
 check(not c.valid_save(corrupt),"Forged traversable sea flag rejected")
 var old=C.new();old.configure_fall_of_greywake();old.command("recruit_template",{"template":"militia_spearman"})
 var paid=old.s.funds;var people=old.s.mercs.duplicate(true);var ships=old.s.shipping.duplicate(true)
 check(old.command("upgrade_greywake") and old.s.funds==paid and old.s.mercs==people and old.s.shipping==ships,"Explicit safe staging upgrade preserves fees people equipment and calendar")
 check(C.Opening.stage(old.s)=="TAVERN_RECRUITMENT" and old.s.opening_flow.migrated_staging and old.valid_save(old.s),"Upgraded selection resumes in tavern without replaying accepted contract")
 old=C.new();old.configure_fall_of_greywake();old.s.sectors[17].battlefield=C.Layouts.create(old.s.sectors[17]);before=JSON.stringify(old.s)
 check(not old.command("upgrade_greywake") and JSON.stringify(old.s)==before,"Unsafe visited staging geography is preserved without mutation")
 var original=C.new();check(original.neighbors(0)==[1,16] and original.s.sectors[17].name=="Ashford market" and not original.s.sectors[0].has("greywake_land"),"Original 16x16 geography unaffected")
 var report={"passed":passed,"failed":failures.size(),"failures":failures}
 var f=FileAccess.open("res://island-test-results.json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"  "));f.close();print("ISLAND: "+JSON.stringify(report));quit(0 if failures.is_empty() else 1)
