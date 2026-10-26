extends SceneTree
const C=preload("res://sim/campaign.gd")
var passed=0
var failures=[]
func _init() -> void: call_deferred("run")
func check(ok: bool,title: String) -> void:
 if ok: passed+=1
 else: failures.append(title);print("FAIL: "+title)
func fresh(seed_value: int=731,roster: Array=["militia_spearman","militia_spearman"]):
 var c=C.new(seed_value);c.autosave_path="user://dockside-check-auto.json";c.configure_greywake_opening();c.command("opening_skip")
 for id in roster:
  if id.begins_with("militia"):c.command("recruit_template",{"template":id})
  else:c.command("hire",{"id":"greywake-named-"+id})
 c.command("opening_confirm");c.command("opening_depart");c.command("opening_skip");c.command("opening_next");c.command("opening_next")
 return c
func reload_at(c,path: String):
 check(c.save_to(path),"Save actual encounter state")
 var loaded=C.new();loaded.autosave_path="user://dockside-check-auto.json"
 check(loaded.load_from(path) and loaded.s==c.s,"Saved encounter and canonical people restore exactly")
 return loaded
func run() -> void:
 var wins=0;var enemy_baseline=""
 for roster in [["militia_spearman","militia_spearman"],["militia_crossbowman","militia_crossbowman"],["militia_spearman","militia_crossbowman"],["mara","oswin","bram"]]:
  for seed_value in [731,947,1291]:
   var c=fresh(seed_value,roster);var g=c.s.groups[0]
   var profiles=JSON.stringify(g.fighters)
   if enemy_baseline=="":enemy_baseline=profiles
   check(profiles==enemy_baseline,"Enemy values never scale to recruitment spending")
   check(c.command("dockside_start") and c.battle!=null and c.battle.t.phase=="deployment","Legal selected company enters real dockside deployment")
   check(c.battle.t.units.filter(func(u):return u.team=="enemy").size()==2,"Exactly two normal enemy actors")
   check(c.battle.t.tiles.filter(func(tile):return tile.kind=="water").all(func(tile):return tile.block),"Dockside water is genuinely impassable")
   check(c.battle.t.tiles.any(func(tile):return tile.kind=="wood" and not tile.block),"Wooden jetty has legal walking tiles")
   check(c.battle.t.tiles.any(func(tile):return tile.kind=="crate" and tile.cover>0 and tile.block),"Cargo stacks have actual collision and cover")
   check(c.command("confirm_deployment"),"Friendly placement validates normally")
   var b=c.battle;var rounds=0
   while b.outcome()=="ongoing" and rounds<50:
    for u in b.t.units:
     if u.team=="company" and b.can_act(u):b.ai_unit(u)
    if b.outcome()=="ongoing":b.end_turn()
    rounds+=1
   var win=b.outcome()=="victory"
   if win:wins+=1
   check(win,"Normal legal-action driver can win: "+str(roster)+" seed "+str(seed_value))
   var funds=c.s.funds
   check(c.command("resolve"),"Actual outcome resolves")
   check(c.s.funds==funds+(180 if win else 0),"Victory pays once; losses receive no reward")
   check(c.s.opening_flow.outcome==("victory" if win else "defeat") and c.s.opening_flow.stage=="GREYWAKE_CAMPAIGN","Real result returns to campaign")
   check(c.valid_save(c.s) and c.Items.ownership_error(c.s)=="","Battle loot injuries and equipment have valid ownership")
   var before=JSON.stringify(c.s);check(not c.command("resolve") and JSON.stringify(c.s)==before,"Reward cannot be resolved twice")
 check(wins==12,"All prototype company/seed fixtures win without special outcome rules")
 var c=fresh();c=reload_at(c,"user://dockside-before.json")
 check(c.command("dockside_start"),"Introductory battle starts after reload")
 c=reload_at(c,"user://dockside-deployment.json")
 check(c.command("confirm_deployment"),"Loaded formation confirms")
 c=reload_at(c,"user://dockside-active.json")
 var b=c.battle;var u=b.t.units[2]
 check(b.los({"x":4,"y":9},{"x":7,"y":12}),"Water does not become an invisible sight wall")
 check(b.step_cost(u,b.tile(4,9),b.tile(4,10))<0,"Water remains blocked in shared movement rules")
 var funds=c.s.funds;var enemy=c.s.groups[0].fighters.duplicate(true)
 check(c.command("retreat") and c.s.funds==funds and c.s.opening_flow.outcome=="retreat","Withdrawal fails forward with no reward")
 check(c.s.groups[0].fighters==enemy and c.s.sectors[17].owner=="bandits" and not C.Shipping.accessible(c.s),"Withdrawal preserves bandits and occupation blocks port")
 check(C.World.land(c.s.squads.first.sector) and c.s.squads.first.sector!=17,"Withdrawal uses actual safe land exit")
 c=reload_at(c,"user://dockside-withdrawn.json")
 # A one-person survivor earns ordinary paid route work. No free provisions/recruits.
 var lost=c.s.squads.first.members[-1];c.s.mercs[lost].dead=true;c.s.mercs[lost].hp=0;c.remove_member(lost)
 check(c.s.squads.first.members.size()==1 and c.command("route",{"sector":84}) and c.advance(1800),"One surviving fighter can travel to Harth after withdrawal")
 check(c.command("accept",{"id":C.Opening.WORK_JOB}),"Recovery work requires physical capable presence at Harth")
 funds=c.s.funds
 check(c.command("route",{"sector":100}) and c.advance(500),"Worker travels to actual farmland")
 check(c.command("route",{"sector":84}) and c.advance(500),"Worker returns to Harth on actual route")
 check(c.s.jobs[1].status=="paid" and c.s.ledger.filter(func(row):return row.reason=="Contract: Harth farm-road rounds").size()==1,"Paid recovery work completes once using existing contract accounting")
 check(c.valid_save(c.s),"One-person paid recovery survives validation")
 # Actual defeat/capture path, using the same engine with a controlled near-death fixture.
 c=fresh();c.command("dockside_start");c.command("confirm_deployment")
 for actor in c.battle.t.units:
  if actor.team=="company":actor.person.hp=5
 check(c.battle.outcome()=="defeat" and c.command("resolve"),"Defeat uses existing incapacitation and capture rules")
 check(c.s.opening_flow.outcome=="defeat" and c.s.squads.first.members.is_empty() and c.s.mercs.values().filter(func(p):return p.get("captured",false)).size()==2,"Defeat survivors remain captured, never restored for free")
 check(c.valid_save(c.s),"Defeat preserves authoritative injuries equipment and history")
 c=fresh();c.command("dockside_start");c.command("confirm_deployment")
 for actor in c.battle.t.units:
  if actor.team=="company":actor.person.hp=0;actor.person.dead=true
 check(c.command("resolve") and c.s.squads.first.members.is_empty(),"Total company destruction never recreates starting recruits")
 check(c.valid_save(c.s) and c.Items.ownership_error(c.s)=="","Destroyed company equipment remains uniquely owned on battlefield")
 var report={"passed":passed,"failed":failures.size(),"failures":failures,"balanced_driver_wins":wins,"balanced_driver_cases":12}
 var f=FileAccess.open("res://dockside-test-results.json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"  "));f.close();print("DOCKSIDE: "+JSON.stringify(report));quit(0 if failures.is_empty() else 1)
