extends RefCounted
const Data=preload("res://sim/catalog.gd")

static func create(state: Dictionary,sector: Dictionary) -> Dictionary:
 var serial=state.next_levy
 state.next_levy+=1
 var id="levy_%d" % serial
 var p=Data.person(id,"Levy %d" % serial,"farmer","spear")
 p.melee=45+int(sector.training/20)*2
 p.ranged=40+int(sector.training/20)
 p.leadership=25
 p.medical=15
 p.wage=3
 p.inventory=p.inventory.filter(func(entry): return entry.kind!="ammo")
 var shield=Data.item(id+":shield","shield")
 p.inventory.append(shield)
 p.equipment.shield=shield.id
 sector.levies.append(p)
 return p

static func strength(sector: Dictionary) -> int:
 var count=0
 for p in sector.levies:
  if p.hp>10 and not p.get("captured",false): count+=1
 return count

static func living(sector: Dictionary) -> int:
 var count=0
 for p in sector.levies:
  if p.hp>0 and not p.get("captured",false): count+=1
 return count

static func train(sector: Dictionary,amount: int) -> void:
 var before=int(sector.training/20)
 sector.training=mini(100,sector.training+amount)
 var gained=int(sector.training/20)-before
 if gained<=0: return
 for p in sector.levies:
  if p.hp>0 and not p.get("captured",false):
   p.melee=mini(95,p.melee+gained*2)
   p.ranged=mini(95,p.ranged+gained)
   p.morale=mini(100,p.morale+gained)
