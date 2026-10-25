extends RefCounted
const Campaign=preload("res://sim/campaign.gd")
const Jobs=preload("res://sim/contracts.gd")
const Defence=preload("res://tests/logistics_defence_cases.gd")

static func job(c,id: String) -> Dictionary:
 for j in c.s.jobs:
  if j.id==id: return j
 return {}

static func quiet():
 var c=Campaign.new()
 c.autosave_path="user://contracts-test-autosave.json"
 c.s.groups=[]
 return c

static func travel(c,index: int) -> bool:
 if not c.command("route",{"sector":index}): return false
 var attempts=0
 while not c.s.squads.first.route.is_empty() and c.s.encounter.is_empty() and attempts<100:
  c.command("advance",{"minutes":60})
  attempts+=1
 return c.s.squads.first.sector==index

static func run(test) -> void:
 var c=quiet()
 test.check(c.s.jobs.size()==7 and Jobs.valid(c.s),"Board contains six validated objective types without changing capture IDs")
 var plain=c.travel_cost(c.s.squads.first,33)
 test.check(c.command("accept",{"id":"caravan"}) and c.travel_cost(c.s.squads.first,33)>plain,"Accepted caravan owns actual freight and adds travel burden")
 test.check(not c.command("accept",{"id":"caravan"}),"Active posting cannot be accepted twice")
 travel(c,33)
 test.check(job(c,"caravan").status=="active" and c.s.sectors[49].supplies.food==0,"Escort neither pays nor teleports freight at an intermediate stop")
 test.check(c.save_to("user://contract-road.json"),"Active escorted freight saves")
 var loaded=Campaign.new()
 loaded.autosave_path=c.autosave_path
 test.check(loaded.load_from("user://contract-road.json") and job(loaded,"caravan").cargo==20 and job(loaded,"caravan").squad=="first","Escort owner, position and freight survive load")
 c=loaded
 var funds=c.s.funds
 test.check(travel(c,49) and job(c,"caravan").status=="paid" and c.s.funds==funds+180 and c.s.sectors[49].supplies.food==20,"Real escorted arrival pays once and delivers exact freight to local depot")
 Jobs.visit(c,c.s.squads.first)
 test.check(c.s.funds==funds+180 and c.s.sectors[49].supplies.food==20,"Repeated arrival callback cannot duplicate payment or cargo")
 test.check(not c.command("repost",{"id":"caravan"}),"Repeat posting respects one day cooldown")
 c.command("advance",{"minutes":1440})
 test.check(c.command("repost",{"id":"caravan"}) and c.s.jobs[-1].id!="caravan" and c.s.jobs[-1].status=="available","Repeat work gets a distinct posting and fresh deadline")
 test.check(not c.command("repost",{"id":"caravan"}) and not c.command("accept",{"id":c.s.jobs[-1].id}),"Duplicate repost and remote caravan pickup are rejected")
 test.check(c.save_to("user://contract-paid.json") and loaded.load_from("user://contract-paid.json") and job(loaded,"caravan").status=="paid","Payment and repeat posting persist together")
 c=quiet()
 c.s.squads.first.sector=33
 test.check(not c.command("accept",{"id":"patrol"}) and not c.command("accept",{"id":"caravan"}),"Road objectives require pickup at origin")
 c.s.squads.first.sector=17
 c.command("accept",{"id":"patrol"})
 travel(c,49) # Path visits 33 before 49.
 test.check(job(c,"patrol").step==2 and job(c,"patrol").status=="active","Patrol counts actual ordered intermediate arrivals")
 travel(c,17)
 test.check(job(c,"patrol").step==2,"Returning before remaining checkpoints cannot finish patrol")
 c.save_to("user://patrol-progress.json")
 loaded=Campaign.new()
 test.check(loaded.load_from("user://patrol-progress.json") and job(loaded,"patrol").step==2,"Patrol checkpoint counter survives save/load")
 c=loaded
 travel(c,81)
 test.check(job(c,"patrol").step==3 and job(c,"patrol").status=="active","Patrol requires the final return leg")
 funds=c.s.funds
 test.check(travel(c,17) and job(c,"patrol").status=="paid" and c.s.funds==funds+220,"Patrol pays only after ordered route and return")
 c=quiet()
 c.command("accept",{"id":"caravan"})
 c.command("dismiss",{"id":"mara"})
 c.command("dismiss",{"id":"oswin"})
 test.check(job(c,"caravan").status=="failed" and job(c,"caravan").cargo==0,"Disbanding assigned escort loses freight and fails immediately")
 c=quiet()
 c.command("accept",{"id":"patrol"})
 c.command("split",{"id":"oswin"})
 c.command("merge",{"from":"first","to":"squad_oswin"})
 test.check(job(c,"patrol").status=="failed","Merging away assigned squad cannot transfer a patrol obligation silently")
 c=quiet()
 c.command("accept",{"id":"caravan"})
 job(c,"caravan").deadline=c.s.time+60
 c.command("advance",{"minutes":60})
 test.check(job(c,"caravan").status=="failed" and job(c,"caravan").finished==540,"Deadline is exclusive and records exact failure time")
 c=Campaign.new()
 c.autosave_path="user://contracts-test-autosave.json"
 c.command("accept",{"id":"hunt"})
 c.command("accept",{"id":"defence"})
 c.s.groups[0].sector=33
 c.s.sectors[33].owner="bandits"
 test.check(travel(c,33) and c.command("enter"),"Elimination follows a persistent target away from its posted sector")
 c.command("confirm_deployment")
 test.play_battle(c)
 Jobs.tick(c)
 test.check(job(c,"hunt").status=="active","Neutralized target remains pending until current battle resolves")
 funds=c.s.funds
 test.check(c.battle.outcome()=="victory" and c.command("resolve") and job(c,"hunt").status=="paid" and c.s.funds==funds+300,"Legal battle away from origin pays elimination")
 test.check(job(c,"defence").status=="failed","An off-site elimination cannot claim settlement defence")
 test.check(not c.command("resolve") and not c.command("accept",{"id":"hunt"}),"Resolved battle and closed target cannot pay again")
 c=Defence.defence(false,3)
 # The fixture already deployed, so a new job must be rejected during contact.
 test.check(not c.command("accept",{"id":"defence"}),"Board cannot be accepted retrospectively during combat")
 c=Campaign.new()
 c.autosave_path="user://contracts-test-autosave.json"
 c.command("accept",{"id":"defence"})
 for i in range(3): c.command("levy",{"sector":17})
 c.s.squads.first.sector=1
 c.s.groups=[c.s.groups[0]]
 c.s.groups[0].sector=18
 c.s.sectors[18].owner="bandits"
 c.faction_tick()
 c.command("enter")
 c.command("confirm_deployment")
 test.play_battle(c)
 funds=c.s.funds
 test.check(c.battle.outcome()=="victory" and c.command("resolve") and job(c,"defence").status=="paid" and c.s.funds==funds+400,"Persistent home levies can fulfil actual settlement defence without remote mercenaries")
 c=Campaign.new()
 c.command("accept",{"id":"defence"})
 c.s.squads.first.sector=1
 c.s.groups=[c.s.groups[0]]
 c.s.groups[0].sector=18
 c.s.sectors[18].owner="bandits"
 c.faction_tick()
 test.check(c.s.sectors[17].owner=="bandits" and job(c,"defence").status=="failed","Undefended settlement loss fails defence through faction simulation")
 c=Campaign.new()
 c.autosave_path="user://contracts-test-autosave.json"
 c.command("hire",{"id":"ada"})
 c.command("hire",{"id":"bram"})
 test.check(c.command("accept",{"id":"camp"}),"Occupied original camp accepts assault contract")
 var camp=Jobs.group(c.s,"briar_guard")
 c.faction_tick()
 test.check(camp.sector==52,"Persistent camp garrison stays at its camp during faction movement")
 c.s.squads.first.sector=51 # Controlled approach fixture, followed by real arrival and combat.
 travel(c,52)
 c.command("enter")
 c.command("confirm_deployment")
 test.play_battle(c)
 funds=c.s.funds
 test.check(c.battle.outcome()=="victory" and c.command("resolve") and job(c,"camp").status=="paid" and c.s.funds==funds+500 and c.s.sectors[52].owner=="company","Legal camp assault neutralizes its actual roster, captures sector and pays")
 c=Campaign.new()
 c.autosave_path="user://contracts-test-autosave.json"
 c.command("accept",{"id":"caravan"})
 c.s.groups[0].sector=49
 c.s.sectors[49].owner="bandits"
 travel(c,49)
 test.check(job(c,"caravan").status=="active" and c.s.sectors[49].supplies.food==0,"Hostile arrival cannot deliver escort before battle")
 c.command("enter")
 c.command("confirm_deployment")
 c.save_to("user://escort-combat.json")
 loaded=Campaign.new()
 loaded.autosave_path=c.autosave_path
 test.check(loaded.load_from("user://escort-combat.json") and job(loaded,"caravan").cargo==20 and loaded.battle!=null,"Active caravan contact survives tactical save/load")
 c=loaded
 funds=c.s.funds
 test.check(c.command("retreat") and job(c,"caravan").status=="failed" and c.s.funds==funds and c.s.sectors[49].supplies.food==0,"Real withdrawal abandons caravan with no payout or delivered goods")
 c=Campaign.new()
 c.autosave_path="user://contracts-test-autosave.json"
 c.command("accept",{"id":"caravan"})
 c.s.groups[0].sector=49
 c.s.sectors[49].owner="bandits"
 travel(c,49)
 c.command("enter")
 c.command("confirm_deployment")
 test.play_battle(c)
 funds=c.s.funds
 test.check(c.battle.outcome()=="victory" and c.command("resolve") and job(c,"caravan").status=="paid" and c.s.funds==funds+180 and c.s.sectors[49].supplies.food==20,"Winning the arrival ambush delivers surviving caravan through battle hook")
 c=Campaign.new()
 c.autosave_path="user://contracts-test-autosave.json"
 c.command("accept",{"id":"caravan"})
 c.s.groups[0].sector=49
 c.s.sectors[49].owner="bandits"
 travel(c,49)
 c.command("enter")
 c.command("confirm_deployment")
 # Incapacitated company is a defeat edge fixture, never a success injection.
 for u in c.battle.t.units:
  if u.team=="company": u.person.hp=10
 funds=c.s.funds
 var abandoned_pack=c.s.squads.first.supplies.food
 test.check(c.battle.outcome()=="defeat" and c.command("resolve") and job(c,"caravan").status=="failed" and job(c,"caravan").cargo==0 and c.s.funds==funds and c.s.sectors[49].supplies.food==abandoned_pack,"Defeat seizes caravan, leaves only actual company pack and pays no reward")
 c=quiet()
 c.command("accept",{"id":"patrol"})
 job(c,"patrol").deadline=c.s.time+300
 c.command("advance",{"minutes":300})
 test.check(job(c,"patrol").status=="failed" and job(c,"patrol").step==0,"Missed patrol deadline fails without fake progress")
 c=Campaign.new()
 c.s.sectors[17].owner="bandits"
 test.check(not c.command("accept",{"id":"defence"}),"Lost settlement cannot sell a defence contract")
 for m in c.s.groups[0].fighters: m.hp=0;m.dead=true
 test.check(not c.command("accept",{"id":"hunt"}),"Already neutralized force cannot sell elimination work")
 c=quiet()
 var bad=c.s.duplicate(true)
 bad.jobs[3].cargo=21
 test.check(not c.valid_save(bad),"Malformed freight ownership is rejected before save")
 bad=c.s.duplicate(true)
 bad.jobs[5].waypoints=[999]
 test.check(not c.valid_save(bad),"Out-of-map contract checkpoint is rejected")
 bad=c.s.duplicate(true)
 bad.jobs[1].id=bad.jobs[0].id
 test.check(not c.valid_save(bad),"Duplicate posting identifiers are rejected")
 c=Campaign.new()
 var legacy=c.s.jobs[0].duplicate(true)
 for key in ["squad","step","target","origin","waypoints","reason","finished","accepted","cargo"]: legacy.erase(key)
 c.s.jobs=[legacy]
 test.check(c.save_to("user://old-capture-board.json") and loaded.load_from("user://old-capture-board.json") and loaded.s.jobs.size()==1 and job(loaded,"redbank").step==0,"Previous schema-3 capture boards load without inventing new jobs or armies")
