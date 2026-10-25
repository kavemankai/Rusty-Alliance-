extends SceneTree
const Campaign=preload("res://sim/campaign.gd")
const Data=preload("res://sim/catalog.gd")
const Continuity=preload("res://tests/continuity_cases.gd")
const Logistics=preload("res://tests/logistics_defence_cases.gd")
var checks=[]
var failed=0

func enemy(b):
 for u in b.t.units:
  if u.team=="enemy": return u
 return null

func loadout(p: Dictionary,slot: String,kind: String) -> void:
 var entry=Data.equipped(p,slot)
 if entry.is_empty():
  entry=Data.item(p.id+":fixture_"+slot,kind)
  p.inventory.append(entry)
  p.equipment[slot]=entry.id
 else: entry.kind=kind

func count_kind(entries: Array,kind: String) -> int:
 var count=0
 for entry in entries:
  if entry.kind==kind: count+=1
 return count

func check(condition: bool,name: String) -> void:
 checks.append({"name":name,"passed":condition})
 if not condition:
  failed+=1
  print("FAIL: "+name)

func fixture(seed_value: int=731):
 var c=Campaign.new(seed_value)
 c.autosave_path="user://test-autosave.json"
 c.command("accept",{"id":"redbank"})
 c.command("route",{"sector":34})
 c.command("advance",{"minutes":600})
 c.command("enter")
 c.command("confirm_deployment")
 return c

func _init() -> void:
 call_deferred("run")

