extends RefCounted
const Data=preload("res://sim/catalog.gd")
const KINDS=["food","medicine","tools"]

static func empty() -> Dictionary:
 return {"food":0,"medicine":0,"tools":0}

static func for_person(state: Dictionary,id: String) -> Dictionary:
 for q in state.squads.values():
  if id in q.members: return q.supplies
 for sector in state.sectors:
  for p in sector.levies:
   if p.id==id: return sector.supplies
 return {}

static func squad_for(state: Dictionary,id: String) -> Dictionary:
 for q in state.squads.values():
  if id in q.members: return q
 return {}

static func transfer(campaign,p: Dictionary) -> String:
 if campaign.battle!=null or not campaign.s.encounter.is_empty(): return "Resolve the encounter before moving provisions"
 var resource=p.get("resource","")
 var amount=p.get("amount",0)
 if resource not in KINDS or not (amount is int) or amount<=0: return "Choose a supply type and positive whole amount"
 var source=owner(campaign.s,p.get("from",""))
 var target=owner(campaign.s,p.get("to",""))
 if source.is_empty() or target.is_empty() or source.id==target.id: return "Choose different available supply stores"
 if source.sector!=target.sector: return "Supply stores must be in the same sector"
 if not source.stationary or not target.stationary: return "Squads must be stationary to exchange supplies"
 if source.supplies[resource]<amount: return "Source has insufficient "+resource
 source.supplies[resource]-=amount
 target.supplies[resource]+=amount
 campaign.note("Moved %d %s between local stores" % [amount,resource])
 return ""

static func owner(state: Dictionary,id: String) -> Dictionary:
 if state.squads.has(id):
  var q=state.squads[id]
  return {"id":id,"sector":q.sector,"stationary":q.route.is_empty(),"supplies":q.supplies}
 if id.begins_with("sector:"):
  var number=id.trim_prefix("sector:")
  if not number.is_valid_int(): return {}
  var index=int(number)
  if index<0 or index>=state.sectors.size() or state.sectors[index].owner!="company": return {}
  return {"id":id,"sector":index,"stationary":true,"supplies":state.sectors[index].supplies}
 return {}

static func split(source: Dictionary,member_count: int) -> Dictionary:
 var share=empty()
 for kind in KINDS:
  share[kind]=int(source[kind]/member_count)
  source[kind]-=share[kind]
 return share

static func combine(source: Dictionary,target: Dictionary) -> void:
 for kind in KINDS:
  target[kind]+=source[kind]
  source[kind]=0

static func carried_weight(supplies: Dictionary) -> float:
 return supplies.food*0.1+supplies.medicine*0.2+supplies.tools

static func valid(supplies: Variant) -> bool:
 if not supplies is Dictionary or not supplies.has_all(KINDS): return false
 for kind in KINDS:
  var amount=supplies[kind]
  if not (amount is int or amount is float) or amount<0 or amount!=floor(amount): return false
 return true

# Preserve the entire old pool, allocating proportionally to actual squad sizes.
static func migrate_pool(state: Dictionary) -> bool:
 if not state.has_all(KINDS): return false
 var pool={"food":state.food,"medicine":state.medicine,"tools":state.tools}
 if not valid(pool): return false
 var eligible=[]
 var members=0
 for id in state.squads.keys():
  var q=state.squads[id]
  if not q is Dictionary or not q.has("members") or not q.members is Array: return false
  q.supplies=empty()
  if not q.members.is_empty(): eligible.append(id); members+=q.members.size()
 eligible.sort()
 for sector in state.sectors: sector.supplies=empty()
 var remaining=pool.duplicate()
 for id in eligible:
  var q=state.squads[id]
  for kind in KINDS:
   q.supplies[kind]=int(pool[kind]*q.members.size()/members)
   remaining[kind]-=q.supplies[kind]
 if eligible.is_empty(): combine(remaining,state.sectors[state.stash_sector].supplies)
 else: combine(remaining,state.squads[eligible[0]].supplies)
 for kind in KINDS: state.erase(kind)
 return true
