extends RefCounted
# Absolute clock: Day 1 begins at minute 0; the landing clock is 08:00 (480).
const FIRST_ARRIVAL=3*1440+360
const ARRIVAL_INTERVAL=5760
const OFFSHORE_WAIT=1440
const RECRUITMENT_WINDOW=2880
const MIN_CANDIDATES=2
const MAX_CANDIDATES=4
const Recruitment=preload("res://sim/recruitment.gd")
const R=preload("res://sim/records.gd")
const SCENARIO_FILE="res://data/greywake_scenario.json"
const EVENT_KINDS=["greywake_ship_arrival","greywake_offshore_deadline","greywake_recruitment_departure"]
const STATUSES=["scheduled","offshore","docked","departed","turned_back","cancelled"]

static func applies(s: Dictionary) -> bool: return s.get("scenario")=="fall_of_greywake"
static func dock(s: Dictionary) -> int: return int(s.greywake.dock_sector)
static func accessible(s: Dictionary) -> bool:
 if not applies(s): return false
 var sh=s.shipping
 return sh.port_blockade.is_empty() and (s.sectors[dock(s)].owner in s.greywake.friendly_harbour_owners or sh.passage_granted)

static func scenario() -> Dictionary:
 var data=JSON.parse_string(FileAccess.get_file_as_string(SCENARIO_FILE))
 for key in ["dock_sector","planned_width","planned_height"]: data[key]=int(data[key])
 return data

static func initialize(c) -> void:
 c.s.greywake=scenario()
 c.s.shipping={"next_sequence":1,"next_arrival_at":FIRST_ARRIVAL,"port_blockade":"","passage_granted":false,"vessels":[]}
 schedule_next(c)

static func schedule_next(c) -> void:
 var sh=c.s.shipping
 var id="greywake-vessel-%08d" % sh.next_sequence
 sh.next_sequence+=1
 sh.vessels.append({"id":id,"arrival_at":sh.next_arrival_at,"status":"scheduled","offshore_deadline":0,"docked_at":0,"recruitment_deadline":0,"offers":[]})
 c.schedule(sh.next_arrival_at,"greywake_ship_arrival",{"vessel":id})

static func vessel(s: Dictionary,id: String) -> Dictionary:
 for v in s.shipping.vessels:
  if v.id==id: return v
 return {}

static func timestamp(at: int) -> String:
 return "Day %d, %02d:%02d" % [int(at/1440)+1,int(at/60)%24,at%60]

static func expire_offers(v: Dictionary) -> void:
 for o in v.offers:
  if o.status=="available": o.status="expired"

static func manifest(c,v: Dictionary) -> void:
 # Generate once, on arrival. Reserve IDs before equipment exists; never reuse them.
 var rows=c.s.recruitment.templates
 var cheap=rows.filter(func(row):return row.repeatable)
 var named=[];var reserved={}
 for other in c.s.shipping.vessels:
  for offer in other.offers:
   if offer.status=="available": reserved[offer.candidate_id]=true
 for row in rows:
  if row.repeatable: continue
  var p=c.s.mercs["greywake-named-"+row.id]
  if eligible(p) and not reserved.has(p.id): named.append(row)
 var count=MIN_CANDIDATES+c.roll(MAX_CANDIDATES-MIN_CANDIDATES+1)
 for i in range(count):
  var row
  # At least one inexpensive replacement; remaining slots may carry a professional.
  if i>0 and not named.is_empty() and c.roll(3)==0:
   row=named.pop_at(c.roll(named.size()))
  else: row=cheap[c.roll(cheap.size())]
  var id="greywake-named-"+row.id;var title=row.name
  if row.repeatable:
   var serial=int(c.s.recruitment.next_id)
   id="greywake-recruit-%08d" % serial;title="Hireling %08d · %s" % [serial,row.name]
   c.s.recruitment.next_id=serial+1
  v.offers.append({"id":v.id+"-offer-"+str(i+1),"vessel_id":v.id,"template_id":row.id,"candidate_id":id,"name":title,"fee":row.fee,"wage":row.wage,"preview":row.duplicate(true),"status":"available","person_id":""})