func run() -> void:
 var c=Campaign.new()
 check(c.s.sectors.size()==256,"Strategic grid contains 256 original sectors")
 check(c.command("hire",{"id":"ada"}) and c.s.funds==1100 and "ada" in c.s.squads.first.members,"Hiring charges fee and adds persistent member")
 check(not c.command("hire",{"id":"ada"}) and c.s.funds==1100,"Duplicate hiring rejected without charge")
 c.s.funds=0
 check(not c.command("buy",{"item":"plate"}) and count_kind(c.s.stash,"plate")==0,"Unaffordable purchases rejected")
 c.s.funds=1000
 check(c.command("buy",{"item":"mace"}) and c.s.funds==920,"Market purchases charge original prices")
 check(c.command("equip",{"id":"mara","item":"mace"}) and Data.weapon(c.s.mercs.mara)=="mace" and count_kind(c.s.stash,"mace")==0,"Equipping transfers stash ownership")
 check(c.command("split",{"id":"ada"}) and c.s.squads.squad_ada.members==["ada"],"Squad split preserves identity")
 check(c.command("merge",{"from":"squad_ada"}) and c.s.squads.first.members.size()==3,"Co located squad merge")
 var route=c.strategic_path(17,34,c.s.squads.first)
 check(route.size()==2,"Weighted strategic route reaches adjacent diagonal sector in two legs")
 var old=c.s.time
 c.command("route",{"sector":34})
 check(c.s.squads.first.due>old,"Travel schedules actual future arrival")
 c.command("advance",{"minutes":600})
 check(not c.s.encounter.is_empty() and c.s.squads.first.sector==34 and c.s.time<old+600,"Hostile arrival interrupts large time advance")
 check(c.s.squads.first.supplies.food<60,"Travel consumes food through clock")
 c.command("enter")
 c.command("confirm_deployment")
 check(c.battle!=null and Data.weapon(c.battle.unit("mara").person)=="mace","Tactical deployment uses campaign equipment")
 var b=c.battle
 var a=b.unit("mara")
 var base=Data.ap(a.person)
 a.person.fatigue=80
 check(Data.ap(a.person)<base,"Fatigue reduces AP generation")
 a.person.fatigue=0
 a.person.hp=35
 check(Data.ap(a.person)<base,"Wounds reduce AP generation")
 a.person.hp=75
 a.ap=26
 var p=b.path(a,4,3)
 check(p.cost==4 and p.path.size()==2,"Movement preview uses exact orthogonal terrain AP")
 check(b.move(a,4,3) and a.ap==22,"Movement execution spends preview AP")
 check(not b.move(a,7,3),"Wall destination rejected")
 check(not b.move(a,11,13),"Movement beyond AP budget rejected")
 var prior=a.ap
 check(b.action(a.id,"stance",{"value":"crouch"}) and a.ap==prior-2,"Stance action costs AP")
 check(b.path(a,5,3).cost==3,"Crouched movement cost affects preview")
 a.stance="stand"
 a.x=6
 a.y=6
 a.ap=26
 check(not b.move(a,7,6),"Closed door blocks movement")
 check(b.action(a.id,"door",{"x":7,"y":6}) and not b.tile(7,6).block,"Door interaction changes logical obstacle")
 check(b.move(a,7,6),"Opened door supports pathfinding")
 check(not b.action(a.id,"door",{"x":7,"y":6}),"Door cannot close on occupied tile")
 var e=enemy(b)
 a.x=6
 a.y=3
 e.x=8
 e.y=3
 check(not b.los(a,e),"Wall blocks line of sight")
 a.y=4
 e.y=4
 check(b.los(a,e),"Window transmits visibility")
 a.x=6
 a.y=6
 e.x=8
 e.y=6
 loadout(a.person,"weapon","spear")
 b.refresh_knowledge()
 check(b.distance(a,e)==2 and b.known("company",e.id),"Spear reach and knowledge fixture valid")
 check(b.attack(a,e),"Spear attacks at two tile reach")
 loadout(a.person,"weapon","sword")
 check(not b.attack(a,e),"Sword cannot attack at spear reach")
 a.x=9
 a.y=3
 e.x=10
 e.y=3
 e.facing=0
 var front=b.hit_chance(a,e)
 e.facing=4
 check(front>b.hit_chance(a,e),"Rear attack increases chance")
 loadout(a.person,"weapon","bow")
 a.person.loaded=true
 for entry in a.person.inventory:
  if entry.kind=="ammo": entry.quantity=8
 a.ap=26
 e.x=12
 e.y=3
 b.refresh_knowledge()
 check(b.hit_chance(a,e,3)>b.hit_chance(a,e,0),"Aim changes displayed resolution probability")
 check(b.attack(a,e,1) and Data.ammo(a.person)==7 and not a.person.loaded,"Ranged attack consumes ammunition and loaded state")
 check(not b.attack(a,e),"Unloaded ranged shot rejected")
 check(b.action(a.id,"reload") and a.person.loaded,"Bow reload consumes AP")
 loadout(a.person,"weapon","crossbow")
 a.person.loaded=false
 a.ap=6
 check(not b.action(a.id,"reload"),"Crossbow reload requires seven AP")
 a.ap=10
 check(b.action(a.id,"reload") and a.ap==3,"Crossbow reload differs from bow")
 a.ap=20
 a.person.bleeding=3
 var medicine=c.s.squads.first.supplies.medicine
 check(b.action(a.id,"aid") and a.person.bleeding==0 and c.s.squads.first.supplies.medicine==medicine-1,"First aid consumes real medical stock and stops bleeding")
 # Defence and mitigation fixtures over a repeatable seed set.
 var blocked=0
 var naked_damage=0
 var plate_damage=0
 for seed_value in range(1,61):
  for armour in ["clothing","plate"]:
   var trial=fixture(seed_value)
   var tb=trial.battle
   var ta=tb.unit("mara")
   var td=enemy(tb)
   ta.x=10;ta.y=2;td.x=11;td.y=2
   ta.ap=26;ta.person.melee=100;loadout(ta.person,"weapon","sword")
   td.person.hp=100;td.person.max_hp=100;loadout(td.person,"body",armour)
   td.person.equipment.erase("shield");td.ap=0
   tb.refresh_knowledge()
   tb.attack(ta,td)
   if armour=="clothing": naked_damage+=100-td.person.hp
   else: plate_damage+=100-td.person.hp
   if armour=="clothing":
    td.person.hp=100;loadout(td.person,"shield","shield");td.ap=26;td.facing=4;ta.ap=26
    tb.attack(ta,td)
    if td.ap==24: blocked+=1
 check(blocked>0,"Shield/parry/dodge responses consume defender AP across deterministic seeds")
 check(plate_damage<naked_damage,"Plate mitigates total cutting damage over identical seeds")
 # AI only sees legitimate perceptions; repeated turns obey AP bounds.
 c=fixture()
 b=c.battle
 for i in range(4):
  if b.outcome()=="ongoing": b.end_turn()
 var legal=true
 for u in b.t.units:
  legal=legal and u.ap>=0 and not b.tile(u.x,u.y).block
 check(legal and b.t.round>1,"AI turns progress with legal AP and occupancy")
 check(not b.t.ai.is_empty(),"AI exposes decision reasons")
 # Save while a tactical encounter is active, including RNG state.
 c.s.mercs.mara.hp=53
 check(c.save_to("user://test-campaign.json"),"Atomic tactical save succeeds")
 var loaded=Campaign.new()
 check(loaded.load_from("user://test-campaign.json"),"Load tactical campaign succeeds")
 check(loaded.s.rng==c.s.rng and loaded.s.time==c.s.time and loaded.s.mercs.mara.hp==53,"Save preserves RNG clock and wounds")
 loaded.battle.unit("mara").person.hp=39
 check(loaded.s.mercs.mara.hp==39,"Loaded tactical units rebind to authoritative mercenary state")
 check(c.roll(1000)==loaded.roll(1000),"Save resumes deterministic random stream")
 # Equivalent time partitions must produce identical events and accounting.
 var one=Campaign.new()
 var many=Campaign.new()
 one.command("advance",{"minutes":720})
 for i in range(12): many.command("advance",{"minutes":60})
 check(JSON.stringify(one.s)==JSON.stringify(many.s),"Batched world time equals hourly steps")
 c=Campaign.new()
 var money=c.s.funds
 c.s.mercs.mara.hp=50
 c.s.mercs.mara.bleeding=2
 c.command("assignment",{"id":"mara","value":"medical"})
 c.command("assignment",{"id":"oswin","value":"training"})
 c.command("advance",{"minutes":960})
 check(c.s.funds==money-40,"Midnight wages charged exactly once")
 check(c.s.mercs.mara.hp>50 and c.s.mercs.mara.bleeding==0,"Strategic treatment heals persistent wounds")
 check(c.s.mercs.oswin.melee>58,"Time based training increases skill")
 Data.equipped(c.s.mercs.mara,"weapon").condition=30
 c.command("assignment",{"id":"mara","value":"repair"})
 c.command("advance",{"minutes":60})
 check(Data.condition(c.s.mercs.mara)>30 and c.s.squads.first.supplies.tools<12,"Repair consumes tools and restores condition")
 # No armies are created during faction actions.
 var groups=c.s.groups.size()
 var location=c.s.groups[0].sector
 c.faction_tick()
 check(c.s.groups.size()==groups and c.s.groups[0].sector!=location,"Faction movement uses existing persistent groups")
 c.s.groups=[]
 c.s.sectors[34].owner="company"
 c.s.sectors[36].owner="company"
 c.s.sectors[34].supplies.food=0
 money=c.s.funds
 c.daily()
 check(c.s.sectors[34].supplies.food>0 and c.s.funds>money,"Owned farms and mines produce meaningful local resources")
 c=Campaign.new()
 c.s.groups=[]
 c.s.mercs.mara.expires=c.s.time+60
 c.command("advance",{"minutes":120})
 check(not c.s.mercs.mara.hired and not "mara" in c.s.squads.first.members,"Employment expiration removes squad member")
 c.s.jobs[0].status="active"
 c.s.jobs[0].deadline=c.s.time+60
 c.command("advance",{"minutes":120})
 check(c.s.jobs[0].status=="failed","Contract deadline can fail through world time")
 # Real command-driven battle loop, no forced outcomes or injected victories.
 var integrated=Campaign.new(731)
 integrated.autosave_path="user://test-autosave.json"
 integrated.command("hire",{"id":"ada"})
 integrated.command("accept",{"id":"redbank"})
 integrated.command("route",{"sector":34})
 integrated.command("advance",{"minutes":600})
 integrated.command("enter")
 integrated.command("confirm_deployment")
 var rounds=play_battle(integrated)
 check(integrated.battle.outcome()=="victory","Contract scenario wins through legal movement and attack commands")
 var funds=integrated.s.funds
 check(integrated.command("resolve") and integrated.s.jobs[0].status=="paid" and integrated.s.funds==funds+450,"Real victory pays accepted contract exactly once")
 check(integrated.s.sectors[34].owner=="company" and integrated.battle==null,"Battle result captures persistent strategic sector")
 check(not integrated.command("resolve") and integrated.s.funds==funds+450,"Reward cannot be duplicated")
 integrated.command("save",{"path":"user://integration.json"})
 check(loaded.load_from("user://integration.json") and loaded.s.jobs[0].status=="paid" and loaded.s.sectors[34].owner=="company","Completed contract and territory survive reload")
 integrated.command("accept",{"id":"iron"})
 integrated.command("route",{"sector":17})
 integrated.command("advance",{"minutes":300})
 for id in ["bram","elin","tom"]: integrated.command("hire",{"id":id})
 integrated.command("buy",{"item":"food"})
 integrated.command("buy",{"item":"medicine"})
 for m in integrated.s.mercs.values():
  if m.hired: integrated.command("assignment",{"id":m.id,"value":"medical"})
 integrated.command("advance",{"minutes":180})
 integrated.command("route",{"sector":36})
 integrated.command("advance",{"minutes":300})
 integrated.command("enter")
 integrated.command("confirm_deployment")
 if integrated.battle!=null:
  play_battle(integrated)
  var victory=integrated.battle.outcome()=="victory"
  if victory: integrated.command("resolve")
  check(victory and integrated.s.jobs[1].status=="paid","Persistent campaign completes second distinct contract battle")
 else: check(false,"Persistent campaign completes second distinct contract battle")
 # Logistics and extended event accounting with encounters excluded by fixture.
 var long_run=Campaign.new()
 long_run.s.groups=[]
 long_run.s.squads.first.members=[]
 for m in long_run.s.mercs.values(): m.hired=false
 var initial_time=long_run.s.time
 long_run.command("advance",{"minutes":43200})
 check(long_run.s.time==initial_time+43200,"Extended simulation advances thirty full days")
 var wage_entries=0
 for entry in long_run.s.ledger:
  if entry.reason=="Daily wages and levy upkeep": wage_entries+=1
 check(wage_entries==30,"Extended simulation processes every midnight exactly once")
 check(long_run.s.events.size()==1 and long_run.s.events[0].kind=="hour","Expired events drain without duplicate recurring events")
 c=Campaign.new()
 c.s.groups=[]
 c.s.squads.first.supplies.food=0
 var morale=c.s.mercs.mara.morale
 c.command("advance",{"minutes":60})
 check(c.s.mercs.mara.morale==morale-5 and c.s.mercs.mara.fatigue>0,"Supply shortage penalizes morale and fatigue")
 c=Campaign.new()
 check(c.command("levy",{"sector":17}) and c.Garrison.strength(c.s.sectors[17])==1 and c.s.funds==1120,"Levy recruitment charges funds and persists in sector")
 c.command("assignment",{"id":"mara","value":"garrison"})
 c.command("assignment",{"id":"oswin","value":"scout"})
 c.command("advance",{"minutes":60})
 check(c.s.sectors[17].training>0,"Leadership advances local levy training")
 check(c.s.sectors[0].known,"Scouting reveals sectors through assignment time")
 var expires=c.s.mercs.mara.expires
 check(c.command("renew",{"id":"mara"}) and c.s.mercs.mara.expires==expires+10080,"Renewal extends actual employment contract")
 check(c.command("unequip_shield",{"id":"mara"}) and not Data.shield(c.s.mercs.mara) and count_kind(c.s.mercs.mara.inventory,"shield")==1,"Removing shield keeps item in backpack")
 c.s.sectors[17].order=60
 c.command("assignment",{"id":"mara","value":"guard"})
 c.command("advance",{"minutes":60})
 check(c.s.sectors[17].order==61,"Guard assignment increases owned settlement order")
 # Save recovery keeps a valid previous generation after malformed current write.
 c.save_to("user://recovery-test.json")
 c.save_to("user://recovery-test.json")
 var broken=FileAccess.open("user://recovery-test.json",FileAccess.WRITE)
 broken.store_string("interrupted JSON")
 broken.close()
 check(loaded.load_from("user://recovery-test.json") and loaded.s.funds==c.s.funds,"Corrupt current save recovers valid backup")
 check(not loaded.load_from("user://does-not-exist.json"),"Missing save rejected without replacing active campaign")
 var restored=Campaign.new()
 c.save_to("user://roundtrip.json")
 restored.load_from("user://roundtrip.json")
 check(JSON.stringify(restored.s)==JSON.stringify(c.s),"Full strategic save roundtrip preserves exact canonical state")
 var invalid=c.s.duplicate(true)
 invalid.mercs.mara.erase("equipment")
 check(not c.valid_save(invalid),"Structurally incomplete character save rejected")
 invalid=c.s.duplicate(true)
 invalid.version=99
 check(not c.valid_save(invalid),"Unsupported save schema rejected")
 c=fixture()
 b=c.battle
 a=b.unit("mara")
 a.x=6;a.y=2;a.ap=26
 check(b.path(a,8,3).cost>4,"Diagonal path cannot cut through a wall corner")
 a.x=9;a.y=9
 check(b.path(a,10,9).cost==5,"Climbing onto hill pays terrain plus elevation cost")
 e=enemy(b)
 a.x=4;a.y=3;loadout(a.person,"weapon","bow")
 e.x=5;e.y=3
 var with_cover=b.hit_chance(a,e)
 b.tile(5,3).cover=0
 check(b.hit_chance(a,e)>with_cover,"Logical barricade cover modifies ranged accuracy")
 a.person.morale=10
 var low_ap=Data.ap(a.person)
 a.person.morale=70
 check(Data.ap(a.person)>low_ap,"Broken morale reduces tactical AP")
 a.person.bleeding=2
 var hp=a.person.hp
 b.start_turn("company")
 check(a.person.hp==hp-2,"Bleeding ticks at own team turn boundary")
 var preview_matches=true
 for seed_value in range(1,21):
  var trial=fixture(seed_value)
  var tb=trial.battle
  var ta=tb.unit("mara")
  var td=enemy(tb)
  ta.x=10;ta.y=2;td.x=11;td.y=2
  ta.ap=26;ta.person.fatigue=9;td.ap=0
  td.person.hp=100;td.person.max_hp=100;loadout(td.person,"body","clothing")
  tb.refresh_knowledge()
  var chance=tb.hit_chance(ta,td)
  var expected_roll=(seed_value*48271)%2147483647%100
  tb.attack(ta,td)
  preview_matches=preview_matches and ((td.person.hp<100)==(expected_roll<chance))
 check(preview_matches,"Displayed hit percentage matches first RNG contact roll over twenty seeds")
 c=Campaign.new()
 c.s.groups=[{"id":"fixture_raiders","faction":"bandits","sector":33,"strength":1,"objective":17}]
 c.s.squads.first.sector=18
 c.s.sectors[33].owner="bandits"
 for i in range(3): c.command("levy",{"sector":17})
 c.faction_tick()
 c.command("enter")
 c.command("confirm_deployment")
 play_battle(c)
 c.command("resolve")
 check(c.s.sectors[17].owner=="company" and c.force_strength(c.s.groups[0])==0,"Persistent levies defeat a weaker force through tactical combat")
 c=Campaign.new()
 c.s.groups=[]
 c.s.funds=0
 c.command("advance",{"minutes":960})
 check(c.s.funds==-40 and c.s.mercs.mara.morale<70,"Wage arrears remain accounted and penalize morale")
 c=fixture()
 b=c.battle
 a=b.unit("mara")
 a.person.hp=0
 c.command("retreat")
 check(c.s.mercs.mara.dead and not "mara" in c.s.squads.first.members,"Tactical death persists and removes squad membership on resolution")
 # Large logical battlefield: no scene nodes are allocated by simulation.
 c=fixture()
 c.battle.build_map(160,160)
 check(c.battle.t.tiles.size()==25600,"160 by 160 tactical grid supported as lightweight data")
 Continuity.run(self)
 Logistics.run(self)
 preload("res://tests/contracts_cases.gd").run(self)
 preload("res://tests/deployment_cases.gd").run(self)
 var results={"checks":checks,"passed":checks.size()-failed,"failed":failed,"contract_rounds":rounds,"engine":Engine.get_version_info().string}
 var f=FileAccess.open("res://test-results.json",FileAccess.WRITE)
 f.store_string(JSON.stringify(results,"  "))
 f.close()
 print("RESULT: %d passed, %d failed; campaign battle %d rounds" % [checks.size()-failed,failed,rounds])
 quit(1 if failed else 0)

func play_battle(c) -> int:
 var b=c.battle
 var round_count=0
 while b.outcome()=="ongoing" and round_count<50:
  for u in b.t.units:
   if u.team!="company" or not b.can_act(u): continue
   # Reuse legal AI decisions as a test driver; player UI calls the same commands.
   b.ai_unit(u)
  if b.outcome()=="ongoing": b.end_turn()
  round_count+=1
 return round_count
