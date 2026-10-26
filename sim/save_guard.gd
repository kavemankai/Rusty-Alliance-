extends RefCounted
const R=preload("res://sim/records.gd")
const Data=preload("res://sim/catalog.gd")

static func text(value: Variant) -> bool: return value is String and value.length()<=4096
static func number(value: Variant,low: int=0,high: int=1000000000000) -> bool: return R.integer(value,low,high)
static func vec(value: Variant,w: int=160,h: int=160) -> bool:
 return value is Dictionary and number(value.get("x"),0,w-1) and number(value.get("y"),0,h-1)

static func item(value: Variant,legacy: bool=false) -> bool:
 if legacy: return value is String
 if not value is Dictionary or not text(value.get("id")) or value.id=="" or not text(value.get("kind")): return false
 if not number(value.get("quantity"),1,1000000) or not number(value.get("condition"),0,100): return false
 return value.get("ammo_type","arrows") in ["arrows","bolts","javelins"]

static func person(value: Variant,legacy: bool=false) -> bool:
 if not value is Dictionary or not text(value.get("id")) or value.id=="" or not text(value.get("name")): return false
 if not Data.Skills.valid(value): return false
 if not value.get("inventory") is Array or value.inventory.size()>4096: return false
 for entry in value.inventory:
  if not item(entry,legacy): return false
 for stat in ["hp","max_hp","fatigue","morale","strength","agility","dexterity","endurance","perception","wisdom","leadership","melee","ranged","medical","smithing","experience","bleeding","wounds"]:
  if not number(value.get(stat),0,1000000): return false
 if value.max_hp<1 or value.hp>value.max_hp or value.fatigue>100 or value.morale>100: return false
 for stat in ["fee","wage","expires","training","kills"]:
  if not number(value.get(stat)): return false
 if not text(value.get("background")): return false
 for stat in ["strength","agility","dexterity","endurance","perception","wisdom","leadership","melee","ranged","medical","smithing"]:
  if value[stat]>1000: return false
 for flag in ["hired","dead","loaded"]:
  if not value.get(flag) is bool: return false
 for flag in ["captured","released"]:
  if value.has(flag) and not value[flag] is bool: return false
 if value.get("assignment","") not in R.ASSIGNMENTS: return false
 if value.has("assignment_record"):
  var assignment=R.Assignment.decode(value.assignment_record)
  if assignment==null or assignment.actor!=value.id or assignment.kind!=value.assignment: return false
 if legacy:
  return value.get("weapon","") in Data.WEAPONS and value.get("armour","") in Data.ARMOUR and number(value.get("ammo"),0,1000000) and number(value.get("condition"),0,100) and value.get("shield") is bool and value.get("helmet") is bool
 if not value.get("equipment") is Dictionary: return false
 for slot in value.equipment:
  if slot not in ["weapon","body","shield","helmet"] or not text(value.equipment[slot]): return false
 if value.has("injuries"):
  if not value.injuries is Array or value.injuries.size()>100000: return false
  for wound in value.injuries:
   if not wound is Dictionary or wound.get("location","") not in ["torso","head","arms","legs"] or not number(wound.get("severity"),0,5) or not wound.get("treated") is bool: return false
 return true

static func tile(value: Variant,index: int,w: int,h: int) -> bool:
 if not vec(value,w,h) or value.x+value.y*w!=index: return false
 for key in ["cost","elevation","cover","conceal"]:
  if not number(value.get(key),0,100): return false
 if value.cost<1 or not text(value.get("kind")): return false
 for key in ["block","door","open"]:
  if not value.get(key) is bool: return false
 for key in ["roof","interior"]:
  if value.has(key) and not value[key] is bool: return false
 if value.has("room") and not text(value.room): return false
 if value.has("light") and not number(value.light,0,12): return false
 if value.has("cover_edge") and not number(value.cover_edge,0,7): return false
 return true

static func field(value: Variant,legacy: bool=false) -> bool:
 if not value is Dictionary or not number(value.get("width"),1,160) or not number(value.get("height"),1,160): return false
 var w=int(value.width);var h=int(value.height)
 if not value.get("tiles") is Array or value.tiles.size()!=w*h or not value.get("ground") is Array: return false
 for i in range(value.tiles.size()):
  if not tile(value.tiles[i],i,w,h): return false
 for placement in value.ground:
  if not vec(placement,w,h) or not item(placement.get("item"),legacy): return false
 for key in ["fog","entry_zones"]:
  if value.has(key) and not value[key] is Dictionary: return false
 if value.has("fog"):
  if not value.fog.has_all(["company","enemy"]): return false
  for team in ["company","enemy"]:
   if not value.fog[team] is Dictionary: return false
 for key in ["deployment_zones","enemy_spawns"]:
  if value.has(key) and not value[key] is Array: return false
 return true

static func contact(value: Variant) -> bool:
 if not value is Dictionary: return false
 if value.is_empty(): return true
 return text(value.get("squad")) and number(value.get("sector"),0,255) and number(value.get("from",value.get("sector")),0,255) and (not value.has("peaceful") or value.peaceful is bool)

