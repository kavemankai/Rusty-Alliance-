extends SceneTree
const Campaign=preload("res://sim/campaign.gd")
const Data=preload("res://sim/catalog.gd")
const Skills=Data.Skills
const Recruitment=Campaign.Recruitment
const Field=preload("res://tests/exploration_cases.gd")
var passed=0
var failures=[]
func _init() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
 if ok: passed+=1
 else: failures.append(message);print("FAIL: "+message)

# Synthetic data for mechanics tests ONLY. Never used as the workshop roster.
static func synthetic_roster() -> Array:
 var rows=[]
 for tier in ["cheap","mid","high","elite"]:
  for i in range({"cheap":2,"mid":4,"high":4,"elite":2}[tier]):
   var row={"id":"test_"+tier+str(i),"name":"Test "+tier+str(i),"tier":tier,"repeatable":tier=="cheap","background":"soldier","weapon":"sword","fee":{"cheap":50,"mid":400,"high":900,"elite":3000}[tier],"wage":{"cheap":5,"mid":15,"high":30,"elite":60}[tier],"attributes":{},"skills":{}}
   for key in Skills.ATTRIBUTES: row.attributes[key]=55
   for key in Skills.ALL: row.skills[key]=30 if tier=="cheap" else 60
   rows.append(row)
 return rows

func write(path: String,data: Dictionary) -> void:
 for suffix in [".bak",".tmp",".bak.tmp"]:
  if FileAccess.file_exists(path+suffix): DirAccess.remove_absolute(ProjectSettings.globalize_path(path+suffix))
 var f=FileAccess.open(path,FileAccess.WRITE);f.store_string(JSON.stringify(data));f.close()

