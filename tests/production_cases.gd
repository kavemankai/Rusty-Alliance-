extends RefCounted
const Campaign=preload("res://sim/campaign.gd")
const Data=preload("res://sim/catalog.gd")
const Items=preload("res://sim/inventory.gd")
const Field=preload("res://tests/exploration_cases.gd")

static func campaign():
 var c=Campaign.new();c.autosave_path="user://production-test-autosave.json"
 return c

static func captives():
 var c=Field.field();c.autosave_path="user://production-test-autosave.json"
 c.command("confirm_deployment")
 for u in c.battle.t.units:
  if u.team=="enemy": u.person.hp=10
 c.command("resolve")
 return c

static func convoy():
 var c=campaign();c.command("accept",{"id":"caravan"})
 c.s.groups=[c.s.groups[0]];c.s.groups[0].sector=49;c.s.sectors[49].owner="bandits"
 c.command("route",{"sector":49});c.command("advance",{"minutes":600});c.command("enter");c.command("confirm_deployment")
 return c

static func run(test) -> void:
 var c=campaign();var owner=c.s.sectors[17].owner
 test.check(c.command("visit") and c.battle.t.peaceful and c.battle.t.phase=="exploration","A peaceful company can enter its sector tactically without an enemy force")
 var b=c.battle;var a=b.unit("mara");var old_funds=c.s.funds;var tools=c.s.squads.first.supplies.tools;var ap=a.ap
 test.check(not c.command("resolve") and c.s.sectors[17].owner==owner,"Peaceful exploration cannot fabricate a capture victory")
 test.check(b.action(a.id,"build",{"x":3,"y":3,"kind":"barricade"}) and b.tile(3,3).cover==35 and c.s.funds==old_funds-20 and c.s.squads.first.supplies.tools==tools-3 and a.ap==ap-8,"Building creates a real fortification and consumes local tools, funds and AP")
 var snapshot=JSON.stringify(c.s)
 test.check(not b.action(a.id,"build",{"x":15,"y":10,"kind":"palisade"}) and JSON.stringify(c.s)==snapshot,"Remote construction rejects before spending resources")
 test.check(c.save_to("user://peaceful-field.json"),"Peaceful visits and built terrain save")
 var loaded=campaign()
 test.check(loaded.load_from("user://peaceful-field.json") and loaded.battle.t.peaceful and loaded.battle.tile(3,3).cover==35,"Built fortifications and peaceful mode survive load")
 test.check(loaded.command("leave") and loaded.battle==null and loaded.s.sectors[17].owner==owner and loaded.s.squads.first.sector==17,"Leaving a peaceful visit preserves territory and strategic location")
 test.check(loaded.command("visit") and loaded.battle.tile(3,3).cover==35,"Constructed terrain persists on a later visit")
 c=campaign();c.command("advance",{"minutes":780});c.command("visit");b=c.battle;a=b.unit("mara");a.person.perception=0;b.refresh_knowledge()
 test.check(b.t.night and not b.visible(a,b.tile(5,3)),"Night reduces actual perception range")
 test.check(b.action(a.id,"build",{"x":3,"y":2,"kind":"torch"}) and b.visible(a,b.tile(5,3)),"A constructed torch changes the actual night visibility calculation")
 c=campaign();c.command("visit");b=c.battle;a=b.unit("mara")
 test.check(c.command("exploration_running") and b.t.exploration.running,"Exploration can run on timed UI pulses")
 test.check(b.action(a.id,"move",{"x":4,"y":3}) and a.x==2 and b.t.exploration.orders.has(a.id),"Running exploration queues rather than instantly executing movement")
 c.command("explore_wait",{"pulses":2})
 test.check(a.x==4 and b.t.exploration.orders.is_empty(),"Running exploration advances its queued movement through actual local pulses")
 c.save_to("user://running-field.json")
 test.check(loaded.load_from("user://running-field.json") and not loaded.battle.t.exploration.running and loaded.battle.unit("mara").x==4,"Loading a running visit pauses safely without undoing progress")
 c=Field.field();c.autosave_path="user://production-test-autosave.json";b=c.battle
 test.check(c.command("entry",{"direction":"south"}) and b.t.active_entry=="south","Authored directional approaches are selectable before combat")
 var placed=true
 for u in b.t.units:
  if u.team=="company": placed=placed and u.deployed and u.y>=12
 test.check(placed and c.command("confirm_deployment"),"The whole formation relocates into a legal selected edge without moving enemies")
 snapshot=JSON.stringify(c.s)
 test.check(not c.command("entry",{"direction":"north"}) and JSON.stringify(c.s)==snapshot,"Approach changes are locked after combat starts")
 c=campaign()
 var room=preload("res://sim/battlefields.gd").create(c.s.sectors[17])
 test.check(room.tiles.any(func(cell):return cell.get("interior",false) and cell.get("roof",false) and cell.kind=="floor"),"Settlement buildings contain actual room and roof data with walkable interiors")
 var training=preload("res://sim/battlefields.gd").create(c.s.sectors[81])
 test.check(training.tiles!=room.tiles,"Training grounds have a distinct facility variant")
 c=campaign();c.command("levy",{"sector":17})
 var levy=c.s.sectors[17].levies[0];var mail={}
 for item in c.s.stash:
  if item.kind=="mail": mail=item;break
 test.check(c.command("transfer",{"from":"stash","to":levy.id,"item":mail.id}) and c.command("equip",{"id":levy.id,"item":mail.id}) and Data.armour(levy)=="mail","A local levy can receive and equip the actual stockpile armour instance")
 test.check(Items.ownership_error(c.s)=="","Levy loadout management retains unique gear ownership")
 c.s.squads.first.sector=18
 snapshot=JSON.stringify(c.s)
 test.check(not c.command("transfer",{"from":"mara","to":levy.id,"item":c.s.mercs.mara.inventory[0].id}) and JSON.stringify(c.s)==snapshot,"Remote company-to-levy handovers are rejected atomically")
 c=captives();var captive=c.s.groups[0].fighters[0];old_funds=c.s.funds
 test.check(c.command("prisoner",{"id":captive.id,"choice":"ransom"}) and c.s.funds==old_funds+50 and captive.released and c.force_strength(c.s.groups[0])==0,"Ransoming a local prisoner pays once and does not reactivate the enemy army")
 snapshot=JSON.stringify(c.s)
 test.check(not c.command("prisoner",{"id":captive.id,"choice":"ransom"}) and JSON.stringify(c.s)==snapshot,"Released or ransomed prisoners cannot pay twice")
 c=captives();captive=c.s.groups[0].fighters[0];var id=captive.id
 test.check(c.command("prisoner",{"id":id,"choice":"recruit"}) and c.s.mercs.has(id) and id in c.s.squads.first.members and c.s.mercs[id].morale==25 and captive not in c.s.groups[0].fighters,"Prisoner enlistment transfers the original profile into paid company employment")
 test.check(c.save_to("user://enlisted-prisoner.json") and loaded.load_from("user://enlisted-prisoner.json") and loaded.s.mercs.has(id) and Items.ownership_error(loaded.s)=="","Enlisted prisoner ownership and employment survive save/load")
 c=captives();captive=c.s.groups[0].fighters[0]
 test.check(c.command("prisoner",{"id":captive.id,"choice":"release"}) and captive.released and c.force_strength(c.s.groups[0])==0,"Merciful release has a persistent non-combat state")
 c=campaign();var road=c.travel_cost(c.s.squads.first,33)
 c.command("transport",{"asset":"horses"});c.command("transport",{"asset":"horses"})
 test.check(c.s.squads.first.transport.horses==2 and c.travel_cost(c.s.squads.first,33)<road,"Owned horses enable faster mounted travel when every member has a mount")
 c.command("transport",{"asset":"carts"});c.command("split",{"id":"oswin"})
 test.check(c.s.squads.first.transport.horses+c.s.squads.squad_oswin.transport.horses==2 and c.s.squads.first.transport.carts+c.s.squads.squad_oswin.transport.carts==1,"Splitting a company conserves whole horses and carts")
 c.command("merge",{"from":"squad_oswin"})
 test.check(c.s.squads.first.transport=={"horses":2,"carts":1},"Merging combines actual owned transport assets without duplication")
 c.s.squads.first.sector=18;snapshot=JSON.stringify(c.s)
 test.check(not c.command("transport",{"asset":"horses"}) and JSON.stringify(c.s)==snapshot,"Transport purchases require a physical market visit")
 c=campaign();var offers=c.s.jobs.size()
 test.check(c.command("post_jobs") and c.s.jobs.size()==offers+2 and c.s.jobs[-1].type=="patrol" and c.s.jobs[-2].type=="escort","A real board request creates route-priced delivery and patrol postings")
 snapshot=JSON.stringify(c.s)
 test.check(not c.command("post_jobs") and JSON.stringify(c.s)==snapshot,"Procedural postings are limited to one request per day")
 c=convoy();b=c.battle
 var job=c.s.jobs[4];var cart=b.unit(job.actors[0].id);var driver=b.unit(job.actors[1].id)
 test.check(cart!=null and driver!=null and cart.role=="cart" and driver.role=="driver","A threatened escort deploys an independently targetable cart and driver")
 test.check(c.save_to("user://protected-convoy.json") and loaded.load_from("user://protected-convoy.json") and loaded.battle.unit(cart.id).person==loaded.s.jobs[4].actors[0],"Convoy actors bind to authoritative contract profiles after reload")
 driver.x=0;driver.y=0;var before_cart=cart.x
 test.check(not b.action(cart.id,"move",{"x":cart.x+1,"y":cart.y}) and cart.x==before_cart,"A cart cannot move without its capable driver nearby")
 driver.x=cart.x;driver.y=cart.y+1
 test.check(b.action(cart.id,"move",{"x":cart.x+1,"y":cart.y}),"A nearby living driver enables paid cart movement")
 var enemy=b.unit(c.s.groups[0].fighters[0].id)
 enemy.x=cart.x+1;enemy.y=cart.y;enemy.person.melee=100;enemy.ap=26;cart.person.hp=1;cart.person.agility=0;cart.ap=0
 b.t.turn="enemy";b.refresh_knowledge();c.s.rng=1
 test.check(b.attack(enemy,cart) and cart.person.hp==0 and job.status=="failed" and job.cargo==0,"An actual enemy hit can destroy the protected cart and fail the delivery before payment")
 c=campaign();var group=c.s.groups[-1]
 c.s.groups=[group]
 var bank=c.s.factions.bandits.resources
 c.Strategy.daily(c)
 test.check(group.fighters.size()==3 and c.s.factions.bandits.resources==bank+60-6-60 and c.s.factions.bandits.history[-1].cost==60,"Faction income/upkeep funds an actual sixty-resource recruit at a staffed owned base")
 test.check(c.save_to("user://faction-budget.json") and loaded.load_from("user://faction-budget.json") and loaded.s.groups[0].fighters.size()==3,"Budgeted reinforcements and their persistent equipment survive saves")
 c=campaign();group=c.s.groups[-1];c.s.groups=[group];c.s.factions.bandits.resources=0
 c.Strategy.daily(c)
 test.check(group.fighters.size()==2,"A faction with insufficient resources cannot create a reinforcement")
 c=campaign();group=c.s.groups[0];group.sector=18;group.objective=36
 c.Strategy.orders(c,group)
 test.check(group.objective==17 and c.s.factions.bandits.intel.has("17"),"A nearby army observes company presence and changes its raid objective")
 c.s.time+=2881;c.s.squads.first.sector=100;group.sector=34;c.Strategy.orders(c,group)
 test.check(not c.s.factions.bandits.intel.has("17"),"Strategic contact intelligence expires instead of tracking remote squads forever")
 c=campaign();var bandits=c.s.groups[0];var nobles=c.s.groups[2]
 bandits.sector=100;nobles.sector=100;c.s.groups=[bandits,nobles]
 c.Strategy.clash(c,bandits)
 test.check(c.force_strength(bandits)==0 and c.force_strength(nobles)==2 and c.s.sectors[100].owner=="nobles","Opposing mobile armies resolve actual persistent casualties and sector control")
 test.check(Items.ownership_error(c.s)=="" and not c.s.sectors[100].battlefield.ground.is_empty(),"Army-clash equipment becomes unique recoverable ground items")
 c=Field.field();b=c.battle;c.command("confirm_deployment")
 var receiver=b.unit(c.s.groups[0].fighters[0].id);var observer=b.unit(c.s.groups[0].fighters[1].id)
 receiver.person.perception=0;receiver.x=16;receiver.y=2
 observer.person.perception=100;observer.x=5;observer.y=2;b.refresh_knowledge()
 test.check(b.known("enemy","mara") and not receiver.memory.has("mara"),"A distant observer does not grant instant personal target knowledge to an isolated ally")
 observer.x=11;b.refresh_knowledge()
 test.check(receiver.memory.has("mara") and receiver.memory.mara.visible,"A nearby observer can relay a currently perceived contact within communication range")
 c=campaign();c.command("visit");b=c.battle;a=b.unit("mara")
 test.check(b.action(a.id,"formation",{"x":4,"y":3,"style":"line"}) and b.unit("mara").x==3 and b.unit("oswin").x==4,"Line formation issues real movement orders for distinct squad destinations")
 a.ap=8;a.person.morale=20
 test.check(b.action(a.id,"rally") and a.ap==4 and a.person.morale>20,"A leader can spend real AP to rally nearby allies")
 snapshot=JSON.stringify(c.s)
 test.check(not b.action(a.id,"rally") and JSON.stringify(c.s)==snapshot,"Rally cannot be spammed again in the same combat round")

 c=campaign();c.command("hire",{"id":"ada"});c.command("hire",{"id":"bram"})
 c.remove_member("ada");c.s.mercs.ada.captured=true;c.s.mercs.ada.captured_sector=34;c.s.mercs.ada.hp=30
 c.s.squads.first.sector=34;c.s.groups=[c.s.groups[0]]
 c.encounter(c.s.squads.first,34);c.command("enter");c.command("confirm_deployment")
 test.check(c.battle.unit("ada")==null,"A captured company member cannot join the rescue battle remotely")
 test.play_battle(c)
 test.check(c.battle.outcome()=="victory" and c.command("resolve") and not c.s.mercs.ada.captured and c.s.mercs.ada.hired and "ada" in c.s.squads.first.members,"An actual local victory rescues the captive profile and reunites it with the surviving company")
 c=campaign();c.command("transport",{"asset":"horses"});c.command("transport",{"asset":"horses"})
 c.s.groups=[];var food=c.s.squads.first.supplies.food;c.daily()
 test.check(c.s.squads.first.supplies.food==food-4,"Owned horses consume their company's actual forage each day")
 c=campaign();c.command("post_jobs");var ordinary=c.s.jobs[7].reward
 c=campaign();c.s.groups[0].sector=33;c.s.sectors[33].known=true;c.command("post_jobs")
 test.check(c.s.jobs[7].risk==1 and c.s.jobs[7].reward==ordinary+75,"A known hostile on the proposed route increases procedural escort pay")
 c=convoy();b=c.battle
 var damaged_cart=b.unit(c.s.jobs[4].actors[0].id);a=b.unit("mara")
 a.x=damaged_cart.x-1;a.y=damaged_cart.y;a.ap=26;damaged_cart.person.hp=50
 tools=c.s.squads.first.supplies.tools
 test.check(b.action(a.id,"repair_cart",{"target":damaged_cart.id}) and damaged_cart.person.hp==64 and a.ap==21 and c.s.squads.first.supplies.tools==tools-1,"A smith can repair an adjacent surviving cart using real AP and local tools")
 test.check(not b.action(a.id,"aid",{"target":damaged_cart.id}),"Medicine cannot be used as a substitute for cart repair tools")

 c=campaign();var patrol=c.s.groups[2]
 c.Strategy.orders(c,patrol)
 patrol.sector=34;c.s.sectors[34].owner="nobles";c.Strategy.orders(c,patrol)
 test.check(patrol.order=="patrol" and patrol.objective==65,"A patrol that finishes its objective returns toward its original base")
 patrol.sector=65;c.Strategy.orders(c,patrol)
 test.check(patrol.objective==34,"A completed return leg begins another actual patrol objective")