static func eligible(p: Dictionary) -> bool:
 return not p.hired and not p.dead and not p.get("captured",false) and not p.get("mainland_hired",false)

static func dock_vessel(c,v: Dictionary) -> void:
 if v.status not in ["scheduled","offshore"]: return
 if v.status=="offshore" and c.s.time>=v.offshore_deadline: return
 var title="HARBOUR REOPENED" if v.status=="offshore" else "MAINLAND VESSEL ARRIVED"
 v.status="docked";v.docked_at=c.s.time;v.recruitment_deadline=c.s.time+RECRUITMENT_WINDOW
 c.schedule(v.recruitment_deadline,"greywake_recruitment_departure",{"vessel":v.id})
 c.note(title+" · Dock Town. The mainland vessel has entered port. Its passengers are available for recruitment until "+timestamp(v.recruitment_deadline)+".")

static func process(c,event: Dictionary) -> void:
 if not applies(c.s): return
 var v=vessel(c.s,event.payload.get("vessel",""))
 if v.is_empty(): return
 match event.kind:
  "greywake_ship_arrival":
   if v.status!="scheduled" or c.s.time!=v.arrival_at: return
   manifest(c,v)
   c.s.shipping.next_arrival_at=v.arrival_at+ARRIVAL_INTERVAL
   schedule_next(c)
   if accessible(c.s): dock_vessel(c,v)
   else:
    v.status="offshore";v.offshore_deadline=v.arrival_at+OFFSHORE_WAIT
    c.schedule(v.offshore_deadline,"greywake_offshore_deadline",{"vessel":v.id})
    c.note("MAINLAND VESSEL WAITING OFFSHORE · Dock Town. A recruitment vessel has arrived, but the harbour is sealed. Its captain will wait until tomorrow morning before returning to the mainland. Deadline: "+timestamp(v.offshore_deadline)+".")
  "greywake_offshore_deadline":
   if v.status!="offshore" or c.s.time<v.offshore_deadline: return
   v.status="turned_back";expire_offers(v)
   c.note("REINFORCEMENTS LOST · Dock Town. The recruitment vessel has returned to the mainland. No new mercenaries have landed.")
  "greywake_recruitment_departure":
   if v.status!="docked" or c.s.time<v.recruitment_deadline: return
   v.status="departed";expire_offers(v);c.note("Mainland recruitment vessel departed Dock Town.")

static func access_changed(c) -> void:
 if not applies(c.s): return
 for v in c.s.shipping.vessels:
  if v.status!="offshore": continue
  # Deadline wins even when this hook runs before its queued event at the same minute.
  if c.s.time>=v.offshore_deadline:
   v.status="turned_back";expire_offers(v)
   c.note("REINFORCEMENTS LOST · Dock Town. The recruitment vessel has returned to the mainland. No new mercenaries have landed.")
  elif accessible(c.s): dock_vessel(c,v)

# Authored campaign integrations only; deliberately not exposed as a player command.
static func set_closure(c,reason: String) -> void:
 if not applies(c.s): return
 c.s.shipping.port_blockade=reason;access_changed(c)

static func grant_passage(c) -> void:
 if not applies(c.s): return
 c.s.shipping.passage_granted=true;access_changed(c)

static func cancel(c,id: String) -> bool:
 if not applies(c.s): return false
 var v=vessel(c.s,id)
 if v.is_empty() or v.status not in ["scheduled","offshore","docked"]: return false
 # Keep the original calendar when cancelling a future vessel.
 if v.status=="scheduled":
  c.s.shipping.next_arrival_at=v.arrival_at+ARRIVAL_INTERVAL;schedule_next(c)
 v.status="cancelled";expire_offers(v)
 return true

