extends RefCounted
const Data=preload("res://sim/catalog.gd")

static func create(state: Dictionary,kind: String,quantity: int=1,condition: int=100) -> Dictionary:
 var entry=Data.item("item_%d" % state.next_item,kind,quantity,condition)
 if kind=="ammo": entry.ammo_type="arrows"
 state.next_item+=1
 return entry

static func find(entries: Array,id: String) -> Dictionary:
 for entry in entries:
  if entry.id==id: return entry
 return {}

static func squad_for(state: Dictionary,id: String) -> Dictionary:
 for q in state.squads.values():
  if id in q.members: return q
 return {}

static func person(state: Dictionary,id: String) -> Dictionary:
 if state.mercs.has(id): return state.mercs[id]
 for sector in state.sectors:
  for defender in sector.levies:
   if defender.id==id: return defender
 return {}

static func location(state: Dictionary,id: String) -> int:
 var q=squad_for(state,id)
 if not q.is_empty(): return q.sector
 for sector in state.sectors:
  for defender in sector.levies:
   if defender.id==id: return sector.id
 return -1

static func stash_accessible(campaign,id: String) -> bool:
 return campaign.battle==null and location(campaign.s,id)==campaign.s.stash_sector and actor_error(campaign,id,0)==""

static func actor_error(campaign,id: String,cost: int) -> String:
 var m=person(campaign.s,id)
 if m.is_empty() or m.hp<=10 or m.dead or m.get("captured",false): return "Select an available capable fighter"
 if campaign.s.mercs.has(id) and not m.hired: return "Select an employed fighter"
 var q=squad_for(campaign.s,id)
 if not q.is_empty() and not q.route.is_empty(): return "Wait until the squad is stationary"
 var at=location(campaign.s,id)
 if at<0 or (not campaign.s.mercs.has(id) and campaign.s.sectors[at].owner!="company"): return "Defender is not at a controlled depot"
 if campaign.battle!=null:
  var u=campaign.battle.unit(id)
  if u==null or not campaign.battle.can_act(u) or u.ap<cost: return "Need %d AP on an active fighter" % cost
 return ""

static func pay_ap(campaign,id: String,cost: int) -> void:
 if campaign.battle!=null: campaign.battle.unit(id).ap-=cost

static func equip(campaign,p: Dictionary) -> String:
 var id=p.get("id","")
 var invalid=actor_error(campaign,id,3)
 if invalid!="": return invalid
 var m=person(campaign.s,id)
 var selector=p.get("item","")
 var entry=find(m.inventory,selector)
 var from_stash=false
 if entry.is_empty() and stash_accessible(campaign,id):
  entry=find(campaign.s.stash,selector)
  from_stash=not entry.is_empty()
 # Kind selection is kept for legacy command clients; UI always sends unique IDs.
 if entry.is_empty():
  for candidate in m.inventory:
   if candidate.kind==selector:
    entry=candidate
    break
 if entry.is_empty() and stash_accessible(campaign,id):
  for candidate in campaign.s.stash:
   if candidate.kind==selector:
    entry=candidate
    from_stash=true
    break
 if entry.is_empty(): return "Item unavailable here; the stockpile is at Ashford"
 var kind=entry.kind
 var slot=""
 if Data.WEAPONS.has(kind):
  slot="weapon"
  if kind in ["greatsword","polearm","bow","crossbow"] and not Data.equipped(m,"shield").is_empty(): return "Remove shield before using a two handed weapon"
 elif Data.ARMOUR.has(kind):
  slot="body"
  if campaign.battle!=null: return "Change armour outside combat"
 elif kind=="shield":
  slot="shield"
  if Data.weapon(m) in ["greatsword","polearm","bow","crossbow"]: return "Shield incompatible with two handed weapon"
 elif kind=="helmet": slot="helmet"
 elif kind=="ammo":
  if not from_stash: return "Ammunition in the backpack is already available"
 else: return "This item cannot be equipped"
 if campaign.battle!=null and campaign.battle.unit(id).ap<draw_cost(kind): return "Insufficient AP to draw this equipment"
 if slot!="" and m.equipment.get(slot,"")==entry.id: return "Already equipped"
 if from_stash:
  campaign.s.stash.erase(entry)
  m.inventory.append(entry)
 if slot!="": m.equipment[slot]=entry.id
 if slot=="weapon":
  m.loaded=false
  if campaign.battle!=null: campaign.battle.unit(id).attack_style="normal"
 pay_ap(campaign,id,draw_cost(kind))
 return ""

static func unequip(campaign,p: Dictionary) -> String:
 var id=p.get("id","")
 var invalid=actor_error(campaign,id,3)
 if invalid!="": return invalid
 var m=person(campaign.s,id)
 var slot=p.get("slot","shield")
 if Data.equipped(m,slot).is_empty(): return "That slot is empty"
 if slot=="body" and campaign.battle!=null: return "Change armour outside combat"
 m.equipment.erase(slot)
 if slot=="weapon": m.loaded=false
 pay_ap(campaign,id,3)
 return ""

