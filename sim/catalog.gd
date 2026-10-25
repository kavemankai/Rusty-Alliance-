extends RefCounted

# Original values: no JA2 source tables or content are included.
const WEAPONS = {
 "unarmed": {"damage":7,"kind":"blunt","reach":1,"ap":4,"range":1,"weight":0,"price":0,"accuracy":0,"defence":0},
 "dagger": {"damage":13,"kind":"pierce","reach":1,"ap":4,"range":1,"weight":1,"price":30,"accuracy":6,"defence":2},
 "sword": {"damage":23,"kind":"cut","reach":1,"ap":5,"range":1,"weight":3,"price":85,"accuracy":8,"defence":9},
 "axe": {"damage":29,"kind":"cut","reach":1,"ap":6,"range":1,"weight":4,"price":75,"accuracy":0,"defence":2},
 "mace": {"damage":24,"kind":"blunt","reach":1,"ap":6,"range":1,"weight":4,"price":80,"accuracy":2,"defence":5},
 "spear": {"damage":21,"kind":"pierce","reach":2,"ap":5,"range":2,"weight":3,"price":60,"accuracy":3,"defence":7},
 "polearm": {"damage":30,"kind":"pierce","reach":2,"ap":7,"range":2,"weight":6,"price":115,"accuracy":0,"defence":7},
 "greatsword": {"damage":33,"kind":"cut","reach":1,"ap":7,"range":1,"weight":6,"price":125,"accuracy":2,"defence":8},
 "bow": {"damage":23,"kind":"projectile","reach":0,"ap":5,"range":12,"effective":7,"reload":2,"weight":2,"price":100,"accuracy":4,"defence":0},
 "crossbow": {"damage":34,"kind":"projectile","reach":0,"ap":4,"range":14,"effective":9,"reload":7,"weight":5,"price":150,"accuracy":9,"defence":0},
 "javelin": {"damage":24,"kind":"projectile","reach":0,"ap":5,"range":6,"effective":4,"reload":1,"weight":2,"price":50,"accuracy":1,"defence":0}
}
const ARMOUR = {
 "clothing":{"cut":0,"pierce":0,"blunt":0,"projectile":0,"weight":0,"price":0},
 "padded":{"cut":5,"pierce":3,"blunt":5,"projectile":3,"weight":3,"price":55},
 "leather":{"cut":7,"pierce":4,"blunt":2,"projectile":4,"weight":4,"price":65},
 "mail":{"cut":13,"pierce":7,"blunt":3,"projectile":8,"weight":8,"price":150},
 "plate":{"cut":19,"pierce":13,"blunt":6,"projectile":15,"weight":14,"price":300}
}
const BACKGROUNDS = {
 "soldier":{"melee":72,"leadership":60}, "hunter":{"ranged":78,"perception":80},
 "physician":{"medical":85,"wisdom":76}, "smith":{"smithing":82,"strength":76},
 "knight":{"melee":85,"leadership":78,"wage":45}, "farmer":{"endurance":78,"wage":12}
}

static func person(id: String, title: String, background: String, weapon: String) -> Dictionary:
 var p = {"id":id,"name":title,"background":background,"strength":65,"agility":65,"dexterity":65,
 "endurance":65,"perception":65,"wisdom":60,"leadership":45,"melee":58,"ranged":55,"medical":20,
 "smithing":20,"experience":1,"morale":70,"fatigue":0,"hp":75,"max_hp":75,"wounds":0,"bleeding":0,
 "injuries":[],"loaded":true,"inventory":[item(id+":weapon",weapon),item(id+":body","padded"),item(id+":ammo","ammo",16)],
 "equipment":{"weapon":id+":weapon","body":id+":body"},"assignment":"rest","hired":false,"dead":false,
 "fee":100,"wage":20,"expires":0,"training":0,"kills":0}
 p.inventory[2].ammo_type=ammo_kind_for(weapon)
 p.merge(BACKGROUNDS.get(background, {}), true)
 return p

static func weight(p: Dictionary) -> int:
 var total=0
 for entry in p.inventory:
  if WEAPONS.has(entry.kind): total+=WEAPONS[entry.kind].weight
  elif ARMOUR.has(entry.kind): total+=ARMOUR[entry.kind].weight
  elif entry.kind=="shield": total+=3
  elif entry.kind=="helmet": total+=2
  elif entry.kind=="ammo": total+=int(ceil(entry.quantity/(2.0 if entry.get("ammo_type","")=="javelins" else 8.0)))
  elif entry.kind=="stone": total+=entry.quantity
 return total

