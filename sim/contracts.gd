extends RefCounted
const Data=preload("res://sim/catalog.gd")

const TYPES=["capture","eliminate","camp","escort","patrol","defend"]

static func seed_board(c) -> void:
 for spec in [
  ["hunt","Break the Redbank raiders","eliminate",34,300,"raiders"],
  ["camp","Assault Briar camp","camp",52,500,"briar_guard"],
  ["caravan","Escort the Willow provisions","escort",49,180,""],
  ["patrol","Patrol the western road","patrol",17,220,""],
  ["defence","Defend Ashford from the raiders","defend",17,400,"raiders"]]:
  c.s.jobs.append({"id":spec[0],"name":spec[1],"type":spec[2],"sector":spec[3],"reward":spec[4],"target":spec[5],"deadline":c.s.time+7200,"status":"available","origin":17,"waypoints":[33,49,81,17] if spec[2]=="patrol" else []})

# Additive schema-3 records: old capture saves remain valid and keep their board.
static func normalize(state: Dictionary) -> void:
 if not state.get("jobs") is Array: return
 var defaults={"squad":"","step":0,"target":"","origin":17,"waypoints":[],"reason":"","finished":0,"accepted":0,"cargo":0}
 for j in state.jobs:
  if not j is Dictionary: continue
  for key in defaults:
   if not j.has(key): j[key]=defaults[key].duplicate() if defaults[key] is Array else defaults[key]
  if j.get("type","")=="escort" and j.get("status","")=="active" and not j.has("actors") and state.get("battle",{}).is_empty():
   j.actors=make_convoy(j.id)

static func group(state: Dictionary,id: String) -> Dictionary:
 for g in state.groups:
  if g.id==id: return g
 return {}

static func capable(c,q: Dictionary) -> bool:
 for id in q.get("members",[]):
  var m=c.s.mercs[id]
  if m.hired and m.hp>10 and not m.get("captured",false): return true
 return false

static func accept(c,id: String,squad: String) -> bool:
 if c.battle!=null or not c.s.encounter.is_empty(): return c.reject("Resolve the encounter before accepting work")
 for j in c.s.jobs:
  if j.id!=id or j.status!="available" or c.s.time>=j.deadline: continue
  var q=c.s.squads.get(squad,{})
  if j.type in ["escort","patrol"]:
   if q.is_empty() or not capable(c,q) or not q.route.is_empty() or q.sector!=j.origin or c.hostile_at(q.sector):
    var work_location=c.s.sectors[j.origin].name if c.s.get("greywake",{}).get("world_mode")=="island_v1" else "Ashford"
    return c.reject("Assign a capable stationary squad at "+work_location)
   for other in c.s.jobs:
    if other.status=="active" and other.type=="escort" and other.squad==squad and j.type=="escort": return c.reject("This squad already escorts a caravan")
  if j.type in ["eliminate","camp","defend"]:
   var g=group(c.s,j.target)
   if g.is_empty() or c.force_strength(g)==0: return c.reject("The target force is already neutralized")
   if j.type=="camp" and (g.sector!=j.sector or c.s.sectors[j.sector].facility!="camp"): return c.reject("The camp is no longer occupied")
   if j.type=="defend" and c.s.sectors[j.sector].owner!="company": return c.reject("Recover the settlement before accepting its defence")
  if j.type=="capture" and c.s.sectors[j.sector].owner=="company": return c.reject("The target is already controlled")
  j.status="active"
  j.squad=squad if j.type in ["escort","patrol"] else ""
  j.accepted=c.s.time
  j.cargo=20 if j.type=="escort" else 0
  if j.type=="escort":
   j.actors=make_convoy(j.id)
   for actor in j.actors: actor.name=("Cart" if actor.merchant_role=="cart" else "Driver")+" · "+q.name
  c.note("Accepted: "+j.name)
  return true
 return c.reject("Job unavailable")

static func finish(c,j: Dictionary,success: bool,reason: String) -> void:
 if j.status!="active" and not (j.status=="available" and not success): return
 j.status="paid" if success else "failed"
 j.reason=reason
 j.finished=c.s.time
 j.cargo=0
 if success: c.record(j.reward,"Contract: "+j.name)
 c.note(j.name+": "+reason)

