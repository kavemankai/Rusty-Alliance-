extends RefCounted
const Data=preload("res://sim/catalog.gd")
const R=preload("res://sim/records.gd")
const FILE="res://data/greywake_opening.json"
const STAGES=["EMPLOYER_BRIEFING","TAVERN_RECRUITMENT","COMPANY_CONFIRMATION","BOAT_CROSSING","GREYWAKE_ARRIVAL","DOCKSIDE_CONTRACT","FIRST_TACTICAL_ENCOUNTER","GREYWAKE_CAMPAIGN"]
const PRE_GAME=["EMPLOYER_BRIEFING","TAVERN_RECRUITMENT","COMPANY_CONFIRMATION","BOAT_CROSSING","GREYWAKE_ARRIVAL","DOCKSIDE_CONTRACT"]
static func content() -> Dictionary: return JSON.parse_string(FileAccess.get_file_as_string(FILE))
static func applies(s: Dictionary) -> bool: return s.get("scenario")=="fall_of_greywake" and s.has("opening_flow")
static func stage(s: Dictionary) -> String: return s.get("opening_flow",{}).get("stage","")
static func locked(s: Dictionary) -> bool: return stage(s) in PRE_GAME
static func initialize(c,at: String="EMPLOYER_BRIEFING") -> void:
 c.s.opening_flow={"version":1,"stage":at,"dialogue_index":0,"tutorial_dismissed":false,"tutorial_flags":{},"outcome":"","migrated_staging":false}
 if c.s.greywake.get("world_mode")=="island_v1": seed_encounter(c)
static func permits(s: Dictionary,kind: String) -> bool:
 if not locked(s): return true
 if kind in ["save","load","opening_next","opening_skip","opening_back","opening_confirm","opening_depart"]: return true
 return stage(s)=="TAVERN_RECRUITMENT" and kind in ["hire","recruit_template","cancel_opening_hire"]
static func run(c,kind: String) -> bool:
 if not applies(c.s): return c.reject("No active Greywake opening")
 var f=c.s.opening_flow
 match kind:
  "opening_skip":
   if f.stage=="EMPLOYER_BRIEFING": f.stage="TAVERN_RECRUITMENT";f.dialogue_index=content().briefing.size()-1
   elif f.stage=="BOAT_CROSSING": f.stage="GREYWAKE_ARRIVAL"
   else: return c.reject("This scene cannot be skipped")
  "opening_next":
   match f.stage:
    "EMPLOYER_BRIEFING":
     if f.dialogue_index<content().briefing.size()-1: f.dialogue_index+=1
     else: f.stage="TAVERN_RECRUITMENT"
    "BOAT_CROSSING": f.stage="GREYWAKE_ARRIVAL"
    "GREYWAKE_ARRIVAL": f.stage="DOCKSIDE_CONTRACT"
    "DOCKSIDE_CONTRACT": f.stage="GREYWAKE_CAMPAIGN"
    _: return c.reject("Choose the relevant opening action")
  "opening_confirm":
   if f.stage!="TAVERN_RECRUITMENT" or c.s.squads.first.members.size()<2 or c.s.squads.first.members.size()>6: return c.reject("Choose two to six mercenaries")
   f.stage="COMPANY_CONFIRMATION"
  "opening_back":
   if f.stage!="COMPANY_CONFIRMATION": return c.reject("Return to the tavern before departure")
   f.stage="TAVERN_RECRUITMENT"
  "opening_depart":
   if f.stage!="COMPANY_CONFIRMATION": return c.reject("Confirm your selected company first")
   if not c.embark_greywake(): return false
   f.stage="BOAT_CROSSING"
  "dockside_start": return start_encounter(c)
  "tutorial_next":
   var key=lesson(c.s,c.battle)
   if key!="": f.tutorial_flags[key]=true
  "tutorial_dismiss": f.tutorial_dismissed=true
  _: return c.reject("Unknown opening action")
 return true
static func valid(s: Dictionary) -> bool:
 if not s.has("opening_flow"): return s.get("greywake",{}).get("world_mode")!="island_v1"
 if s.get("scenario")!="fall_of_greywake": return false
 var f=s.opening_flow
 if not f is Dictionary or f.get("version")!=1 or f.get("stage") not in STAGES: return false
 if not R.integer(f.get("dialogue_index"),0,content().briefing.size()-1) or not f.get("tutorial_dismissed") is bool or not f.get("tutorial_flags") is Dictionary or not f.get("migrated_staging") is bool: return false
 if f.get("outcome") not in ["","victory","retreat","defeat"]: return false
 for key in f.tutorial_flags:
  if key not in ["select","move","ap","attack","chance","turn","defence","resolve"] or not f.tutorial_flags[key] is bool: return false
 if s.greywake.get("world_mode")=="island_v1":
  var jobs=s.jobs.filter(func(j):return j.id==INTRO_JOB)
  var groups=s.groups.filter(func(g):return g.id=="greywake-dockside-bandits")
  if jobs.size()!=1 or groups.size()!=1 or jobs[0].reward!=int(JSON.parse_string(FileAccess.get_file_as_string(DOCKSIDE_FILE)).reward) or jobs[0].target!=groups[0].id or groups[0].fighters.size()!=2: return false
  if f.stage=="FIRST_TACTICAL_ENCOUNTER" and s.encounter.is_empty(): return false
 var hiring=f.stage in ["EMPLOYER_BRIEFING","TAVERN_RECRUITMENT","COMPANY_CONFIRMATION"]
 if (s.opening_voyage.phase=="hiring")!=hiring: return false
 if locked(s) and (s.time!=480 or not s.battle.is_empty() or not s.encounter.is_empty()): return false
 if locked(s) and (s.squads.size()!=1 or not s.squads.has("first") or s.squads.first.sector!=17 or not s.squads.first.route.is_empty()): return false
 if f.stage=="COMPANY_CONFIRMATION" and s.squads.first.members.size()<2: return false
 return true