func run() -> void:
 var original=Campaign.new();original.autosave_path="user://skills-original-auto.json"
 check(original.s.funds==1200 and original.s.squads.first.members==["mara","oswin"] and original.s.mercs.mara.name=="Mara" and original.s.mercs.oswin.name=="Oswin","Original purse, named identities and starting company preserved")
 for p in original.s.mercs.values():
  check(p.has_all(Skills.ATTRIBUTES) and p.has_all(Skills.ALL),"Seven attributes/seven skills: "+p.id)
 var base=JSON.stringify(original.s)
 check(not original.configure_new_greywake([]) and JSON.stringify(original.s)==base,"Missing roster never silently replaces original campaign")
 check(not original.command("recruit_template",{"template":"test_cheap0"}) and JSON.stringify(original.s)==base,"Repeatable recruitment cannot leak into original campaign")
 for fixture in ["legacy-strategic","legacy-tactical","legacy-corpse","schema2-strategic","schema2-tactical"]:
  var restored=Campaign.new()
  check(restored.load_from("res://tests/fixtures/"+fixture+".json"),"Old save loads: "+fixture)
  for p in restored.s.mercs.values(): check(Skills.valid(p,true),"Old save gains valid neutral skills: "+fixture+"/"+p.id)
 var legacy=JSON.parse_string(base)
 legacy.mercs.mara.kills=2;legacy.mercs.mara.inventory[0].condition=61
 for p in legacy.mercs.values():
  for key in Skills.ADDED+["training_bank","training_skill","trained_hour"]: p.erase(key)
 for group in legacy.groups:
  for p in group.fighters:
   for key in Skills.ADDED+["training_bank","training_skill","trained_hour"]: p.erase(key)
 write("user://skills-legacy.json",legacy)
 var migrated=Campaign.new()
 check(migrated.load_from("user://skills-legacy.json") and migrated.s.mercs.mara.stealth==40 and migrated.s.mercs.mara.kills==2 and migrated.s.mercs.mara.inventory[0].condition==61,"Schema-3 normalization preserves history and equipment while adding neutral skills")
 for key in Skills.ADDED:
  for bad in [-1,101,2.5,"60",null,{},INF]:
   var corrupt=original.s.duplicate(true);corrupt.mercs.mara[key]=bad
   check(not original.valid_save(corrupt),"Reject malformed "+key+": "+str(bad))
 var rows=synthetic_roster()
 check(Recruitment.valid_templates(rows),"Synthetic test schema has two repeatable cheap and ten unique named templates")
 var wrong=rows.duplicate(true);wrong[-1].fee=2400
 check(not Recruitment.valid_templates(wrong),"Elite hiring fee must exceed opening purse")
 wrong=rows.duplicate(true);wrong[3].name=wrong[2].name
 check(not Recruitment.valid_templates(wrong),"Duplicate named roster identities rejected")
 var c=Campaign.new();c.autosave_path="user://skills-greywake-auto.json"
 check(c.configure_new_greywake(rows) and c.s.funds==2400 and c.s.mercs.size()==10 and c.s.squads.first.members.is_empty(),"Separate Greywake start has a 2,400 purse and lets the player choose a company")
 check(original.s.squads.first.members==["mara","oswin"] and original.s.mercs.size()==6,"Creating Greywake does not mutate another original campaign")
 var before=JSON.stringify(c.s)
 check(not c.command("hire",{"id":"greywake-named-test_elite0"}) and JSON.stringify(c.s)==before,"Unaffordable Elite rejection leaves money, profiles, items and events unchanged")
 check(c.command("recruit_template",{"template":"test_cheap0"}) and c.command("recruit_template",{"template":"test_cheap0"}),"Cheap archetype can generate multiple individuals")
 var a=c.s.mercs[c.s.squads.first.members[0]];var z=c.s.mercs[c.s.squads.first.members[1]]
 check(a.id!=z.id and a.name!=z.name and a.inventory[0].id!=z.inventory[0].id and c.s.funds==2300,"Cheap recruits have unique persistent names, person IDs and item IDs; each fee is charged once")
 for key in Skills.ATTRIBUTES+Skills.ALL: check(a[key]==z[key],"Cheap template stats initially identical: "+key)
 a.stealth+=1;a.inventory[0].condition=50;a.kills=3;a.experience=2
 check(z.stealth==30 and z.inventory[0].condition==100 and z.kills==0 and z.experience==1,"Recruit skills, items and experience are independently owned")
 check(c.command("hire",{"id":"greywake-named-test_mid0"}),"Player can choose a named starting mercenary")
 before=JSON.stringify(c.s)
 check(not c.command("hire",{"id":"greywake-named-test_mid0"}) and JSON.stringify(c.s)==before,"Named hire cannot duplicate a person or charge again")
 check(c.valid_save(c.s) and c.save_to("user://skills-greywake.json"),"Greywake recruitment state and unique ownership validate/save")
 var loaded=Campaign.new()
 check(loaded.load_from("user://skills-greywake.json") and JSON.stringify(loaded.s)==JSON.stringify(c.s),"Greywake identities, equipment, skills, counters and history survive exact reload")
 check(loaded.command("recruit_template",{"template":"test_cheap0"}) and loaded.s.mercs.size()==13,"Recruit serial continues after reload without replacing previous individuals")
 before=JSON.stringify(loaded.s);loaded.s.funds=0;var broke=JSON.stringify(loaded.s)
 check(not loaded.command("recruit_template",{"template":"test_cheap0"}) and JSON.stringify(loaded.s)==broke,"Rejected cheap recruitment grants no money, item, ID or unit")
 check(not c.configure_new_greywake(rows),"Active Greywake cannot be restarted to duplicate opening money")
 var isolated=Campaign.new();isolated.configure_new_greywake(rows)
 check(isolated.autosave_path=="user://greywake-autosave.json" and original.autosave_path=="user://skills-original-auto.json","Scenario autosaves cannot silently overwrite the original campaign")
 check(isolated.default_save_path()=="user://greywake.json" and original.default_save_path()=="user://campaign.json","Default save/load commands also keep scenario files separate")
 before=JSON.stringify(original.s)
 check(not original.command("assignment",{}) and JSON.stringify(original.s)==before,"Missing assignment arguments cannot grant progress or mutate state")
 check(not original.command("recruit_template",{"template":{}}) and JSON.stringify(original.s)==before,"Malformed recruitment arguments are rejected safely")
 var corrupt=c.s.duplicate(true);corrupt.recruitment.next_id=1
 check(not c.valid_save(corrupt),"Saved recruit identity counter cannot roll back over existing individuals")
 var renewal=Campaign.new();renewal.s.groups=[];renewal.s.squads.first.supplies.food=10000
 var funds=renewal.s.funds
 renewal.command("renew",{"id":"mara"});renewal.command("advance",{"minutes":960})
 check(renewal.s.funds==funds-140-40,"Renewal audit preserves existing 140 upfront plus 40 daily company payroll accounting")
 var training=Campaign.new();training.s.groups=[];training.s.squads.first.supplies.food=10000
 var trainee=training.s.mercs.mara
 var xp=trainee.experience
 for key in Skills.ALL:
  trainee[key]=50
  check(training.command("assignment",{"id":"mara","value":"training","skill":key}),"Select training: "+key)
  var progress=trainee.training
  for repeat in range(20): training.command("assignment",{"id":"mara","value":"training","skill":key})
  check(trainee[key]==50 and trainee.training==progress and trainee.experience==xp,"Free repeated assignment never grants skill or XP: "+key)
  check(training.command("advance",{"minutes":360}) and trainee[key]==51,"Paid simulation time trains selected skill: "+key)
 check(trainee.experience==xp and training.valid_save(training.s),"Selected-skill training preserves experience and valid owned state")
 var progress=trainee.training;before=JSON.stringify(training.s)
 check(not training.command("assignment",{"id":"mara","value":"training","skill":"sword"}) and JSON.stringify(training.s)==before,"Weapon-specific skill trees are rejected without changes")
 check(not Skills.train(trainee,int(training.s.time/60),false) and trainee.training==progress,"One simulation hour cannot be rewarded twice")
 for flag in ["dead","captured"]:
  var unavailable=trainee.duplicate(true);unavailable[flag]=true
  check(not Skills.train(unavailable,int(training.s.time/60)+1,false),"Unavailable characters cannot receive training: "+flag)
 for high in [false,true]:
  var scout=Campaign.new();scout.s.groups=[];scout.s.mercs.mara.perception=0
  scout.s.mercs.mara.fieldcraft=80 if high else 40
  scout.command("assignment",{"id":"mara","value":"scout"});scout.command("advance",{"minutes":60})
  check(scout.s.sectors[0].known==high,"Fieldcraft scouting grants only paid terrain discovery at extended range: "+str(high))
 var encounter=Field.field();var b=encounter.battle;var u=b.unit("mara");var enemy=b.t.units.filter(func(p):return p.team=="enemy")[0]
 b.t.phase="combat";b.t.night=false;u.x=6;u.y=4;u.stance="crouch";u.mode="cautious";enemy.x=10;enemy.y=4;enemy.facing=4;enemy.person.perception=0
 b.tile(u.x,u.y).conceal=10;u.person.stealth=40
 check(b.visible(enemy,u),"Neutral stealth preserves baseline concealed visibility")
 u.person.stealth=100
 check(not b.visible(enemy,u),"High stealth reduces actual detection in concealment")
 u.mode="run"
 check(b.visible(enemy,u),"Running forfeits the concealment stealth benefit")
 u.mode="cautious";b.tile(u.x,u.y).conceal=0
 check(b.visible(enemy,u),"Stealth cannot hide a unit in open terrain")
 b.tile(u.x,u.y).conceal=10
 b.refresh_knowledge()
 check(not b.known("enemy",u.id),"Hidden high-stealth fighter is absent from enemy team knowledge")
 check(not enemy.get("memory",{}).has(u.id),"AI receives no actual coordinates for a never-detected fighter")
 for high in [false,true]:
  var field=Field.field();var board=field.battle;var actor=board.unit("mara")
  board.t.phase="combat";board.t.turn="company";board.t.layout="wilderness"
  actor.x=0;actor.y=2;actor.ap=26;actor.person.fieldcraft=90 if high else 40
  board.tile(1,2).kind="brush";board.tile(1,2).cost=4;board.refresh_knowledge()
  var preview=board.path(actor,1,2,true);var cost=preview.cost
  check(cost==(2 if high else 4),"Fieldcraft changes eligible wilderness AP preview: "+str(high))
  check(board.path_heap(actor,1,2,true).cost==board.path_reference(actor,1,2,true).cost,"Both path solvers share skill-aware movement cost")
  check(board.move(actor,1,2) and actor.ap==26-cost,"Skill-aware execution spends previewed AP exactly")
  check(Skills.wilderness_cost(actor.person,{"kind":"road"},4,"wilderness")==4 and Skills.wilderness_cost(actor.person,{"kind":"brush"},4,"settlement")==4,"Fieldcraft cannot discount roads or urban movement")
  check(Skills.wilderness_cost(actor.person,{"kind":"unknown"},2,"wilderness")==2,"Unknown-ground preview cannot expose a hidden skill discount")
 for high in [false,true]:
  var field=Field.field();var board=field.battle;var actor=board.unit("mara")
  board.t.phase="combat";board.t.turn="company";actor.x=0;actor.y=2;actor.ap=26;actor.mode="run"
  actor.person.endurance=20;actor.person.athletics=100 if high else 40;actor.person.fatigue=0
  check(board.move(actor,1,2) and actor.person.fatigue==(1 if high else 4),"Athletics changes actual paid running fatigue: "+str(high))
  actor.mode="walk";actor.ap=26
  var price=board.Combat.risk(board,actor,2,2).disengage_ap
  check(price==(4 if high else 6),"Athletics changes controlled withdrawal preview: "+str(high))
  check(board.action(actor.id,"disengage",{"x":2,"y":2}) and actor.ap==26-price,"Withdrawal uses the same skill-aware AP charge")
  check(Skills.withdrawal_fatigue(actor.person)==(4 if high else 10),"Athletics affects strategic withdrawal fatigue")
  var exploring=Field.field();var walking=exploring.battle.unit("mara")
  exploring.command("confirm_deployment",{"explore":true})
  walking.mode="run";walking.person.endurance=20;walking.person.athletics=100 if high else 40;walking.person.fatigue=0
  var prior_experience=walking.person.experience
  check(exploring.battle.move(walking,1,2) and walking.person.fatigue==(1 if high else 4),"Exploration and combat use the same athletics fatigue rule")
  check(walking.person.experience==prior_experience,"Exploration movement cannot farm experience")
 var first=Field.field();first.command("confirm_deployment")
 for fighter in first.battle.t.units:
  for key in Skills.ADDED: fighter.person[key]=90
 var actor=first.battle.unit("mara");var rng=first.s.rng;var kills=actor.person.kills;var experience=actor.person.experience
 for repeat in range(20): first.battle.attack(actor,actor)
 check(first.s.rng==rng and actor.person.kills==kills and actor.person.experience==experience,"Invalid repeated attacks cannot generate kills, experience or random rolls")
 check(first.save_to("user://skills-ai.json"),"High-skill tactical state validates and saves")
 var replay=Campaign.new();check(replay.load_from("user://skills-ai.json"),"High-skill tactical state reloads")
 check(first.battle.end_turn() and replay.battle.end_turn(),"Tactical AI executes with the new skills in both instances")
 var results=[]
 for campaign in [first,replay]:
  var values=[]
  for fighter in campaign.battle.t.units: values.append([fighter.id,fighter.x,fighter.y,fighter.ap,fighter.person.hp,fighter.person.experience])
  results.append({"rng":campaign.s.rng,"units":values})
 check(results[0]==results[1],"High-skill AI replay preserves deterministic positions, AP, health, experience and RNG")
 var hidden=Field.field();var hidden_board=hidden.battle;var explorer=hidden_board.unit("mara")
 hidden_board.t.phase="combat";explorer.x=0;explorer.y=2;explorer.person.fieldcraft=100
 var key=str(2*int(hidden_board.t.width)+1)
 hidden_board.t.fog.company.erase(key);hidden_board.t.sight.company.erase(key)
 hidden_board.tile(1,2).kind="brush";hidden_board.tile(1,2).cost=8
 var estimate=hidden_board.Combat.risk(hidden_board,explorer,1,2).disengage_ap
 check(estimate==6,"Withdrawal preview uses provisional unknown terrain rather than hidden Fieldcraft cost")
 hidden_board.tile(1,2).block=true
 check(hidden_board.Combat.risk(hidden_board,explorer,1,2).disengage_ap==estimate,"Hidden blocker changes cannot leak through the withdrawal AP preview")
 var report={"passed":passed,"failed":failures.size(),"failures":failures,"roster_source":"legacy infrastructure fixture; production baseline tested in tests/greywake.gd"}
 var file=FileAccess.open("res://skills-test-results.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close()
 print("SKILLS: "+JSON.stringify(report));quit(0 if failures.is_empty() else 1)