static func tick(c) -> void:
 for j in c.s.jobs:
  if j.status not in ["active","available"]: continue
  if c.s.time>=j.deadline:
   finish(c,j,false,"Deadline missed")
   continue
  if j.status!="active": continue
  if j.type=="escort" and j.get("actors",[]).any(func(actor):return actor.hp<=10 or actor.get("captured",false)):
   finish(c,j,false,"Caravan cart or driver lost")
   continue
  if j.type in ["escort","patrol"]:
   var q=c.s.squads.get(j.squad,{})
   if q.is_empty() or not capable(c,q): finish(c,j,false,"Assigned squad lost or disbanded")
  elif j.type=="defend" and c.s.sectors[j.sector].owner!="company": finish(c,j,false,"Settlement lost")
  elif j.type in ["eliminate","camp","defend"] and c.battle==null:
   var g=group(c.s,j.target)
   if g.is_empty() or c.force_strength(g)==0: finish(c,j,false,"Target lost before the contracted victory")

# Arrival and victorious contact resolution are the only travel progress hooks.
static func visit(c,q: Dictionary) -> void:
 tick(c)
 if c.hostile_at(q.sector): return
 for j in c.s.jobs:
  if j.status!="active" or j.squad!=q.id or c.s.time>=j.deadline: continue
  if not capable(c,q): continue
  if j.type=="escort" and q.sector==j.sector and j.cargo>0:
   # Freight is separate from company provisions until delivered to the depot.
   c.s.sectors[j.sector].supplies.food+=j.cargo
   finish(c,j,true,"Caravan delivered; 20 food stored at destination")
  elif j.type=="patrol" and j.step<j.waypoints.size() and q.sector==j.waypoints[j.step]:
   j.step+=1
   c.note("Patrol checkpoint %d/%d" % [j.step,j.waypoints.size()])
   if j.step==j.waypoints.size(): finish(c,j,true,"Ordered patrol completed and returned")

static func resolved(c,index: int,victory: bool,participating: Array,engaged: Array) -> void:
 for j in c.s.jobs:
  if j.status!="active" or c.s.time>=j.deadline: continue
  if j.type=="escort" and j.squad in participating and not victory:
   finish(c,j,false,"Caravan abandoned or seized in combat")
  elif victory:
   if j.type=="capture" and j.sector==index: finish(c,j,true,"Target captured")
   elif j.type in ["eliminate","camp","defend"] and j.target in engaged:
    var g=group(c.s,j.target)
    if not g.is_empty() and c.force_strength(g)==0:
     if j.type=="eliminate" or j.sector==index: finish(c,j,true,"Target force defeated" if j.type!="defend" else "Settlement assault repelled")
 if victory:
  for q in c.combat_squads(index): visit(c,q)
 tick(c)

static func repost(c,id: String) -> bool:
 for j in c.s.jobs:
  if j.id!=id: continue
  if j.type not in ["escort","patrol"] or j.status not in ["paid","failed"] or c.s.time<j.finished+1440: return c.reject("Road work reposts one day after closing")
  var base=j.get("series",j.id)
  for other in c.s.jobs:
   if other.get("series",other.id)==base and (other.status in ["active","available"] or other.finished>j.finished): return c.reject("A newer posting already exists")
  var offer=j.duplicate(true)
  offer.erase("actors")
  offer.merge({"id":base+"_%d" % c.s.next_event,"series":base,"status":"available","deadline":c.s.time+7200,"squad":"","step":0,"accepted":0,"finished":0,"reason":"","cargo":0},true)
  c.s.jobs.append(offer)
  c.schedule(offer.deadline,"deadline",{"id":offer.id})
  return true
 return c.reject("Unknown posting")

static func describe(j: Dictionary) -> String:
 match j.type:
  "capture": return "Win a battle and capture the target sector."
  "eliminate": return "Defeat the persistent %s force wherever it moves." % j.target
  "camp": return "Assault the occupied camp and defeat its garrison."
  "defend": return "Defeat %s in an actual assault at this settlement; losing it fails the job." % j.target
  "escort": return "Collect 20 freight food at Ashford and deliver to the target with the assigned squad. Keep cart and driver alive; withdrawal loses the caravan."
  "patrol":
   var stops=[]
   for point in j.waypoints: stops.append("%d:%d" % [int(point)%16+1,int(point)/16+1])
   return "Visit in order: "+" → ".join(stops)+". Progress %d/%d." % [j.step,j.waypoints.size()]
 return ""