const DOCKSIDE_FILE="res://data/greywake_dockside.json"
const INTRO_JOB="greywake-dockside-trouble"
const WORK_JOB="greywake-harth-rounds"
const PERSISTENT_OFFER_DEADLINE=2147483646
const LESSONS={"select":"Select a fighter by clicking them or their name. Your choices remain free.","move":"Click open ground, inspect the route, then Confirm movement. Water and stacked cargo are impassable.","ap":"Action Points pay for moving, attacking and preparing defence. Read the cost before confirming.","attack":"Select a visible opponent and choose Confirm attack. Melee weapons require their real reach.","chance":"The target panel shows hit chance and attack AP. Chance is not a guarantee; enemy defence can stop a hit.","turn":"End turn when ready. Unspent AP can support guard reactions under the existing rules.","defence":"Use cover, Guard or a defensive preparation. You can withdraw through a safe exit.","resolve":"After victory or defeat, choose Resolve. Injuries, losses and actual loot remain with the campaign."}
static func seed_encounter(c) -> void:
 if c.s.jobs.any(func(j):return j.id==INTRO_JOB): return
 var doc=JSON.parse_string(FileAccess.get_file_as_string(DOCKSIDE_FILE));var fighters=[]
 for row in doc.enemies:
  var p=Data.person(row.id,row.name,"farmer",row.weapon)
  for key in ["strength","agility","dexterity","endurance","perception","wisdom","leadership","melee","ranged"]: p[key]=int(row[key])
  p.hp=int(row.hp);p.max_hp=int(row.hp);p.medical=0;p.smithing=0;p.morale=50
  p.stealth=20;p.fieldcraft=20;p.athletics=30
  p.inventory=p.inventory.filter(func(item):return item.kind!="ammo")
  Data.equipped(p,"body").kind="clothing"
  fighters.append(p)
 c.s.groups.append({"id":doc.id,"faction":"bandits","sector":17,"objective":17,"fighters":fighters,"positions":{},"stationary":true})
 c.s.jobs.append({"id":INTRO_JOB,"name":"Dockside Trouble","type":"eliminate","sector":17,"origin":17,"reward":int(doc.reward),"deadline":PERSISTENT_OFFER_DEADLINE,"status":"available","target":doc.id,"opening_contract":true})
 # A short, ordinary paid route near Harth remains available after a dockside loss.
 # Existing waypoint progress, exactly-once payment and daily reposting are reused.
 c.s.jobs.append({"id":WORK_JOB,"name":"Harth farm-road rounds","type":"patrol","sector":84,"origin":84,"waypoints":[100,84],"reward":120,"deadline":c.s.time+7200,"status":"available","target":"","recovery_work":true})
 c.Contracts.normalize(c.s)
 c.schedule(c.s.time+7200,"deadline",{"id":WORK_JOB})
static func start_encounter(c) -> bool:
 if stage(c.s)!="GREYWAKE_CAMPAIGN" or c.battle!=null or not c.s.encounter.is_empty(): return c.reject("Prepare the company on the island first")
 var q=c.s.squads.get("first",{});var j={}
 for job in c.s.jobs:
  if job.id==INTRO_JOB: j=job
 if q.is_empty() or q.sector!=17 or not q.route.is_empty() or not c.Contracts.capable(c,q) or j.is_empty() or j.status not in ["available","active"] or not c.hostile_at(17): return c.reject("Bring a capable stationary company to Dock Town")
 if j.status=="available" and not c.Contracts.accept(c,INTRO_JOB,q.id): return false
 c.s.opening_flow.stage="FIRST_TACTICAL_ENCOUNTER"
 c.encounter(q,17)
 return c.command("enter")
static func on_resolved(c,index: int,outcome: String) -> void:
 if stage(c.s)!="FIRST_TACTICAL_ENCOUNTER" or index!=17: return
 c.s.opening_flow.stage="GREYWAKE_CAMPAIGN";c.s.opening_flow.outcome=outcome
 c.s.opening_flow.tutorial_flags.resolve=true
 if outcome!="victory":
  for job in c.s.jobs:
   if job.id==INTRO_JOB and job.status=="active": c.Contracts.finish(c,job,false,"Company withdrew" if outcome=="retreat" else "Company defeated")
static func mark(s: Dictionary,key: String) -> void:
 if stage(s)=="FIRST_TACTICAL_ENCOUNTER" and key in LESSONS: s.opening_flow.tutorial_flags[key]=true
static func lesson(s: Dictionary,battle) -> String:
 if stage(s)!="FIRST_TACTICAL_ENCOUNTER" or s.opening_flow.tutorial_dismissed: return ""
 if battle!=null and battle.t.phase!="deployment" and battle.outcome()!="ongoing": return "resolve"
 for key in LESSONS:
  if not s.opening_flow.tutorial_flags.get(key,false): return key
 return ""

static func prepare_contact(c,index: int) -> void:
 if stage(c.s)!="GREYWAKE_CAMPAIGN" or c.s.opening_flow.outcome!="" or index!=17 or not c.s.encounter.is_empty() or c.battle!=null: return
 for job in c.s.jobs:
  if job.id==INTRO_JOB and job.status=="available":
   if c.Contracts.accept(c,INTRO_JOB,"first"): c.s.opening_flow.stage="FIRST_TACTICAL_ENCOUNTER"
   return
