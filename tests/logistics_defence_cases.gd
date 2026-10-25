extends RefCounted
const Campaign=preload("res://sim/campaign.gd")
const Data=preload("res://sim/catalog.gd")
const Supplies=preload("res://sim/supplies.gd")
const Garrison=preload("res://sim/garrison.gd")
const Items=preload("res://sim/inventory.gd")

static func quiet():
 var c=Campaign.new()
 c.autosave_path="user://logistics-test-autosave.json"
 c.s.groups=[]
 return c

static func defence(with_mercs: bool=true,count: int=2,split_squad: bool=false):
 var c=Campaign.new()
 c.autosave_path="user://logistics-test-autosave.json"
 for i in range(count): c.command("levy",{"sector":17})
 c.command("supply_transfer",{"from":"first","to":"sector:17","resource":"food","amount":20})
 c.command("supply_transfer",{"from":"first","to":"sector:17","resource":"medicine","amount":5})
 c.s.groups=[c.s.groups[0]]
 c.s.groups[0].sector=18
 c.s.groups[0].objective=17
 c.s.sectors[18].owner="bandits"
 if split_squad: c.command("split",{"id":"oswin"})
 if not with_mercs: c.s.squads.first.sector=1
 c.faction_tick()
 c.command("enter")
 c.command("confirm_deployment")
 return c

static func total(state: Dictionary,resource: String) -> int:
 var sum=0
 for q in state.squads.values(): sum+=q.supplies[resource]
 for cell in state.sectors: sum+=cell.supplies[resource]
 return sum