static func hire(c,offer_id: String,squad_id: String) -> bool:
 if not applies(c.s) or Recruitment.opening(c.s): return c.reject("Complete mainland departure first")
 if c.battle!=null or not c.s.encounter.is_empty(): return c.reject("Resolve the active encounter before recruiting")
 var v={};var offer={}
 for candidate in c.s.shipping.vessels:
  for o in candidate.offers:
   if o.id==offer_id: v=candidate;offer=o
 if offer.is_empty() or v.status!="docked" or offer.status!="available" or c.s.time>=v.recruitment_deadline or not accessible(c.s): return c.reject("A current accessible docked-vessel offer is required")
 var q=c.s.squads.get(squad_id,{})
 if q.is_empty() or q.sector!=dock(c.s) or not q.route.is_empty(): return c.reject("Hiring squad must be stationary at Dock Town")
 if c.s.funds<offer.fee or c.s.mercs.size()>=4096: return c.reject("Insufficient hiring funds or roster space")
 var row=offer.preview;var person
 if row.repeatable:
  if c.s.mercs.has(offer.candidate_id): return c.reject("Candidate already exists")
  person=Recruitment.make_person(row,offer.candidate_id,offer.name)
 else:
  person=c.s.mercs.get(offer.candidate_id,{})
  if person.is_empty() or not eligible(person): return c.reject("Professional is no longer available")
 # All checks precede authoritative mutations. Canonical named inventory is retained.
 c.record(-int(offer.fee),"Mainland hire "+person.name)
 person.hired=true;person.mainland_hired=true;person.expires=c.s.time+7*1440
 c.s.mercs[person.id]=person;q.members.append(person.id)
 if q.leader=="": q.leader=person.id
 c.schedule(person.expires,"employment",{"id":person.id})
 offer.status="hired";offer.person_id=person.id
 c.note(person.name+" joined at Dock Town from "+v.id)
 return true

