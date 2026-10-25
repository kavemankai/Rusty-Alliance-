extends RefCounted
const Data=preload("res://sim/catalog.gd")

static func create(state: Dictionary,kind: String,quantity: int=1,condition: int=100) -> Dictionary:
 var entry=Data.item("item_%d" % state.next_item,kind,quantity,condition)
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

static func stash_accessible(campaign,id: String) -> bool:
 if campaign.battle!=null: return false
 var q=squad_for(campaign.s,id)
 return not q.is_empty() and q.sector==campaign.s.stash_sector and q.route.is_empty()

static func actor_error(campaign,id: String,cost: int) -> String:
 if not campaign.s.mercs.has(id) or not campaign.s.mercs[id].hired or campaign.s.mercs[id].dead: return "Select an employed living fighter"
 var m=campaign.s.mercs[id]
 if m.hp<=10: return "Incapacitated fighters cannot manage equipment"
 var q=squad_for(campaign.s,id)
 if q.is_empty() or not q.route.is_empty(): return "Wait until the squad is stationary"
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
 var m=campaign.s.mercs[id]
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
  if kind in ["greatsword","polearm","bow","crossbow"] and Data.shield(m): return "Remove shield before using a two handed weapon"
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
 if slot!="" and m.equipment.get(slot,"")==entry.id: return "Already equipped"
 if from_stash:
  campaign.s.stash.erase(entry)
  m.inventory.append(entry)
 if slot!="": m.equipment[slot]=entry.id
 if slot=="weapon": m.loaded=false
 pay_ap(campaign,id,3)
 return ""

static func unequip(campaign,p: Dictionary) -> String:
 var id=p.get("id","")
 var invalid=actor_error(campaign,id,3)
 if invalid!="": return invalid
 var m=campaign.s.mercs[id]
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
  if not campaign.s.mercs.has(destination) or not campaign.s.mercs[destination].hired or campaign.s.mercs[destination].hp<=0: return "Recipient unavailable"
  var a=squad_for(campaign.s,source)
  var b=squad_for(campaign.s,destination)
  if a.is_empty() or b.is_empty() or a.sector!=b.sector or not b.route.is_empty(): return "Recipients must be stationary in the same sector"
  if campaign.battle!=null:
   var receiver=campaign.battle.unit(destination)
   if receiver==null or campaign.battle.distance(campaign.battle.unit(source),receiver)>1: return "Recipient must be adjacent in combat"
 var inventory=campaign.s.stash if source=="stash" else campaign.s.mercs[source].inventory
 var entry=find(inventory,p.get("item",""))
 if entry.is_empty(): return "Source does not own this item"
 if source!="stash" and entry.id in campaign.s.mercs[source].equipment.values(): return "Unequip this item before transferring it"
 var recipient=campaign.s.stash if destination=="stash" else campaign.s.mercs[destination].inventory
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
   if not Data.WEAPONS.has(entry.kind) and not Data.ARMOUR.has(entry.kind) and entry.kind not in ["ammo","shield","helmet"]: return "Unknown item kind"
   if not (entry.quantity is int or entry.quantity is float) or entry.quantity<1 or entry.quantity!=floor(entry.quantity): return "Invalid item quantity"
   if entry.kind!="ammo" and entry.quantity!=1: return "Equipment cannot be stacked"
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