static func run(test) -> void:
 var c=quiet()
 var original=c.s.squads.first.supplies.duplicate()
 test.check(not c.s.has("food") and c.s.sectors[17].supplies.food==0,"Supplies have explicit squad and depot owners without a global duplicate")
 c.command("split",{"id":"oswin"})
 test.check(c.s.squads.first.supplies.food==30 and c.s.squads.squad_oswin.supplies.food==30,"Squad split divides carried provisions proportionally")
 var conserved=true
 for kind in Supplies.KINDS: conserved=conserved and total(c.s,kind)==original[kind]
 test.check(conserved,"Squad split conserves every supply type exactly")
 c.command("merge",{"from":"squad_oswin","to":"first"})
 test.check(c.s.squads.first.supplies==original,"Merge reunites all provisions without duplication")
 c.command("split",{"id":"oswin"})
 c.s.squads.first.supplies.food=0
 c.s.squads.squad_oswin.sector=18
 c.command("advance",{"minutes":60})
 test.check(c.s.mercs.mara.morale==65 and c.s.mercs.oswin.morale==70,"A starving squad cannot consume a distant squad's food")
 test.check(c.s.squads.squad_oswin.supplies.food==29,"Fed detached squad pays only its own hourly ration")
 var before=JSON.stringify(c.s)
 test.check(not c.command("supply_transfer",{"from":"squad_oswin","to":"first","resource":"food","amount":5}) and JSON.stringify(c.s)==before,"Remote supply transfer rejects atomically")
 c.s.squads.squad_oswin.sector=17
 test.check(c.command("supply_transfer",{"from":"squad_oswin","to":"first","resource":"food","amount":5}) and c.s.squads.first.supplies.food==5 and c.s.squads.squad_oswin.supplies.food==24,"Co-located squads exchange exact ration quantities")
 before=JSON.stringify(c.s)
 test.check(not c.command("supply_transfer",{"from":"first","to":"sector:17","resource":"food","amount":6}) and JSON.stringify(c.s)==before,"Insufficient supply transfer spends nothing")
 test.check(not c.command("supply_transfer",{"from":"first","to":"sector:17","resource":"food","amount":0}) and not c.command("supply_transfer",{"from":"first","to":"sector:17","resource":"food","amount":1.5}),"Zero and fractional transfers are rejected")
 c.command("route",{"squad":"squad_oswin","sector":33})
 test.check(not c.command("supply_transfer",{"from":"squad_oswin","to":"first","resource":"food","amount":1}),"A travelling squad cannot hand off supplies")
 c=quiet()
 test.check(c.command("supply_transfer",{"from":"first","to":"sector:17","resource":"food","amount":10}) and c.s.sectors[17].supplies.food==10 and c.s.squads.first.supplies.food==50,"Stationary squad deposits real food into its local depot")
 test.check(c.command("supply_transfer",{"from":"sector:17","to":"first","resource":"food","amount":4}) and c.s.sectors[17].supplies.food==6 and c.s.squads.first.supplies.food==54,"Loading a depot consumes its actual stock")
 c.s.sectors[17].owner="bandits"
 before=JSON.stringify(c.s)
 test.check(not c.command("supply_transfer",{"from":"sector:17","to":"first","resource":"food","amount":1}) and JSON.stringify(c.s)==before,"Hostile depots are inaccessible until control is recovered")
 c=quiet()
 c.command("split",{"id":"oswin"})
 var first_before=c.s.squads.first.supplies.food
 var other_before=c.s.squads.squad_oswin.supplies.food
 c.command("buy",{"squad":"squad_oswin","item":"food"})
 test.check(c.s.squads.first.supplies.food==first_before and c.s.squads.squad_oswin.supplies.food==other_before+20,"Market purchases fill the selected squad, not a remote company pool")
 c.s.sectors[34].owner="company"
 c.s.sectors[34].supplies.food=0
 first_before=c.s.squads.first.supplies.food
 c.daily()
 test.check(c.s.sectors[34].supplies.food==28 and c.s.squads.first.supplies.food==first_before,"Farm output remains in its producing sector")
 var q=c.s.squads.first
 var light=c.travel_cost(q,33)
 q.supplies.tools+=100
 test.check(c.travel_cost(q,33)>light,"Carried provisions and tools add real strategic travel burden")
 c=quiet()
 c.command("hire",{"id":"ada"})
 c.command("split",{"id":"ada"})
 c.s.squads.squad_ada.sector=18
 c.s.mercs.mara.hp=40
 c.s.mercs.mara.bleeding=2
 c.command("assignment",{"id":"mara","value":"medical"})
 var medicine=c.s.squads.first.supplies.medicine
 c.command("advance",{"minutes":60})
 test.check(c.s.mercs.mara.hp==43 and c.s.squads.first.supplies.medicine==medicine-1,"Remote physician contributes no skill and local treatment consumes one local medicine")
 c.s.mercs.mara.hp=40
 c.s.squads.squad_ada.sector=17
 c.command("advance",{"minutes":60})
 test.check(c.s.mercs.mara.hp==47,"Co-located physician improves actual healing")
 c.s.squads.first.supplies.medicine=0
 c.s.mercs.mara.hp=40
 c.s.mercs.mara.bleeding=1
 c.command("advance",{"minutes":60})
 test.check(c.s.mercs.mara.hp==39 and c.s.squads.squad_ada.supplies.medicine>0,"A patient's squad cannot spend another squad's medical stock automatically")
 c.s.mercs.mara.bleeding=0
 Data.equipped(c.s.mercs.mara,"weapon").condition=20
 c.s.squads.first.supplies.tools=0
 c.command("assignment",{"id":"mara","value":"repair"})
 c.command("advance",{"minutes":60})
 test.check(Data.condition(c.s.mercs.mara)==20,"Repairs cannot consume a neighbouring squad's tools")
 # Multiple friendly squads deploy into the same real encounter.
 c=defence(true,1,true)
 var b=c.battle
 test.check(b!=null and b.t.squads.size()==2 and b.unit("mara")!=null and b.unit("oswin")!=null,"Co-located squads deploy together instead of receiving separate duplicate battles")
 var cell=c.s.sectors[17]
 var levy=cell.levies[0]
 test.check(b.unit(levy.id)!=null and b.unit(levy.id).role=="levy" and b.unit(levy.id).team=="company","Recruited levy is a controllable tactical defender")
 var occupied={}
 var unique=true
 for u in b.t.units:
  var key="%d:%d" % [u.x,u.y]
  unique=unique and not occupied.has(key) and not b.tile(u.x,u.y).block
  occupied[key]=true
 test.check(unique,"Combined mercenaries levies and enemies deploy without occupied or blocked cells")
 b.unit(levy.id).person.hp=52
 test.check(cell.levies[0].hp==52,"Tactical levy health updates its canonical strategic profile")
 var unit=b.unit("mara")
 unit.person.bleeding=2
 c.s.squads.first.supplies.medicine=1
 var other_medicine=c.s.squads.squad_oswin.supplies.medicine
 test.check(b.action("mara","aid") and c.s.squads.first.supplies.medicine==0 and c.s.squads.squad_oswin.supplies.medicine==other_medicine,"Tactical first aid consumes the acting mercenary's own pack")
 unit=b.unit(levy.id)
 unit.person.bleeding=1
 var depot_medicine=cell.supplies.medicine
 test.check(b.action(levy.id,"aid") and cell.supplies.medicine==depot_medicine-1,"Levy first aid consumes the home depot's medicine")
 before=JSON.stringify(c.s)
 test.check(not c.command("supply_transfer",{"from":"first","to":"sector:17","resource":"food","amount":1}) and JSON.stringify(c.s)==before,"Paused combat cannot be used to teleport provisions between stores")
 test.check(c.save_to("user://combined-defence.json"),"Combined defence with squad supplies saves")
 var loaded=Campaign.new()
 loaded.autosave_path="user://logistics-test-autosave.json"
 test.check(loaded.load_from("user://combined-defence.json") and loaded.battle.t.squads.size()==2,"Combined defence resumes with both squad memberships")
 loaded.battle.unit(levy.id).person.hp=41
 test.check(loaded.s.sectors[17].levies[0].hp==41,"Loaded levy references rebind to the strategic garrison")
 test.check(Items.ownership_error(loaded.s)=="","Loaded levy gear has unique inventory ownership")
 # A garrison must defend even when the mercenary company is elsewhere.
 c=defence(false,3)
 b=c.battle
 test.check(c.s.encounter.squad=="" and b.t.squads.is_empty() and b.unit("mara")==null,"Enemy strategic movement creates a garrison-only tactical engagement")
 var only_levies=true
 for u in b.t.units:
  if u.team=="company": only_levies=only_levies and u.role=="levy"
 test.check(only_levies,"Garrison-only battle contains actual levies and no remote mercenaries")
 before=JSON.stringify(c.s)
 test.check(not c.command("retreat") and JSON.stringify(c.s)==before,"Home-bound levies cannot retreat by teleporting as a company squad")
 test.play_battle(c)
 test.check(b.outcome()=="victory" and c.command("resolve") and c.s.sectors[17].owner=="company","Persistent levies can win and retain ownership through legal tactical actions")
 test.check(c.s.squads.first.sector==1,"Remote company location is unchanged by garrison combat")
 test.check(not c.s.sectors[17].battlefield.ground.is_empty(),"Garrison-only victory leaves loot on site for later company recovery")
 # Tactical death changes garrison numbers, not a decorative counter.
 c=defence(true,2)
 b=c.battle
 cell=c.s.sectors[17]
 levy=cell.levies[0]
 var dead_ids=[]
 for entry in levy.inventory: dead_ids.append(entry.id)
 unit=b.unit(levy.id)
 var enemy=test.enemy(b)
 unit.x=9;unit.y=2;unit.ap=0;unit.person.hp=1;unit.person.morale=0
 enemy.x=10;enemy.y=2;enemy.ap=26;enemy.person.melee=100
 c.s.rng=1
 b.t.turn="enemy"
 b.refresh_knowledge()
 test.check(b.attack(enemy,unit) and unit.person.hp==0 and Garrison.strength(cell)==1,"Legal enemy attack creates a persistent levy casualty")
 test.check(levy.inventory.is_empty() and b.t.ground.size()==dead_ids.size(),"Fallen levy equipment becomes real ground loot once")
 b.t.turn="company"
 test.check(c.command("retreat") and c.s.squads.first.sector!=17 and not c.s.encounter.is_empty(),"Withdrawing mercenaries leave surviving levies to continue the defence")
 c.command("enter")
 c.command("confirm_deployment")
 test.check(c.battle.unit(levy.id)==null and c.battle.t.squads.is_empty() and Garrison.strength(cell)==1,"Follow-on garrison defence preserves its casualty without redeploying withdrawn squads")
 # A defeated garrison loses control and cannot respawn captured defenders.
 c=defence(false,1)
 b=c.battle
 for u in b.t.units:
  if u.team=="company": u.person.hp=8
 test.check(b.outcome()=="defeat" and c.command("resolve") and c.s.sectors[17].owner=="bandits","Incapacitated garrison defeat transfers sector control to the actual attacking faction")
 test.check(c.s.sectors[17].levies[0].captured and Garrison.strength(c.s.sectors[17])==0,"Defeated surviving levies are captured and stop defending")
 # Training, local recovery, upkeep and recruitment caps are all real.
 c=quiet()
 c.command("levy",{"sector":17})
 cell=c.s.sectors[17]
 levy=cell.levies[0]
 var melee=levy.melee
 Garrison.train(cell,20)
 test.check(levy.melee==melee+2 and levy.ranged==41,"Garrison training improves the existing defender's combat skills")
 levy.hp=40;levy.bleeding=2
 c.command("supply_transfer",{"from":"first","to":"sector:17","resource":"medicine","amount":1})
 c.command("advance",{"minutes":60})
 test.check(levy.hp==43 and levy.bleeding==0 and cell.supplies.medicine==0,"Wounded levy recovery uses local medical skill and spends a local medical supply")
 var funds=c.s.funds
 c.daily()
 test.check(c.s.funds==funds-43,"Living local levies incur upkeep alongside mercenary wages")
 c.s.funds=10000
 while Garrison.living(cell)<12: c.command("levy",{"sector":17})
 funds=c.s.funds
 test.check(not c.command("levy",{"sector":17}) and c.s.funds==funds,"Garrison recruitment cap rejects before charging funds")
 var invalid=c.s.duplicate(true)
 invalid.next_levy=1
 test.check(not c.valid_save(invalid),"Save validation rejects reused levy IDs")
 invalid=c.s.duplicate(true)
 invalid.squads.first.supplies.food=-1
 test.check(not c.valid_save(invalid),"Save validation rejects negative provisions")
 invalid=c.s.duplicate(true)
 invalid.squads.first.supplies.medicine=0.5
 test.check(not c.valid_save(invalid),"Save validation rejects fractional medical supplies")
 # Migrate actual previous-release records, conserving the old global pool.
 c=Campaign.new()
 test.check(c.load_from("res://tests/fixtures/schema2-strategic.json") and c.s.version==3,"Actual schema-2 split-company save migrates to schema 3")
 test.check(total(c.s,"food")==60 and total(c.s,"medicine")==12 and total(c.s,"tools")==12,"Migration conserves the full previous global supply pool")
 test.check(c.s.squads.first.supplies.food==30 and c.s.squads.squad_oswin.supplies.food==30,"Migration allocates provisions proportionally to existing squads")
 test.check(Garrison.strength(c.s.sectors[17])==1 and c.s.sectors[17].levies[0].melee==49,"Migration creates one persistent trained levy for each old garrison member")
 test.check(c.save_to("user://migrated-logistics.json") and loaded.load_from("user://migrated-logistics.json") and JSON.stringify(loaded.s)==JSON.stringify(c.s),"Migrated provisions and levy identities roundtrip without duplication")
 test.check(c.load_from("res://tests/fixtures/schema2-tactical.json") and c.battle.unit("mara").x==4,"Actual schema-2 active battle resumes without redeploying or resetting positions")
 test.check(c.battle.t.squads==["first"] and Supplies.for_person(c.s,"mara").food>0,"Migrated active units receive the correct squad supply context")
 c=quiet()
 c.command("levy",{"sector":17})
 c.s.squads.first.sector=1
 levy=c.s.sectors[17].levies[0]
 levy.hp=8;levy.bleeding=2
 c.s.sectors[17].supplies.medicine=1
 c.command("advance",{"minutes":60})
 test.check(levy.hp==6 and c.s.sectors[17].supplies.medicine==1,"An isolated unconscious levy cannot treat itself using a remote doctor")
 c=quiet()
 c.s.squads.first.supplies={"food":101,"medicine":7,"tools":5}
 c.command("split",{"id":"oswin"})
 test.check(c.s.squads.first.supplies=={"food":51,"medicine":4,"tools":3} and c.s.squads.squad_oswin.supplies=={"food":50,"medicine":3,"tools":2},"Odd split remainders stay with the source squad without loss")
 c=defence(true,0)
 var captured_pack=c.s.squads.first.supplies.duplicate()
 var depot=c.s.sectors[17].supplies.duplicate()
 for u in c.battle.t.units:
  if u.team=="company": u.person.hp=8
 test.check(c.command("resolve") and c.s.squads.first.members.is_empty(),"Defeated company survivors are captured instead of escaping without a capable escort")
 test.check(c.s.squads.first.supplies==Supplies.empty() and c.s.sectors[17].supplies.food==captured_pack.food+depot.food and c.s.sectors[17].supplies.tools==captured_pack.tools+depot.tools,"Defeated squad packs remain at the lost sector rather than teleporting to safety")
 c=quiet()
 c.command("levy",{"sector":17})
 var pack_food=c.s.squads.first.supplies.food
 c.command("advance",{"minutes":60})
 test.check(c.s.sectors[17].levies[0].morale==65 and c.s.squads.first.supplies.food==pack_food-2,"Unstocked levies suffer shortage without consuming a co-located squad's pack")
 var legacy=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/schema2-strategic.json"))
 for squad in legacy.squads.values(): squad.members=[]
 for p in legacy.mercs.values(): p.hired=false
 var f=FileAccess.open("user://empty-squad-legacy.json",FileAccess.WRITE)
 f.store_string(JSON.stringify(legacy));f.close()
 test.check(c.load_from("user://empty-squad-legacy.json") and c.s.sectors[17].supplies.food==60 and total(c.s,"food")==60,"Migration with no staffed squads puts the whole legacy pool in the base depot")
 # Old active battles deployed only their primary squad. A reserve omitted from
 # that transient roster must get the next engagement rather than disappearing.
 c=defence(true,0,true)
 b=c.battle
 b.t.units.erase(b.unit("oswin"))
 b.t.squads.erase("squad_oswin")
 b.unit("mara").person.hp=8
 test.check(c.command("resolve") and c.s.sectors[17].owner=="company" and not c.s.encounter.is_empty(),"An undeployed legacy reserve preserves the defence when the primary squad falls")
 c.command("enter")
 c.command("confirm_deployment")
 test.check(c.battle.unit("oswin")!=null and c.battle.unit("mara")==null,"Surviving reserve deploys in the follow-on engagement without resurrecting captured troops")