static func valid(s: Dictionary) -> bool:
 if not applies(s):
  if s.has("shipping") or s.has("greywake") or s.has("opening_voyage"): return false
  for e in s.events:
   if e.kind in EVENT_KINDS: return false
  return true
 var scenario_spec=scenario()
 if s.get("greywake",{}).get("world_mode")=="island_v1": scenario_spec.world_mode="island_v1";scenario_spec.world_version=1
 if s.get("greywake")!=scenario_spec: return false
 var sh=s.get("shipping")
 if not sh is Dictionary or not sh.has_all(["next_sequence","next_arrival_at","port_blockade","passage_granted","vessels"]): return false
 if not R.integer(sh.next_sequence,2,1000000000) or not R.integer(sh.next_arrival_at,FIRST_ARRIVAL) or int(sh.next_arrival_at-FIRST_ARRIVAL)%ARRIVAL_INTERVAL!=0: return false
 if not sh.port_blockade is String or sh.port_blockade.length()>256 or not sh.passage_granted is bool or not sh.vessels is Array or sh.vessels.size()>10000: return false
 var vessels={};var offers={};var identities={};var active_names={};var hired_names={};var scheduled=0
 var rows={}
 for row in s.recruitment.templates: rows[row.id]=row
 for v in sh.vessels:
  if not v is Dictionary or not v.has_all(["id","arrival_at","status","offshore_deadline","docked_at","recruitment_deadline","offers"]): return false
  if not v.id is String or vessels.has(v.id) or v.status not in STATUSES or not v.offers is Array: return false
  var serial=v.id.trim_prefix("greywake-vessel-")
  if not v.id.begins_with("greywake-vessel-") or not serial.is_valid_int() or int(serial)<1 or int(serial)>=sh.next_sequence: return false
  if not R.integer(v.arrival_at,FIRST_ARRIVAL) or v.arrival_at!=FIRST_ARRIVAL+(int(serial)-1)*ARRIVAL_INTERVAL: return false
  for key in ["offshore_deadline","docked_at","recruitment_deadline"]:
   if not R.integer(v[key],0): return false
  vessels[v.id]=v
  if v.status=="scheduled":
   scheduled+=1
   if v.offshore_deadline!=0 or v.docked_at!=0 or v.recruitment_deadline!=0: return false
   if v.arrival_at!=sh.next_arrival_at or v.arrival_at<=s.time or not v.offers.is_empty(): return false
  elif v.status!="cancelled":
   if v.arrival_at>s.time or v.offers.size()<MIN_CANDIDATES or v.offers.size()>MAX_CANDIDATES: return false
  if v.offshore_deadline!=0 and v.offshore_deadline!=v.arrival_at+OFFSHORE_WAIT: return false
  if v.status in ["offshore","turned_back"] and (v.offshore_deadline==0 or v.docked_at!=0 or v.recruitment_deadline!=0): return false
  if v.status=="offshore" and s.time>=v.offshore_deadline: return false
  if v.status=="turned_back" and s.time<v.offshore_deadline: return false
  if v.status in ["docked","departed"]:
   if v.docked_at<v.arrival_at or v.docked_at>s.time or v.recruitment_deadline!=v.docked_at+RECRUITMENT_WINDOW: return false
   if v.offshore_deadline>0 and v.docked_at>=v.offshore_deadline: return false
   if (v.status=="docked")!=(s.time<v.recruitment_deadline): return false
  for o in v.offers:
   if not o is Dictionary or not o.has_all(["id","vessel_id","template_id","candidate_id","name","fee","wage","preview","status","person_id"]): return false
   if not o.id is String or offers.has(o.id) or not o.id.begins_with(v.id+"-offer-") or o.vessel_id!=v.id or o.status not in ["available","hired","expired"] or not rows.has(o.template_id): return false
   var row=rows[o.template_id]
   if o.preview!=row or o.fee!=row.fee or o.wage!=row.wage or not o.candidate_id is String or not o.person_id is String: return false
   offers[o.id]=o
   if row.repeatable:
    var n=o.candidate_id.trim_prefix("greywake-recruit-")
    if not o.candidate_id.begins_with("greywake-recruit-") or not n.is_valid_int() or int(n)<1 or int(n)>=s.recruitment.next_id or identities.has(o.candidate_id): return false
    identities[o.candidate_id]=true
    if o.name!="Hireling %08d · %s" % [int(n),row.name]: return false
    if o.status!="hired" and s.mercs.has(o.candidate_id): return false
   elif o.candidate_id!="greywake-named-"+row.id or o.name!=row.name: return false
   if o.status=="available":
    if v.status not in ["offshore","docked"] or o.person_id!="": return false
    if not row.repeatable:
     if active_names.has(o.candidate_id) or not eligible(s.mercs[o.candidate_id]): return false
     active_names[o.candidate_id]=true
   elif o.status=="hired":
    if v.docked_at<=0: return false
    if not row.repeatable:
     if hired_names.has(o.candidate_id): return false
     hired_names[o.candidate_id]=true
    if o.person_id!=o.candidate_id or not s.mercs.has(o.person_id) or not s.mercs[o.person_id].get("mainland_hired",false): return false
    var person=s.mercs[o.person_id]
    if person.template_id!=o.template_id or person.name!=o.name: return false
   elif o.person_id!="" or v.status not in ["departed","turned_back","cancelled"]: return false
 if scheduled!=1 or sh.vessels.size()!=sh.next_sequence-1: return false
 # Exactly one future authoritative event for every live state; obsolete events may remain.
 var event_keys={}
 for e in s.events:
  if e.kind not in EVENT_KINDS: continue
  if not vessels.has(e.payload.get("vessel","")): return false
  var v=vessels[e.payload.vessel];var key=e.kind+":"+v.id
  if event_keys.has(key): return false
  event_keys[key]=e.at
  var expected={"greywake_ship_arrival":v.arrival_at,"greywake_offshore_deadline":v.offshore_deadline,"greywake_recruitment_departure":v.recruitment_deadline}[e.kind]
  if expected<=0 or e.at!=expected: return false
 for v in sh.vessels:
  var kind={"scheduled":"greywake_ship_arrival","offshore":"greywake_offshore_deadline","docked":"greywake_recruitment_departure"}.get(v.status,"")
  if kind!="" and not event_keys.has(kind+":"+v.id): return false
 return true
