extends RefCounted
const Data=preload("res://sim/catalog.gd")
const Items=preload("res://sim/inventory.gd")
const Supplies=preload("res://sim/supplies.gd")
const Garrison=preload("res://sim/garrison.gd")

# Upgrade detached parsed data. Never mutate the currently running campaign.
static func upgrade(data: Variant) -> Dictionary:
 if not data is Dictionary: return {}
 if data.get("version",0)==3: return data
 if data.get("version",0)==2: return upgrade_v2(data)
 if data.get("version",0)!=1 or not legacy_shape(data): return {}
 data.version=2
 data.next_item=1
 data.stash_sector=17
 data.pending_encounters=[]
 for m in data.mercs.values(): Items.migrate_person(m)
 var converted=[]
 for kind in data.stash:
  if not kind is String: return {}
  converted.append(Items.create(data,kind,16 if kind=="ammo" else 1))
 data.stash=converted
 var roster=[]
 for g in data.groups:
  if not g is Dictionary or not g.has_all(["id","sector","strength","faction","objective"]): return {}
  g.fighters=[]
  g.positions={}
  for index in range(g.strength):
   g.fighters.append(Data.hostile(g.id+"_fighter_%d" % index,index))
   if not data.encounter.is_empty() and g.sector==data.encounter.sector: roster.append({"group":g,"index":index})
  g.erase("strength")
 if not data.battle.is_empty():
  var enemy_index=0
  for u in data.battle.units:
   if u.team=="company":
    if not data.mercs.has(u.id): return {}
    u.person=data.mercs[u.id]
   else:
    if enemy_index>=roster.size(): return {}
    Items.migrate_person(u.person)
    var slot=roster[enemy_index]
    slot.group.fighters[slot.index]=u.person
    slot.group.positions[u.id]={"x":u.x,"y":u.y}
    u.group=slot.group.id
    enemy_index+=1
  # Reuse legacy corpse equipment instead of minting a duplicate weapon.
  for placement in data.battle.ground:
   var entry={}
   for u in data.battle.units:
    if u.x==placement.x and u.y==placement.y and u.person.hp<=0:
     for candidate in u.person.inventory:
      if candidate.kind==placement.item:
       entry=candidate
       for slot in u.person.equipment.keys():
        if u.person.equipment[slot]==entry.id: u.person.equipment.erase(slot)
       u.person.inventory.erase(entry)
       break
     if not entry.is_empty(): break
   if entry.is_empty(): entry=Items.create(data,placement.item)
   placement.item=entry
  data.sectors[data.encounter.sector].battlefield={"width":data.battle.width,"height":data.battle.height,"tiles":data.battle.tiles,"ground":data.battle.ground}
 return upgrade_v2(data)

static func upgrade_v2(data: Dictionary) -> Dictionary:
 if not data.has_all(["sectors","squads","stash_sector","battle"]): return {}
 if not data.sectors is Array or data.sectors.size()!=256 or not data.squads is Dictionary or not data.battle is Dictionary: return {}
 if not (data.stash_sector is int or data.stash_sector is float) or data.stash_sector<0 or data.stash_sector>=256: return {}
 for sector in data.sectors:
  if not sector is Dictionary or not sector.has_all(["garrison","training"]): return {}
  if not (sector.garrison is int or sector.garrison is float) or sector.garrison<0 or sector.garrison>256: return {}
 if not Supplies.migrate_pool(data): return {}
 data.next_levy=1
 for sector in data.sectors:
  sector.levies=[]
  for index in range(sector.garrison): Garrison.create(data,sector)
  sector.erase("garrison")
 if not data.battle.is_empty():
  if not data.battle.has("units") or not data.battle.units is Array: return {}
  data.battle.squads=[]
  for u in data.battle.units:
   u.role="merc" if u.team=="company" else "enemy"
   if u.team=="company":
    var q=Supplies.squad_for(data,u.id)
    if q.is_empty(): return {}
    u.squad=q.id
    if q.id not in data.battle.squads: data.battle.squads.append(q.id)
 data.version=3
 return data

static func legacy_shape(data: Dictionary) -> bool:
 if not data.has_all(["sectors","mercs","stash","groups","battle","encounter"]): return false
 if not data.sectors is Array or data.sectors.size()!=256 or not data.mercs is Dictionary or not data.stash is Array or not data.groups is Array or not data.battle is Dictionary or not data.encounter is Dictionary: return false
 for sector in data.sectors:
  if not sector is Dictionary: return false
 for g in data.groups:
  if not g is Dictionary or not g.has_all(["id","sector","strength","faction","objective"]): return false
  if not g.id is String or not (g.strength is int or g.strength is float) or g.strength<0 or g.strength>256: return false
 var people=data.mercs.values()
 if not data.battle.is_empty():
  if not data.battle.has_all(["units","ground","tiles","width","height"]) or not data.battle.units is Array: return false
  if not data.encounter.has_all(["sector","squad"]) or data.encounter.sector<0 or data.encounter.sector>=256: return false
  for u in data.battle.units:
   if not u is Dictionary or not u.has_all(["id","person","team","x","y"]): return false
   people.append(u.person)
 for p in people:
  if not p is Dictionary or not p.has_all(["id","inventory","weapon","armour","shield","helmet","ammo","condition"]): return false
  if not p.inventory is Array: return false
  if not p.id is String or not (p.ammo is int or p.ammo is float) or p.ammo<0 or not (p.condition is int or p.condition is float): return false
  if not Data.WEAPONS.has(p.weapon) or not Data.ARMOUR.has(p.armour): return false
  for kind in p.inventory:
   if not kind is String: return false
 return true