# Structural preflight runs before old migration code or semantic validators.
static func raw(data: Variant) -> bool:
 if not data is Dictionary or not number(data.get("version"),1,3): return false
 var legacy=data.version==1
 for key in ["mercs","squads","factions","battle","encounter"]:
  if not data.get(key) is Dictionary: return false
 for key in ["sectors","groups","jobs","events","ledger","stash","log"]:
  if not data.get(key) is Array: return false
 if data.sectors.size()!=256 or data.groups.size()>4096 or data.mercs.size()>4096 or data.events.size()>200000 or data.jobs.size()>100000 or data.ledger.size()>1000000: return false
 if not number(data.get("time")) or not number(data.get("rng"),1,2147483646) or not number(data.get("funds"),-1000000000000) or not number(data.get("next_event"),1): return false
 if not data.get("result") is Dictionary: return false
 if data.has("stash_sector") and not number(data.stash_sector,0,255): return false
 if data.has("next_levy") and not number(data.next_levy,1): return false
 if not contact(data.encounter): return false
 if data.has("pending_encounters") and not data.pending_encounters is Array: return false
 for c in data.get("pending_encounters",[]):
  if not contact(c) or c.is_empty(): return false
 for message in data.log:
  if not text(message): return false
 for entry in data.stash:
  if not item(entry,legacy): return false
 for key in data.mercs:
  if not text(key) or not person(data.mercs[key],legacy) or data.mercs[key].id!=key: return false
 for key in data.squads:
  var q=data.squads[key]
  if not text(key) or not q is Dictionary or q.get("id")!=key or not text(q.get("name")) or not text(q.get("leader")) or not q.get("members") is Array or not q.get("route") is Array or not number(q.get("sector"),0,255) or not number(q.get("due")): return false
  for id in q.members:
   if not text(id): return false
  var last=int(q.sector)
  for sector in q.route:
   if not number(sector,0,255) or absi(last%16-int(sector)%16)+absi(int(last/16)-int(sector/16))!=1: return false
   last=int(sector)
  if q.get("assignment","") not in R.ASSIGNMENTS: return false
 var group_ids={}
 for g in data.groups:
  if not g is Dictionary or not text(g.get("id")) or group_ids.has(g.id) or not text(g.get("faction")) or not data.factions.has(g.faction) or not number(g.get("sector"),0,255) or not number(g.get("objective"),0,255): return false
  group_ids[g.id]=true
  if legacy:
   if not number(g.get("strength"),0,256): return false
  else:
   if not g.get("fighters") is Array or not g.get("positions") is Dictionary: return false
   for p in g.fighters:
    if not person(p): return false
   for position in g.positions.values():
    if not vec(position): return false
 for i in range(256):
  var s=data.sectors[i]
  if not s is Dictionary or s.get("id")!=i or s.get("x")!=i%16 or s.get("y")!=int(i/16) or not text(s.get("owner")) or not data.factions.has(s.owner) or s.get("terrain","") not in ["road","grass","forest","hills","marsh"] or not text(s.get("facility")) or not text(s.get("name")) or not s.get("known") is bool: return false
  for key in ["loyalty","order","training"]:
   if not number(s.get(key),0,100): return false
  if data.version<3 and not number(s.get("garrison"),0,256): return false
  if data.version==3:
   if not s.get("levies") is Array: return false
   for p in s.levies:
    if not person(p): return false
  if s.has("battlefield") and not field(s.battlefield,legacy): return false
 for j in data.jobs:
  if not j is Dictionary or not text(j.get("id")) or not text(j.get("name")) or not text(j.get("type")) or not text(j.get("status")) or not number(j.get("sector"),0,255) or not number(j.get("reward")) or not number(j.get("deadline")): return false
  if not j.get("actors",[]) is Array: return false
  for p in j.get("actors",[]):
   if not person(p): return false
 for f in data.factions.values():
  if not f is Dictionary or not number(f.get("resources")) or not number(f.get("losses")): return false
 if not data.battle.is_empty():
  var b=data.battle
  if not field(b,legacy) or not b.get("units") is Array or not b.get("knowledge") is Dictionary or not b.knowledge.has_all(["company","enemy"]): return false
  for team in ["company","enemy"]:
   if not b.knowledge[team] is Dictionary: return false
   for info in b.knowledge[team].values():
    if not vec(info,int(b.width),int(b.height)) or not number(info.get("round"),0) or not info.get("visible") is bool: return false
  for key in ["log","ai","noise"]:
   if not b.get(key) is Array: return false
  if b.get("turn","") not in ["company","enemy"] or not number(b.get("round"),1): return false
  for noise in b.noise:
   if not vec(noise,int(b.width),int(b.height)) or noise.get("team","") not in ["company","enemy"] or not number(noise.get("round")): return false
  for u in b.units:
   if not u is Dictionary or not person(u.get("person"),legacy) or not text(u.get("id")) or not vec(u,int(b.width),int(b.height)) or not number(u.get("ap"),0,100) or u.get("team","") not in ["company","enemy"] or not number(u.get("facing"),0,7) or not u.get("guard") is bool: return false
   if u.get("stance","") not in ["stand","crouch","prone"] or u.get("mode","") not in ["walk","run","cautious"]: return false
   if not u.get("memory",{}) is Dictionary: return false
   for info in u.get("memory",{}).values():
    if not vec(info,int(b.width),int(b.height)) or not number(info.get("round")) or not info.get("visible") is bool: return false
 return true

static func records(data: Dictionary) -> bool:
 for p in data.mercs.values():
  if p.has("assignment_record") and p.assignment_record.since>data.time: return false
 var ids={};var last_at=-1;var last_id=-1
 for value in data.events:
  var e=R.Event.decode(value)
  if e==null or ids.has(e.id) or e.id>=data.next_event or e.at<data.time or e.at<last_at or (e.at==last_at and e.id<=last_id): return false
  ids[e.id]=true;last_at=e.at;last_id=e.id
 var prior=null
 for value in data.ledger:
  var row=R.Transaction.decode(value)
  if row==null or row.at>data.time or (prior!=null and (row.at<prior.at or row.balance!=prior.balance+row.amount)): return false
  prior=row
 if prior!=null and prior.balance!=data.funds: return false
 return true
