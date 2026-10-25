extends RefCounted
const Campaign=preload("res://sim/campaign.gd")
const Exploration=preload("res://tests/exploration_cases.gd")

static func field():
 var c=Exploration.field()
 c.autosave_path="user://visibility-ai-test-autosave.json"
 c.command("confirm_deployment")
 return c

static func hidden_memory(y: int=2):
 var c=field();var b=c.battle
 b.unit("mara").y=y
 var enemy=b.unit(c.s.groups[0].fighters[0].id)
 enemy.ap=4
 b.t.turn="enemy"
 b.t.knowledge.enemy.mara={"x":12,"y":2,"round":b.t.round,"visible":false}
 enemy.memory={"mara":b.t.knowledge.enemy.mara.duplicate()}
 b.refresh_knowledge()
 return c

static func run(test) -> void:
 var c=field();var b=c.battle
 test.check(b.Visibility.level(b,16,2)==0 and b.Visibility.cell(b,16,2).kind=="unknown","Unexplored hostile-side terrain has no exposed live terrain properties")
 test.check(b.Visibility.level(b,0,2)==2 and b.Visibility.level(b,16,2,"enemy")==2,"Each team sees its own local terrain independently")
 var door=b.tile(2,2)
 door.merge({"door":true,"open":true,"block":false,"kind":"door"},true)
 b.refresh_knowledge()
 test.check(b.Visibility.cell(b,2,2).open and b.Visibility.level(b,2,2)==2,"Visible door state enters persistent terrain memory")
 for u in b.t.units:
  if u.team=="company": u.y=11
 b.refresh_knowledge()
 door.open=false;door.block=true
 b.refresh_knowledge()
 test.check(b.Visibility.level(b,2,2)==1 and b.Visibility.cell(b,2,2).open and not b.Visibility.cell(b,2,2).block,"An unseen door change does not overwrite remembered terrain")
 test.check(c.save_to("user://fog-memory.json"),"Remembered terrain distinct from current world saves")
 var loaded=Campaign.new();loaded.autosave_path=c.autosave_path
 test.check(loaded.load_from("user://fog-memory.json") and loaded.battle.Visibility.cell(loaded.battle,2,2).open and loaded.battle.tile(2,2).block,"Hidden current state and remembered snapshot remain distinct after reload")
 c=loaded;b=c.battle
 b.unit("mara").y=2;b.refresh_knowledge()
 test.check(b.Visibility.level(b,2,2)==2 and not b.Visibility.cell(b,2,2).open,"Seeing the door again updates its actual current state")
 c=field();b=c.battle
 b.tile(7,2).merge({"block":true,"kind":"rock"},true);b.refresh_knowledge()
 var actor=b.unit("mara")
 var planned=b.path(actor,9,2,true)
 test.check(b.Visibility.level(b,7,2)==0 and 43 in planned.path,"Provisional route assumes unknown ground without routing around a hidden obstacle")
 var ap=actor.ap
 test.check(b.action("mara","move",{"x":9,"y":2}) and actor.x==6 and actor.ap==ap-12 and b.tile(7,2).block,"Actual execution stops before newly encountered terrain and only charges executed steps")
 test.check(b.Visibility.level(b,7,2)==2 and b.Visibility.cell(b,7,2).block,"Approach reveals the obstacle rather than silently bypassing it")
 c=field();b=c.battle
 b.unit("mara").x=10;b.refresh_knowledge()
 b.unit("mara").x=0;b.refresh_knowledge()
 test.check(b.Visibility.level(b,10,2)==1,"Previously observed ground remains remembered after leaving sight")
 test.check(c.command("retreat") and c.save_to("user://fog-retreat.json") and loaded.load_from("user://fog-retreat.json"),"Sector terrain memory persists across retreat and campaign save")
 c=loaded;c.command("route",{"sector":90});c.command("advance",{"minutes":600});c.command("enter")
 test.check(c.battle.Visibility.level(c.battle,10,2)==1,"Re-entry preserves explored terrain outside the deployment briefing zone")
 c=field();b=c.battle
 actor=b.unit("mara");var enemy=b.unit(c.s.groups[0].fighters[0].id)
 test.loadout(actor.person,"weapon","bow")
 actor.x=4;actor.y=6;enemy.x=8;enemy.y=6
 actor.person.perception=100;enemy.person.perception=100
 b.tile(7,6).cover=35
 b.refresh_knowledge()
 var sheltered=b.directional_cover(actor,enemy)
 var front=b.hit_chance(actor,enemy)
 actor.x=8;actor.y=2;b.refresh_knowledge()
 test.check(sheltered==35 and b.directional_cover(actor,enemy)==0 and b.hit_chance(actor,enemy)>front,"Low cover protects from its incoming side and can be flanked")
 actor.x=4;actor.y=6;b.tile(4,6).elevation=1
 test.check(b.directional_cover(actor,enemy)==25,"Elevated attacker reduces the directional protection of low cover")
 b.tile(4,6).elevation=0;b.tile(7,6).cover=0;b.tile(7,6).block=true;b.tile(7,6).kind="window"
 test.check(b.los(actor,enemy) and b.directional_cover(actor,enemy)==35,"An adjacent window can pass sight while supplying directional protection")
 c=field();b=c.battle
 for u in b.t.units:
  if u.team=="company" and u.id!="mara": u.person.hp=0
 actor=b.unit("mara");actor.x=2;actor.y=6;actor.person.perception=100
 enemy=b.unit(c.s.groups[0].fighters[0].id);enemy.x=6;enemy.y=4;enemy.person.perception=100
 test.loadout(enemy.person,"weapon","bow")
 b.tile(5,6).cover=35
 b.t.turn="enemy";b.refresh_knowledge()
 b.ai_unit(enemy)
 test.check(b.t.ai_state[enemy.id].actions.has("take directional cover"),"Ranged AI takes a legal protected firing step before attacking")
 test.check(enemy.ap>=0 and not b.tile(enemy.x,enemy.y).block,"Cover-seeking AI obeys actual occupancy, terrain and AP")
 c=hidden_memory(2);b=c.battle;enemy=b.unit(c.s.groups[0].fighters[0].id)
 var rng=c.s.rng
 b.ai_unit(enemy)
 var first={"x":enemy.x,"y":enemy.y,"goal":b.t.ai_state[enemy.id].goal,"actions":b.t.ai_state[enemy.id].actions}
 test.check(first.goal=={"x":12,"y":2} and first.actions.has("investigate last seen contact") and c.s.rng==rng,"AI investigates stored coordinates without attacking or rolling against an unseen foe")
 var other=hidden_memory(12);var second=other.battle.unit(other.s.groups[0].fighters[0].id)
 other.battle.ai_unit(second)
 test.check(second.x==first.x and second.y==first.y and other.battle.t.ai_state[second.id].goal==first.goal and other.battle.t.ai_state[second.id].actions==first.actions,"Moving a still-hidden player does not change pursuit decisions based on the same memory")
 test.check(c.save_to("user://ai-memory.json") and loaded.load_from("user://ai-memory.json") and loaded.battle.t.ai_state[enemy.id]==b.t.ai_state[enemy.id],"AI search goal and decision trace persist through tactical save/load")
 c=hidden_memory();b=c.battle;b.t.round=6;enemy=b.unit(c.s.groups[0].fighters[0].id)
 b.ai_unit(enemy)
 test.check(not b.t.ai_state[enemy.id].actions.has("investigate last seen contact"),"Expired opponent memory stops directing pursuit")
 c=hidden_memory();b=c.battle;enemy=b.unit(c.s.groups[0].fighters[0].id);enemy.x=13
 b.ai_unit(enemy)
 test.check(b.t.ai_state[enemy.id].get("searched","")=="mara:1","Reaching an empty last-seen location marks it searched rather than tracking hidden movement")
 c=field();b=c.battle;enemy=b.unit(c.s.groups[0].fighters[0].id)
 var ally=b.unit(c.s.groups[0].fighters[1].id)
 ally.x=13;ally.y=2;ally.person.hp=20
 enemy.ap=4;b.t.turn="enemy";b.refresh_knowledge()
 b.ai_unit(enemy)
 test.check(b.t.ai_state[enemy.id].actions.has("support wounded ally") and b.distance(enemy,ally)<=1,"An unengaged fighter moves to support a nearby wounded ally")
 c=field();b=c.battle
 var invalid=c.s.duplicate(true)
 invalid.battle.fog.company["99999"]={}
 test.check(not c.valid_save(invalid) and not b.Visibility.valid(invalid.battle),"Out-of-map fog cache record is rejected")
 invalid=c.s.duplicate(true)
 invalid.battle.ai_state.unknown={"actions":[]}
 test.check(not c.valid_save(invalid),"AI state cannot bind to an unknown tactical identity")
 invalid=c.s.duplicate(true)
 invalid.battle.fog.company["0"]={"x":0,"y":0,"cost":-1,"elevation":0,"block":false,"cover":0,"conceal":0,"door":false,"open":false,"kind":"grass"}
 test.check(not c.valid_save(invalid) and not b.Visibility.valid(invalid.battle),"Malformed remembered tile costs are rejected")
 test.check(loaded.load_from("res://tests/fixtures/schema2-tactical.json") and loaded.battle.t.phase=="combat" and loaded.battle.t.has("fog") and loaded.battle.t.ai_state.is_empty(),"Legacy active combat safely initializes fog and AI search state")
