extends SceneTree
const C=preload("res://sim/campaign.gd")
var passed=0
var failures=[]
func _init() -> void: call_deferred("run")
func check(ok: bool,title: String) -> void:
 if ok: passed+=1
 else: failures.append(title);print("FAIL: "+title)
func same_failure(c,kind: String,p: Dictionary,title: String) -> void:
 var before=JSON.stringify(c.s);check(not c.command(kind,p) and JSON.stringify(c.s)==before,title)
func reload_at(c):
 var path="user://opening-flow-check.json"
 check(c.save_to(path),"Opening stage saves: "+C.Opening.stage(c.s))
 var loaded=C.new();loaded.autosave_path="user://opening-flow-auto.json"
 check(loaded.load_from(path) and loaded.s==c.s,"Opening stage reloads exactly")
 return loaded
func run() -> void:
 var c=C.new();c.autosave_path="user://opening-flow-auto.json"
 check(c.configure_greywake_opening(),"New production opening configures")
 check(C.Opening.stage(c.s)=="EMPLOYER_BRIEFING" and c.s.funds==2400 and c.valid_save(c.s),"Briefing owns no second purse or company")
 same_failure(c,"hire",{"id":"greywake-named-mara"},"Cannot recruit behind the briefing")
 same_failure(c,"advance",{"minutes":60},"Briefing clock frozen")
 for i in range(C.Opening.content().briefing.size()):check(c.command("opening_next"),"Briefing advances without accepting a second contract")
 check(C.Opening.stage(c.s)=="TAVERN_RECRUITMENT","Briefing enters tavern")
 same_failure(c,"opening_confirm",{},"Empty company cannot set sail")
 for i in range(2):check(c.command("recruit_template",{"template":"militia_spearman"}),"Tavern uses canonical recruiting")
 check(c.s.funds==2160,"Exact two paid fees")
 c=reload_at(c)
 check(c.command("opening_confirm") and C.Opening.stage(c.s)=="COMPANY_CONFIRMATION","Company confirmation is persistent stage")
 c=reload_at(c)
 check(c.command("opening_back") and c.command("opening_confirm"),"Confirmation can return without transactions")
 var people=c.s.mercs.duplicate(true)
 check(c.command("opening_depart") and C.Opening.stage(c.s)=="BOAT_CROSSING","Existing embark logic starts presentation crossing")
 check(c.s.mercs.size()==people.size() and c.s.funds==2160 and c.s.squads.first.sector==17,"Boat does not rehire or spend")
 c=reload_at(c)
 same_failure(c,"opening_depart",{},"Departure cannot replay after reload")
 same_failure(c,"embark",{},"Direct embark cannot duplicate initial transaction")
 same_failure(c,"advance",{"minutes":1440},"Cinematic does not advance strategic shipping time")
 check(c.command("opening_skip") and C.Opening.stage(c.s)=="GREYWAKE_ARRIVAL","Skipping crossing preserves required arrival")
 c=reload_at(c)
 check(c.command("opening_next") and C.Opening.stage(c.s)=="DOCKSIDE_CONTRACT","Arrival opens introductory contract alert")
 check(c.command("opening_next") and C.Opening.stage(c.s)=="GREYWAKE_CAMPAIGN","Alert enters campaign")
 check(c.s.time==480 and c.s.shipping.next_arrival_at==4680 and c.valid_save(c.s),"Opening keeps original absolute calendar and valid owned state")
 var fast=C.new();fast.configure_greywake_opening();check(fast.command("opening_skip") and C.Opening.stage(fast.s)=="TAVERN_RECRUITMENT","Skipping dialogue reaches tavern, never campaign")
 var original=C.new();check(not original.s.has("opening_flow") and original.valid_save(original.s),"Original campaign has no opening metadata")
 var corrupt=c.s.duplicate(true);corrupt.erase("opening_flow")
 check(not c.valid_save(corrupt),"Island saves require their opening state")
 corrupt=fast.s.duplicate(true);corrupt.squads.first.sector=18
 check(not fast.valid_save(corrupt),"Pre-voyage company cannot move to island behind the tavern")
 corrupt=fast.s.duplicate(true);corrupt.opening_flow.dialogue_index=100
 check(not fast.valid_save(corrupt),"Corrupt briefing index rejected safely")
 var report={"passed":passed,"failed":failures.size(),"failures":failures}
 var f=FileAccess.open("res://opening-flow-results.json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"  "));f.close()
 print("OPENING_FLOW: "+JSON.stringify(report));quit(0 if failures.is_empty() else 1)
