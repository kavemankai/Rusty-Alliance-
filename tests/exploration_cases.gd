extends RefCounted
const Campaign=preload("res://sim/campaign.gd")
const Fields=preload("res://tests/battlefield_cases.gd")

# Open, low-perception contact fixture isolates transition rules from map LOS.
static func field():
 var c=Fields.contact(90)
 c.autosave_path="user://exploration-test-autosave.json"
 return arrange(c)

static func arrange(c):
 var b=c.battle
 for cell in b.t.tiles: cell.merge({"block":false,"door":false,"cost":2,"elevation":0,"conceal":0,"cover":0,"kind":"grass"},true)
 var friendly=0;var hostile=0
 for u in b.t.units:
  u.person.perception=0;u.person.bleeding=0
  if u.team=="company":
   u.x=0;u.y=2+friendly*4;friendly+=1
  else:
   u.x=16;u.y=2+hostile*8;hostile+=1
 return c

static func run(test) -> void:
 var c=field();var b=c.battle
 var time=c.s.time;var rng=c.s.rng
 var ap=b.unit("mara").ap
 test.check(c.command("confirm_deployment",{"explore":true}) and b.t.phase=="exploration" and b.t.turn=="company","Scout confirmation starts exploration when neither side detects opponents")
 test.check(b.unit("mara").ap==ap and c.s.time==time and c.s.rng==rng and b.t.exploration.elapsed==0,"Exploration entry preserves AP, PRNG, world time and positions")
 var before=JSON.stringify(c.s)
 test.check(not b.end_turn() and not c.command("resolve") and not c.command("advance",{"minutes":60}) and JSON.stringify(c.s)==before,"Exploration cannot advance combat rounds, resolve an ongoing battle or advance strategic time")
 test.check(not b.action("mara","attack",{"target":c.s.groups[0].fighters[0].id}) and not b.action("mara","guard") and JSON.stringify(c.s)==before,"Exploration cannot attack or reserve combat reactions")
 test.check(not b.action("mara","move",{"x":99,"y":99}) and JSON.stringify(c.s)==before,"Invalid exploration route spends no local time or AP")
 var enemy=b.unit(c.s.groups[0].fighters[0].id)
 test.check(c.command("explore_wait") and b.t.exploration.elapsed==1 and enemy.x==17 and b.t.phase=="exploration","Wait advances one local pulse and a real enemy patrol step")
 test.check(b.action("mara","move",{"x":2,"y":2}) and b.unit("mara").x==2 and b.t.exploration.elapsed==3,"Exploration movement advances one simultaneous local pulse per tile")
 test.check(c.s.time==time and c.s.rng==rng and b.t.round==1,"Local movement/patrol time does not advance strategic events, combat rounds or PRNG")
 test.check(c.save_to("user://exploring.json"),"Exploration state saves")
 var loaded=Campaign.new()
 loaded.autosave_path=c.autosave_path
 var state=b.t.exploration.duplicate(true)
 test.check(loaded.load_from("user://exploring.json") and loaded.battle.t.phase=="exploration" and loaded.battle.t.exploration==state and loaded.battle.unit("mara").x==2,"Mode, elapsed pulses, patrol state and character positions survive reload")
 c=loaded;b=c.battle
 loaded.s.mercs.mara.morale-=1
 test.check(b.unit("mara").person.morale==loaded.s.mercs.mara.morale,"Exploration reload binds authoritative company profiles")
 test.check(b.action("mara","move",{"x":15,"y":2}) and b.t.phase=="combat" and b.unit("mara").x<15 and b.t.exploration.orders.is_empty(),"Detection stops a long exploration route at first contact and cancels pending orders")
 test.check(b.t.turn=="company" and b.t.round==1 and b.unit("mara").ap<=ap and b.known("company",enemy.id),"Contact establishes a valid company turn with remaining AP and actual perceived opponent")
 var contact_ap=b.unit("mara").ap
 test.check(c.save_to("user://exploration-contact.json") and loaded.load_from("user://exploration-contact.json") and loaded.battle.t.phase=="combat" and loaded.battle.unit("mara").ap==contact_ap,"Transitioned combat saves without an AP refill or reopened exploration")
 c=field();b=c.battle
 for u in b.t.units:
  if u.team=="enemy": u.person.perception=100
 c.command("confirm_deployment",{"explore":true})
 for anchor in b.t.exploration.patrol.values(): anchor.side=-1
 test.check(b.t.phase=="exploration" and c.command("explore_wait") and b.t.phase=="combat" and not b.known("company",c.s.groups[0].fighters[0].id) and b.known("enemy","mara"),"Enemy-only detection also triggers combat without exposing hidden enemy coordinates")
 c=field();b=c.battle
 enemy=b.unit(c.s.groups[0].fighters[0].id);enemy.x=5;enemy.y=2
 test.check(c.command("confirm_deployment",{"explore":true}) and b.t.phase=="combat" and b.t.exploration.elapsed==0,"Immediate post-deployment contact bypasses exploration without an extra time pulse")
 c=field();b=c.battle;c.command("confirm_deployment",{"explore":true})
 ap=b.unit("mara").ap
 test.check(c.command("combat") and b.t.phase=="combat" and b.unit("mara").ap==ap,"Manual combat entry preserves remaining AP")
 before=JSON.stringify(c.s)
 test.check(not c.command("explore") and JSON.stringify(c.s)==before,"Combat cannot return to exploration before three quiet rounds")
 for cell in b.t.tiles:
  if cell.x==8: cell.block=true
 for i in range(3): b.end_turn()
 test.check(b.t.quiet_rounds==3 and b.t.round==4,"Three full rounds without either side seeing opponents establish quiet state")
 ap=b.unit("mara").ap
 var positions=[]
 for u in b.t.units: positions.append([u.id,u.x,u.y,u.person.hp])
 test.check(c.command("explore") and b.t.phase=="exploration" and b.unit("mara").ap==ap and b.t.round==4,"Quiet combat resumes exploration without resetting turn number or AP")
 var after=[]
 for u in b.t.units: after.append([u.id,u.x,u.y,u.person.hp])
 test.check(after==positions,"Leaving combat preserves all positions and injuries")
 c=field();b=c.battle;c.command("confirm_deployment",{"explore":true})
 b.unit("mara").person.bleeding=2
 b.unit("mara").person.hp=20
 c.command("explore_wait",{"pulses":10})
 test.check(b.unit("mara").person.hp==18 and b.t.exploration.elapsed==10,"Untreated bleeding progresses during local exploration time")
 before=JSON.stringify(c.s)
 test.check(not c.command("explore_wait",{"pulses":17}) and JSON.stringify(c.s)==before,"Oversized exploration time request rejects atomically")
 c=field();b=c.battle;c.command("confirm_deployment",{"explore":true})
 # Persist a legal interrupted order, then obstruct it before its next pulse.
 var actor=b.unit("mara")
 b.t.exploration.orders.mara=b.path(actor,3,2).path.duplicate()
 test.check(c.save_to("user://exploration-order.json") and loaded.load_from("user://exploration-order.json") and loaded.battle.t.exploration.orders.mara.size()==3,"Pending adjacent movement route survives save/load")
 c=loaded;b=c.battle;b.tile(1,2).block=true
 c.command("explore_wait")
 test.check(b.unit("mara").x==0 and not b.t.exploration.orders.has("mara"),"A newly blocked route stops without teleporting or charging movement AP")
 c=field();b=c.battle;c.command("confirm_deployment",{"explore":true})
 b.unit("mara").person.hp=1;b.unit("mara").person.bleeding=2
 c.command("explore_wait",{"pulses":10})
 test.check(b.unit("mara").person.hp==0 and b.unit("mara").person.inventory.is_empty() and not b.t.ground.is_empty(),"Exploration bleeding death creates actual ground inventory without duplication")
 c=field();b=c.battle;c.command("confirm_deployment",{"explore":true})
 test.check(c.command("retreat") and c.battle==null and c.s.sectors[90].owner=="bandits","Exploration withdrawal uses real safe-sector retreat and preserves hostile control")
 c=field();b=c.battle;c.command("confirm_deployment",{"explore":true})
 var invalid=c.s.duplicate(true)
 invalid.battle.exploration.orders.mara=[100]
 test.check(not c.valid_save(invalid),"Saved exploration route cannot jump across the map")
 invalid=c.s.duplicate(true);invalid.battle.exploration.elapsed=-1
 test.check(not c.valid_save(invalid),"Negative exploration time is rejected")
 invalid=c.s.duplicate(true);invalid.battle.exploration.patrol.mara={"x":0,"y":2,"side":1}
 test.check(not c.valid_save(invalid),"Company identities cannot own hostile patrol records")
 invalid=c.s.duplicate(true);invalid.battle.turn="enemy"
 test.check(not c.valid_save(invalid),"Exploration cannot load with an enemy team turn")
 test.check(loaded.load_from("res://tests/fixtures/schema2-tactical.json") and loaded.battle.t.phase=="combat" and loaded.battle.t.quiet_rounds==0,"Older active saves retain combat and initialize quiet-round tracking safely")

 c=arrange(Fields.contact(17,true));b=c.battle
 test.check(c.command("confirm_deployment",{"explore":true}) and b.t.phase=="exploration" and b.unit("mara")==null,"A home-only garrison can scout without remote company units")
 var levy=b.unit(c.s.sectors[17].levies[0].id)
 test.check(b.action(levy.id,"move",{"x":2,"y":levy.y}) and c.save_to("user://levy-exploration.json") and loaded.load_from("user://levy-exploration.json"),"Levy exploration movement and mode survive save/load")
 loaded.s.sectors[17].levies[0].morale-=2
 test.check(loaded.battle.unit(levy.id).person.morale==loaded.s.sectors[17].levies[0].morale,"Loaded exploring levies bind the authoritative home roster")
 c=Campaign.new();c.autosave_path="user://exploration-test-autosave.json"
 c.command("hire",{"id":"ada"});c.command("split",{"id":"oswin"})
 for q in c.s.squads.values(): q.sector=90
 c.s.groups=[c.s.groups[0]];c.s.groups[0].sector=90
 c.encounter(c.s.squads.first,90);c.command("enter");arrange(c);b=c.battle
 c.command("confirm_deployment",{"explore":true})
 for id in ["mara","oswin"]:
  var u=b.unit(id)
  b.t.exploration.orders[id]=b.path(u,2,u.y).path.duplicate()
 c.command("explore_wait",{"pulses":2})
 test.check(b.t.squads.size()==2 and b.unit("mara").x==2 and b.unit("oswin").x==2 and b.t.phase=="exploration","One local pulse advances pending orders from combined squads together")

 c=field();b=c.battle;c.command("confirm_deployment")
 b.t.quiet_rounds=3
 var nearby=b.unit(c.s.groups[0].fighters[0].id);nearby.x=5;nearby.y=2
 before=JSON.stringify(c.s)
 test.check(not c.command("explore") and JSON.stringify(c.s)==before,"Current LOS rejects exploration atomically even if saved quiet counter/knowledge are stale")
 c=field();b=c.battle;c.command("confirm_deployment",{"explore":true})
 invalid=c.s.duplicate(true)
 invalid.battle.exploration.patrol[c.s.groups[0].fighters[0].id].side=true
 test.check(not c.valid_save(invalid),"Malformed boolean patrol direction cannot enter movement arithmetic")