static func transfer(campaign,p: Dictionary) -> String:
 var source=p.get("from","")
 var destination=p.get("to","")
 if source==destination or source=="" or destination=="": return "Choose different item owners"
 var actor=destination if source=="stash" else source
 var invalid=actor_error(campaign,actor,3)
 if invalid!="": return invalid
 if source=="stash" or destination=="stash":
  if not stash_accessible(campaign,actor): return "Visit Ashford to use the stockpile"
 else:
  var recipient_profile=person(campaign.s,destination)
  if recipient_profile.is_empty() or recipient_profile.hp<=0 or recipient_profile.get("captured",false): return "Recipient unavailable"
  var a=squad_for(campaign.s,source)
  var b=squad_for(campaign.s,destination)
  if location(campaign.s,source)!=location(campaign.s,destination) or (not b.is_empty() and not b.route.is_empty()): return "Recipients must be stationary in the same sector"
  if campaign.battle!=null:
   var receiver=campaign.battle.unit(destination)
   if receiver==null or campaign.battle.distance(campaign.battle.unit(source),receiver)>1: return "Recipient must be adjacent in combat"
 var inventory=campaign.s.stash if source=="stash" else person(campaign.s,source).inventory
 var entry=find(inventory,p.get("item",""))
 if entry.is_empty(): return "Source does not own this item"
 if source!="stash" and entry.id in person(campaign.s,source).equipment.values(): return "Unequip this item before transferring it"
 var recipient=campaign.s.stash if destination=="stash" else person(campaign.s,destination).inventory
 inventory.erase(entry)
 recipient.append(entry)
 pay_ap(campaign,actor,3)
 return ""

static func migrate_person(p: Dictionary) -> void:
 if p.has("equipment"): return
 var old=p.inventory.duplicate()
 p.inventory=[]
 p.equipment={}
 var count=0
 for kind in old:
  if kind=="ammo": continue
  var entry=Data.item(p.id+":legacy_%d" % count,kind)
  count+=1
  p.inventory.append(entry)
  var slot=""
  if kind==p.weapon and not p.equipment.has("weapon"): slot="weapon"
  elif kind==p.armour and not p.equipment.has("body"): slot="body"
  elif kind=="shield" and p.shield: slot="shield"
  elif kind=="helmet" and p.helmet: slot="helmet"
  if slot!="": p.equipment[slot]=entry.id
  if slot=="weapon": entry.condition=p.condition
 # Legacy booleans could describe equipment absent from the old inventory list.
 for pair in [["weapon",p.weapon],["body",p.armour],["shield","shield" if p.shield else ""],["helmet","helmet" if p.helmet else ""]]:
  if pair[1]!="" and pair[1] not in ["unarmed","clothing"] and not p.equipment.has(pair[0]):
   var entry=Data.item(p.id+":legacy_"+pair[0],pair[1],1,p.condition if pair[0]=="weapon" else 100)
   p.inventory.append(entry)
   p.equipment[pair[0]]=entry.id
 if p.ammo>0: p.inventory.append(Data.item(p.id+":legacy_ammo","ammo",p.ammo))
 for key in ["weapon","armour","shield","helmet","ammo","condition"]: p.erase(key)

static func ownership_error(state: Dictionary) -> String:
 var ids={}
 var owners=[]
 owners.append({"name":"stash","inventory":state.stash})
 for m in state.mercs.values(): owners.append(m)
 for g in state.groups:
  for m in g.get("fighters",[]): owners.append(m)
 for job in state.jobs:
  for actor in job.get("actors",[]): owners.append(actor)
 for cell in state.sectors:
  for p in cell.levies: owners.append(p)
  for ground in cell.get("battlefield",{}).get("ground",[]):
   if not ground is Dictionary or not ground.has_all(["item","x","y"]): return "Invalid ground placement"
   owners.append({"name":"ground","inventory":[ground.item]})
 for owner in owners:
  if not owner.inventory is Array: return "Invalid inventory"
  var local={}
  for entry in owner.inventory:
   if not entry is Dictionary or not entry.has_all(["id","kind","quantity","condition"]): return "Invalid item"
   if not entry.id is String or entry.id=="" or ids.has(entry.id): return "Duplicate item ownership: "+str(entry.id)
   if not Data.WEAPONS.has(entry.kind) and not Data.ARMOUR.has(entry.kind) and entry.kind not in ["ammo","shield","helmet","stone"]: return "Unknown item kind"
   if not (entry.quantity is int or entry.quantity is float) or entry.quantity<1 or entry.quantity!=floor(entry.quantity): return "Invalid item quantity"
   if entry.kind not in ["ammo","stone"] and entry.quantity!=1: return "Equipment cannot be stacked"
   if entry.kind=="ammo" and entry.get("ammo_type","arrows") not in ["arrows","bolts","javelins"]: return "Invalid ammunition type"
   if not (entry.condition is int or entry.condition is float) or entry.condition<0 or entry.condition>100 or entry.condition!=floor(entry.condition): return "Invalid item condition"
   if entry.id.begins_with("item_"):
    var suffix=entry.id.trim_prefix("item_")
    if not suffix.is_valid_int() or int(suffix)>=state.next_item: return "Item allocator would reuse an existing ID"
   ids[entry.id]=true
   local[entry.id]=entry
  for slot in owner.get("equipment",{}):
   var id=owner.equipment[slot]
   if not local.has(id): return "Equipment is not owned"
   var kind=local[id].kind
   if (slot=="weapon" and not Data.WEAPONS.has(kind)) or (slot=="body" and not Data.ARMOUR.has(kind)) or (slot in ["shield","helmet"] and kind!=slot) or slot not in ["weapon","body","shield","helmet"]: return "Invalid equipment slot"
 return ""

static func draw_cost(kind: String) -> int:
 return 4 if kind in ["greatsword","polearm","crossbow","helmet"] else 3
