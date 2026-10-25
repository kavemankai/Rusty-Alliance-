extends RefCounted
const Campaign=preload("res://sim/campaign.gd")
const Data=preload("res://sim/catalog.gd")
const Field=preload("res://tests/exploration_cases.gd")

static func setup(test):
 var c=Field.field();c.autosave_path="user://melee-test-autosave.json"
 c.command("confirm_deployment")
 var b=c.battle;var a=b.unit("mara");var e=b.unit(c.s.groups[0].fighters[0].id)
 a.x=6;a.y=2;e.x=7;e.y=2;a.person.melee=100;e.person.agility=0;e.person.melee=0
 a.person.perception=100;e.person.perception=100;a.ap=26;e.ap=0;e.person.hp=200;e.person.max_hp=200
 test.loadout(e.person,"body","clothing")
 b.refresh_knowledge();c.s.rng=1
 return c

static func run(test) -> void:
 var c=setup(test);var b=c.battle;var a=b.unit("mara");var e=b.unit(c.s.groups[0].fighters[0].id)
 var ap=a.ap
 test.check(b.action(a.id,"attack_style",{"value":"power"}) and b.Combat.cost(a)==7,"Power strike has a real two-AP surcharge")
 test.check(b.action(a.id,"aim_location",{"value":"legs"}) and b.Combat.cost(a)==8,"Selecting a body target adds AP and an accuracy tradeoff")
 test.check(b.attack(a,e) and a.ap==ap-8 and not e.person.injuries.is_empty() and e.person.injuries[-1].location=="legs","Actual aimed power hit records the selected body injury and spends preview AP")
 var leg_penalty=Data.injury(e.person,"legs")
 e.person.hp=e.person.max_hp
 var impaired=Data.ap(e.person);var injuries=e.person.injuries.duplicate(true)
 e.person.injuries=[]
 test.check(leg_penalty>0 and Data.ap(e.person)>impaired,"Leg injury severity continues reducing AP even after HP is restored")
 e.person.injuries=injuries
 Data.treat(e.person,85)
 test.check(Data.injury(e.person,"legs")<leg_penalty,"Skilled treatment reduces persistent localized injury severity")
 var snapshot=JSON.stringify(c.s)
 test.check(not b.action(a.id,"attack_style",{"value":"invalid"}) and not b.action(a.id,"aim_location",{"value":"wings"}) and JSON.stringify(c.s)==snapshot,"Invalid attack/target choices reject without spending resources")
 c=setup(test);b=c.battle;a=b.unit("mara");e=b.unit(c.s.groups[0].fighters[0].id)
 test.loadout(e.person,"weapon","sword")
 e.guard=true;e.ap=26;a.facing=4
 var preview=b.Combat.risk(b,a,5,2)
 test.check(preview.threats.has(e.id) and preview.disengage_ap==6,"Withdrawal preview names perceived armed reaction threats and exact deliberate cost")
 var old_hp=a.person.hp;ap=a.ap;var enemy_ap=e.ap
 test.check(b.action(a.id,"disengage",{"x":5,"y":2}) and a.x==5 and a.ap==ap-6 and e.ap==enemy_ap and a.person.hp==old_hp,"Deliberate one-step disengagement avoids melee opportunities while paying extra AP")
 a.ap=1;snapshot=JSON.stringify(c.s)
 test.check(not b.action(a.id,"disengage",{"x":4,"y":2}) and JSON.stringify(c.s)==snapshot,"Insufficient-AP disengagement rejects atomically")
 c=setup(test);b=c.battle;a=b.unit("mara");e=b.unit(c.s.groups[0].fighters[0].id)
 test.check(b.action(a.id,"defence_mode",{"value":"shield"}) and a.ap==24,"Shield-focused defence is an actual paid combat choice")
 test.check(b.Combat.defence_bonus(a,"shield")==15 and b.Combat.defence_bonus(a,"parry")==0,"Defensive specialization boosts its selected response only")
 var shield=Data.equipped(a.person,"shield");shield.condition=0
 test.check(not Data.shield(a.person) and not b.action(a.id,"defence_mode",{"value":"shield"}),"Broken shields no longer function or permit shield-focused defence")
 a.ap=3;a.activated=true
 var base=Data.ap(a.person)
 b.start_turn("company")
 test.check(a.ap==mini(26,base+3),"Next activated turn carries at most four actual unused AP")
 a.ap=26;a.activated=false;b.start_turn("company")
 test.check(a.ap==Data.ap(a.person),"A unit's first activation receives no unearned carryover")
 test.loadout(a.person,"weapon","crossbow")
 for item in a.person.inventory:
  if item.kind=="ammo": item.ammo_type="arrows"
 a.person.loaded=false;a.ap=26;snapshot=JSON.stringify(c.s)
 test.check(Data.ammo(a.person)==0 and not b.action(a.id,"reload") and JSON.stringify(c.s)==snapshot,"Crossbows cannot reload with arrows or spend AP on incompatible ammunition")
 for item in a.person.inventory:
  if item.kind=="ammo": item.ammo_type="bolts"
 test.check(b.action(a.id,"reload") and a.person.loaded and a.ap==19,"Matching bolts reload with the crossbow's actual seven-AP cost")
 c=Campaign.new();c.autosave_path="user://melee-test-autosave.json"
 test.check(c.command("buy",{"item":"bolts"}) and c.s.stash[-1].ammo_type=="bolts" and c.s.stash[-1].quantity==16,"Market purchases create explicitly typed projectile stacks")
 c=setup(test);b=c.battle;a=b.unit("mara");e=b.unit(c.s.groups[0].fighters[0].id)
 var dagger=c.Items.create(c.s,"dagger");a.person.inventory.append(dagger)
 ap=a.ap
 test.check(b.action(a.id,"throw",{"item":dagger.id,"target":e.id}) and a.ap==ap-6 and c.Items.find(a.person.inventory,dagger.id).is_empty() and b.t.ground[-1].item.id==dagger.id,"A thrown dagger leaves its actual inventory owner and becomes recoverable ground equipment")
 test.check(c.Items.ownership_error(c.s)=="","Throwing preserves unique item ownership")
 test.check(c.save_to("user://melee-combat.json"),"Injuries, combat choices, ammunition types and thrown equipment save")
 var loaded=Campaign.new()
 test.check(loaded.load_from("user://melee-combat.json") and loaded.battle.t.ground[-1].item.id==dagger.id,"Thrown equipment survives active-combat reload")
 var bad=c.s.duplicate(true)
 bad.mercs.mara.injuries=[{"location":"legs","severity":-1,"treated":false}]
 test.check(not c.valid_save(bad),"Invalid localized injury severity is rejected before loading")

 c=setup(test);b=c.battle;a=b.unit("mara");e=b.unit(c.s.groups[0].fighters[0].id)
 a.ap=26;a.activated=true;b.start_turn("company")
 test.check(a.ap==mini(26,Data.ap(a.person)+4),"Carryover is capped at four AP rather than accumulating a full unused turn")
 a.ap=26;e.x=10;e.y=2;b.refresh_knowledge();var before_x=a.x
 test.check(b.action(a.id,"charge",{"target":e.id}) and a.x==9 and a.ap==13,"Charge pays the real approach steps and a seven-AP power strike")
 c=setup(test);b=c.battle;a=b.unit("mara");e=b.unit(c.s.groups[0].fighters[0].id)
 c.s.rng=1;var shield_before=Data.equipped(a.person,"shield").condition
 test.check(b.action(a.id,"bash",{"target":e.id}) and e.x==8 and a.ap==21 and Data.equipped(a.person,"shield").condition==shield_before-2,"Shield bash spends AP/condition, deals a real hit and displaces a surviving opponent into a free cell")
 test.check(e.person.bleeding==0,"A blunt shield bash does not create cutting bleed")
 c=setup(test);b=c.battle;a=b.unit("mara");e=b.unit(c.s.groups[0].fighters[0].id)
 var ally=b.unit("oswin");ally.x=6;ally.y=3;ally.ap=0;ally.person.agility=0
 a.person.perception=100;a.facing=0;e.x=9;e.y=3;e.person.ranged=100;e.ap=26
 test.loadout(e.person,"weapon","bow");e.person.loaded=true;b.t.turn="company";b.refresh_knowledge()
 test.check(b.action(a.id,"protect",{"target":ally.id}) and a.ap==23 and a.protecting==ally.id,"Shield protection reserves an adjacent ally with a real initial AP cost")
 b.t.turn="enemy";c.s.rng=1
 var protected_hp=ally.person.hp
 test.check(b.attack(e,ally) and a.ap==20 and Data.equipped(a.person,"shield").condition==96 and ally.person.hp<protected_hp,"A guardian spends additional AP and shield durability when intercepting an actual incoming hit")
 test.check(b.t.log.any(func(text):return "intercepted" in text),"Interception is explicitly reported in combat feedback")
 b.start_turn("company")
 test.check(a.protecting=="","Protection expires on the guardian's next activation")
 var defender={"person":Data.person("defender","Defender","soldier","sword"),"defence_mode":"parry"}
 a.attack_style="normal";var parry=b.Combat.parry_chance(a,defender)
 a.attack_style="feint"
 test.check(b.Combat.parry_chance(a,defender)<parry,"Feints trade damage/AP for a reduced opposing parry chance")
 c=setup(test);b=c.battle;a=b.unit("mara");e=b.unit(c.s.groups[0].fighters[0].id)
 a.person.melee=50
 var before_chance=b.hit_chance(a,e)
 a.person.injuries=[{"location":"arms","severity":3,"treated":false}]
 test.check(b.hit_chance(a,e)<before_chance,"Arm injury severity reduces actual hit probability")
 a.person.injuries=[{"location":"head","severity":4,"treated":false}]
 var injured_ap=Data.ap(a.person);a.person.injuries=[]
 test.check(Data.ap(a.person)>injured_ap,"Head injury severity reduces available action points")
