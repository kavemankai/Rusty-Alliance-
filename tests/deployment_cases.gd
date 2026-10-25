extends RefCounted
const Campaign=preload("res://sim/campaign.gd")

static func contact():
 var c=Campaign.new()
 c.autosave_path="user://deployment-test-autosave.json"
 c.command("accept",{"id":"redbank"})
 c.command("route",{"sector":34})
 c.command("advance",{"minutes":600})
 c.command("enter")
 return c

static func run(test) -> void:
 var c=contact()
 var b=c.battle
 var mara=b.unit("mara")
 var oswin=b.unit("oswin")
 test.check(b.t.phase=="deployment" and b.outcome()=="deployment" and b.t.round==1,"Contact enters a separate deployment phase before combat")
 test.check(mara.deployed and oswin.deployed and b.deployment_error(mara.id,mara.x,mara.y)=="","Default formation is legal and ready for review")
 var snapshot=JSON.stringify(c.s)
 test.check(not b.action("mara","move",{"x":3,"y":3}) and not b.end_turn() and not c.command("advance",{"minutes":60}) and not c.command("resolve") and JSON.stringify(c.s)==snapshot,"Deployment rejects movement, enemy turn, world time and resolution atomically")
 var enemy=null
 for u in b.t.units:
  if u.team=="enemy": enemy=u;break
 test.check(not b.attack(enemy,mara,0,true) and not c.command("unequip",{"id":"mara","slot":"weapon"}) and JSON.stringify(c.s)==snapshot,"Reaction attacks and equipment AP changes cannot bypass deployment freeze")
 b.refresh_knowledge()
 b.start_turn("enemy")
 b.ai_unit(enemy)
 test.check(b.t.knowledge=={"company":{},"enemy":{}} and JSON.stringify(c.s)==snapshot,"Repositioning and pre-start AI calls reveal no opponents or advance simulation")
 test.check(not c.command("deploy",{"id":"mara","x":-1,"y":3}) and not c.command("deploy",{"id":"mara","x":8,"y":3}) and not c.command("deploy",{"id":"mara","x":1.5,"y":3}) and JSON.stringify(c.s)==snapshot,"Out-of-grid, outside-zone and fractional placement reject without mutation")
 test.check(not c.command("deploy",{"id":"mara","x":oswin.x,"y":oswin.y}) and JSON.stringify(c.s)==snapshot,"Occupied friendly tiles reject without overlap or AP cost")
 test.check(not c.command("deploy",{"id":enemy.id,"x":0,"y":0}) and not c.command("deploy",{"id":"missing","x":0,"y":0}) and JSON.stringify(c.s)==snapshot,"Enemy and unknown identities cannot be placed")
 test.check(not c.command("deploy",{"id":"mara","x":3,"y":3,"facing":9}) and JSON.stringify(c.s)==snapshot,"Invalid facing rejects placement atomically")
 var ap=mara.ap
 var rng=c.s.rng
 var world_time=c.s.time
 var hp=mara.person.hp
 var profile=JSON.stringify(mara.person)
 test.check(c.command("deploy",{"id":"mara","x":3,"y":3,"facing":2}) and mara.x==3 and mara.y==3 and mara.facing==2,"Placement command sets chosen tile and facing")
 test.check(mara.ap==ap and JSON.stringify(mara.person)==profile and c.s.rng==rng and c.s.time==world_time,"Deployment consumes no AP, resources, health, fatigue, RNG or world time")
 test.check(c.save_to("user://deployment-position.json"),"Unconfirmed formation can be saved")
 test.check(c.save_to("user://deployment-position.json") and FileAccess.file_exists("user://deployment-position.json.bak"),"Repeated deployment save retains a valid previous-generation backup")
 var loaded=Campaign.new()
 loaded.autosave_path=c.autosave_path
 test.check(loaded.load_from("user://deployment-position.json") and loaded.battle.t.phase=="deployment" and loaded.battle.unit("mara").x==3 and loaded.battle.unit("mara").facing==2,"Deployment phase, tile and facing survive save/load")
 loaded.s.mercs.mara.morale-=1
 test.check(loaded.battle.unit("mara").person.morale==loaded.s.mercs.mara.morale,"Loaded deployment rebinds the canonical mercenary profile")
 c=loaded;b=c.battle;mara=b.unit("mara")
 test.check(c.command("confirm_deployment") and b.t.phase=="combat" and b.t.turn=="company" and b.t.round==1 and mara.ap==ap and mara.person.hp==hp,"Confirmation starts first company turn without AP refill or bleeding tick")
 test.check(b.can_act(mara) and c.s.rng==rng and c.s.time==world_time,"Combat becomes actionable only after confirmation with clock and RNG preserved")
 snapshot=JSON.stringify(c.s)
 test.check(not c.command("confirm_deployment") and not c.command("deploy",{"id":"mara","x":2,"y":3}) and JSON.stringify(c.s)==snapshot,"Confirmed deployment cannot reopen, relocate or refill AP")
 test.check(b.action("mara","move",{"x":4,"y":3}) and mara.ap<ap,"Normal combat movement charges AP after confirmation")
 c.save_to("user://deployment-started.json")
 test.check(loaded.load_from("user://deployment-started.json") and loaded.battle.t.phase=="combat" and loaded.battle.unit("mara").x==4 and loaded.battle.unit("mara").ap<ap,"Confirmed combat position and spent AP survive reload")
 # Old active saves have no phase field. They resume combat without redeployment.
 var previous=loaded.s.duplicate(true)
 previous.battle.erase("phase")
 for u in previous.battle.units: u.erase("deployed")
 var f=FileAccess.open("user://deployment-old-combat.json",FileAccess.WRITE)
 f.store_string(JSON.stringify(previous));f.close()
 test.check(loaded.load_from("user://deployment-old-combat.json") and loaded.battle.t.phase=="combat" and loaded.battle.unit("mara").x==4 and loaded.battle.unit("mara").ap<ap,"Previous schema-3 active battles resume in place without a fresh placement phase")
 for fixture in ["legacy-tactical.json","schema2-tactical.json"]:
  test.check(loaded.load_from("res://tests/fixtures/"+fixture) and loaded.battle.t.phase=="combat","Older tactical fixture resumes directly in combat: "+fixture)
 c=contact();b=c.battle
 b.tile(0,0).block=true
 snapshot=JSON.stringify(c.s)
 test.check(not c.command("deploy",{"id":"mara","x":0,"y":0}) and JSON.stringify(c.s)==snapshot,"Blocked terrain cannot be used for deployment")
 # A hostile survivor close to the entry edge restricts placement, stays put,
 # and remains hidden. This is a remembered-position re-entry fixture.
 c=Campaign.new()
 c.autosave_path="user://deployment-test-autosave.json"
 c.s.groups[0].positions[c.s.groups[0].fighters[0].id]={"x":2,"y":3}
 c.command("route",{"sector":34});c.command("advance",{"minutes":600});c.command("enter")
 b=c.battle
 enemy=b.unit(c.s.groups[0].fighters[0].id)
 test.check(enemy.x==2 and enemy.y==3 and not b.deployment_tile(b.t,3,3) and not b.known("company",enemy.id),"Re-entry preserves near-edge enemy position and excludes close deployment tiles without revealing the unit")
 test.check(c.command("confirm_deployment"),"Safe defaults adapt to hostile survivors without relocating them")
 # Combined squads and a full garrison use one validated formation.
 c=Campaign.new()
 c.autosave_path="user://deployment-test-autosave.json"
 c.s.funds=4000
 for i in range(12): c.command("levy",{"sector":17})
 c.command("split",{"id":"oswin"})
 c.s.groups=[c.s.groups[0]]
 c.s.groups[0].sector=18;c.s.sectors[18].owner="bandits"
 c.faction_tick();c.command("enter")
 b=c.battle
 var friend_count=0
 var placed=true
 for u in b.t.units:
  if u.team=="company":
   friend_count+=1
   placed=placed and u.deployed and b.deployment_error(u.id,u.x,u.y)==""
 test.check(friend_count==14 and b.t.squads.size()==2 and placed,"Combined squads and twelve local levies receive non-overlapping legal placements")
 var levy=b.unit(c.s.sectors[17].levies[0].id)
 var free={}
 for cell in b.t.tiles:
  if b.deployment_error(levy.id,cell.x,cell.y)=="" and (cell.x!=levy.x or cell.y!=levy.y): free=cell;break
 test.check(c.command("deploy",{"id":levy.id,"x":free.x,"y":free.y,"facing":6}),"Local levy placement and facing use the same authoritative command")
 test.check(c.save_to("user://deployment-combined.json") and loaded.load_from("user://deployment-combined.json") and loaded.battle.t.phase=="deployment" and loaded.battle.t.squads.size()==2,"Combined squad and garrison formation survives unconfirmed save/load")
 var levy_id=levy.id
 loaded.s.sectors[17].levies[0].morale-=3
 test.check(loaded.battle.unit(levy_id).person.morale==loaded.s.sectors[17].levies[0].morale and loaded.command("confirm_deployment"),"Loaded levy profiles rebind and entire formation confirms together")
 # Home-only placement uses the same phase with no mercenary participants.
 c=Campaign.new();c.autosave_path="user://deployment-test-autosave.json"
 for i in range(3): c.command("levy",{"sector":17})
 c.s.squads.first.sector=1
 c.s.groups=[c.s.groups[0]];c.s.groups[0].sector=18;c.s.sectors[18].owner="bandits"
 c.faction_tick();c.command("enter")
 test.check(c.battle.t.phase=="deployment" and c.battle.t.squads.is_empty() and c.battle.unit("mara")==null and c.command("confirm_deployment"),"Garrison-only contact has its own reviewable deployment without remote mercenaries")
 c=contact()
 var bad=c.s.duplicate(true)
 bad.battle.phase="unknown"
 test.check(not c.valid_save(bad),"Unknown battle phase is rejected")
 bad=c.s.duplicate(true)
 bad.battle.knowledge.company["leak"]={"visible":true}
 test.check(not c.valid_save(bad),"Pre-combat save cannot contain revealed enemy knowledge")
 bad=c.s.duplicate(true)
 for u in bad.battle.units:
  if u.id=="mara": u.x=9
 test.check(not c.valid_save(bad),"Placed units outside the zone cannot be loaded")
 c.battle.unit("mara").deployed=false
 snapshot=JSON.stringify(c.s)
 test.check(not c.command("confirm_deployment") and JSON.stringify(c.s)==snapshot,"Incomplete formation cannot confirm or consume a turn")
 c=Campaign.new()
 c.autosave_path="user://deployment-test-autosave.json"
 c.command("route",{"sector":34});c.command("advance",{"minutes":600})
 # Persisted blocked entry terrain is a placement-capacity failure fixture.
 # Build the existing map through the same tactical data builder.
 var builder=preload("res://sim/tactical.gd").new(c)
 for cell in builder.t.tiles:
  if cell.x<6: cell.block=true
 c.command("enter")
 test.check(not c.battle.unit("mara").deployed and not c.command("confirm_deployment"),"Blocked entry zone leaves units unplaced and cannot silently start combat")
 test.check(c.save_to("user://deployment-no-space.json") and loaded.load_from("user://deployment-no-space.json") and not loaded.battle.unit("mara").deployed,"Unplaced formation remains recoverable through save/load")
 test.check(loaded.command("retreat") and loaded.battle==null,"No-space formation can withdraw through the existing safe-exit rules")
 c=contact()
 test.check(c.command("retreat") and c.battle==null and c.s.sectors[34].owner=="bandits" and c.s.jobs[0].status=="active","Pre-combat withdrawal uses actual safe-exit resolution without a capture reward")