static func item(id: String, kind: String, quantity: int=1, condition: int=100) -> Dictionary:
 return {"id":id,"kind":kind,"quantity":quantity,"condition":condition}

static func item_label(entry: Dictionary) -> String:
 if entry.kind=="ammo": return "%s ×%d" % [entry.get("ammo_type","arrows").capitalize(),entry.quantity]
 if entry.kind=="stone": return "Throwing stones ×%d" % entry.quantity
 return "%s · %d%% condition" % [entry.kind.capitalize(),entry.condition]

static func equipped(p: Dictionary,slot: String) -> Dictionary:
 var id=p.get("equipment",{}).get(slot,"")
 for entry in p.inventory:
  if entry.id==id: return entry
 return {}

static func weapon(p: Dictionary) -> String:
 return equipped(p,"weapon").get("kind","unarmed")

static func armour(p: Dictionary) -> String:
 return equipped(p,"body").get("kind","clothing")

static func shield(p: Dictionary) -> bool:
 return equipped(p,"shield").get("condition",0)>0

static func helmet(p: Dictionary) -> bool:
 return not equipped(p,"helmet").is_empty()

static func condition(p: Dictionary) -> int:
 return equipped(p,"weapon").get("condition",100)

static func ammo(p: Dictionary) -> int:
 var count=0
 for entry in p.inventory:
  if entry.kind=="ammo" and entry.get("ammo_type",ammo_kind_for(weapon(p)))==ammo_kind_for(weapon(p)): count+=entry.quantity
 return count

static func consume_ammo(p: Dictionary) -> void:
 for entry in p.inventory:
  if entry.kind=="ammo" and entry.get("ammo_type",ammo_kind_for(weapon(p)))==ammo_kind_for(weapon(p)) and entry.quantity>0:
   entry.quantity-=1
   if entry.quantity==0: p.inventory.erase(entry)
   return

static func hostile(id: String,index: int) -> Dictionary:
 var p=person(id,"Raider %d" % (index+1),"farmer","spear" if index%2==0 else "bow")
 p.melee=43
 p.ranged=40
 p.hp=48
 p.max_hp=48
 equipped(p,"body").kind="clothing"
 p.morale=50
 return p

static func ap(p: Dictionary) -> int:
 if p.hp <= 10: return 0
 var value = 10.0 + p.agility / 12.0 + p.dexterity / 24.0 + p.experience * 0.6
 value *= (0.45 + 0.55 * p.hp / float(p.max_hp)) * (1.0 - p.fatigue / 180.0)
 value *= minf(1.0, (8.0 + p.strength / 4.0) / maxf(1, weight(p)))
 if p.morale < 25: value *= 0.7
 value-=injury(p,"legs")+int(injury(p,"head")/2)
 return clampi(int(value), 4, 26)

static func ammo_kind_for(kind: String) -> String:
 return "bolts" if kind=="crossbow" else ("javelins" if kind=="javelin" else "arrows")

static func injury(p: Dictionary,location: String) -> int:
 var total=0
 for wound in p.get("injuries",[]):
  if wound.location==location: total+=wound.severity
 return mini(8,total)

static func normalize_person(p: Dictionary) -> void:
 if not p.get("inventory") is Array or not p.get("equipment") is Dictionary: return
 if not p.has("injuries"): p.injuries=[]
 for entry in p.get("inventory",[]):
  if not entry is Dictionary: return
  if entry.get("kind","")=="ammo" and not entry.has("ammo_type"): entry.ammo_type=ammo_kind_for(weapon(p))

static func treat(p: Dictionary,skill: int) -> void:
 for wound in p.get("injuries",[]):
  wound.treated=true
  wound.severity=maxi(0,wound.severity-(2 if skill>=60 else 1))
 p.injuries=p.get("injuries",[]).filter(func(w):return w.severity>0)

static func injury_summary(p: Dictionary) -> String:
 var descriptions=[]
 for wound in p.get("injuries",[]): descriptions.append("%s severity %d%s" % [wound.location,wound.severity," (treated)" if wound.treated else ""])
 return "none" if descriptions.is_empty() else "; ".join(descriptions)