static func valid(state: Dictionary) -> bool:
 if not state.jobs is Array: return false
 var ids={}
 for j in state.jobs:
  if not j is Dictionary or not j.has_all(["id","name","type","status","sector","reward","deadline"]): return false
  if not j.id is String or j.id=="" or ids.has(j.id) or not j.name is String or not j.type in TYPES or not j.status in ["available","active","paid","failed"]: return false
  ids[j.id]=true
  if j.has("actors"):
   if not j.actors is Array or j.actors.size()!=2 or j.type!="escort": return false
   var roles=[]
   for actor in j.actors:
    if not actor is Dictionary or actor.get("merchant_role","") not in ["cart","driver"] or actor.merchant_role in roles: return false
    roles.append(actor.merchant_role)
  for key in ["sector","reward","deadline"]:
   if not integer(j[key]) or j[key]<0: return false
  if j.sector>=256: return false
  if j.type=="capture" and not j.has("step"): continue # Previous schema-3 capture records.
  if not j.has_all(["squad","step","target","origin","waypoints","reason","finished","accepted","cargo"]): return false
  if not j.squad is String or not j.target is String or not j.reason is String or not j.waypoints is Array: return false
  for key in ["step","origin","finished","accepted","cargo"]:
   if not integer(j[key]) or j[key]<0: return false
  if j.origin>=256 or j.step>j.waypoints.size(): return false
  for point in j.waypoints:
   if not integer(point) or point<0 or point>=256: return false
  if j.type=="patrol" and j.waypoints.is_empty(): return false
  if j.type in ["eliminate","camp","defend"] and j.target=="": return false
  if j.status=="active" and j.type in ["escort","patrol"] and not state.squads.has(j.squad): return false
  if j.cargo!=(20 if j.type=="escort" and j.status=="active" else 0): return false
 return true

static func integer(value: Variant) -> bool:
 return (value is int or value is float) and value==floor(value)

static func make_convoy(id: String) -> Array:
 var cart=Data.person(id+":cart","Provision cart","merchant","unarmed")
 cart.inventory=[];cart.equipment={};cart.hp=90;cart.max_hp=90;cart.agility=25;cart.perception=10;cart.merchant_role="cart"
 var driver=Data.person(id+":driver","Caravan driver","merchant","dagger")
 driver.inventory=driver.inventory.filter(func(item):return item.kind!="ammo")
 Data.equipped(driver,"body").kind="clothing"
 driver.hp=45;driver.max_hp=45;driver.melee=30;driver.merchant_role="driver"
 return [cart,driver]

static func post(c) -> bool:
 if c.battle!=null or not c.s.encounter.is_empty(): return c.reject("Finish the encounter first")
 var q=c.s.squads.get("first",{})
 if q.is_empty() or q.sector!=17 or not q.route.is_empty(): return c.reject("Request postings at Ashford")
 var day=int(c.s.time/1440)
 if c.s.get("board_day",-1)==day: return c.reject("New postings are available once per day")
 var destinations=[]
 for sector in c.s.sectors:
  if sector.id!=17 and sector.facility!="" and sector.owner in ["free","company"]: destinations.append(sector.id)
 destinations.sort()
 if destinations.is_empty(): return c.reject("No open delivery destination")
 c.s.board_day=day
 var destination=destinations[day%destinations.size()]
 var route=c.strategic_path(17,destination,q)
 var risk=0;var eta=0
 for index in route:
  eta+=c.travel_cost(q,index)
  if c.s.sectors[index].known and c.hostile_at(index): risk+=1
 var id="road_%d_%d" % [day,c.s.next_event]
 var j={"id":id,"series":id,"name":"Deliver provisions to "+c.s.sectors[destination].name,"type":"escort","sector":destination,"origin":17,"reward":120+int(eta/4)+risk*75,"deadline":c.s.time+maxi(1440,eta*3+720),"status":"available","target":"","waypoints":[],"risk":risk}
 c.s.jobs.append(j);normalize(c.s);c.schedule(j.deadline,"deadline",{"id":id})
 var patrol={"id":id+"_patrol","series":id+"_patrol","name":"Survey the road to "+c.s.sectors[destination].name,"type":"patrol","sector":17,"origin":17,"reward":100+int(eta/3)+risk*50,"deadline":c.s.time+maxi(1440,eta*4+720),"status":"available","target":"","waypoints":[destination,17],"risk":risk}
 c.s.jobs.append(patrol);normalize(c.s);c.schedule(patrol.deadline,"deadline",{"id":patrol.id})
 c.note("New delivery and patrol postings: travel and known route risk determine payment")
 return true
