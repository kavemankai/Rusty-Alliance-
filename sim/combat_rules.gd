extends RefCounted
const Data=preload("res://sim/catalog.gd")
const Items=preload("res://sim/inventory.gd")
const ATTACKS={"normal":{"ap":0,"hit":0,"damage":1.0},"power":{"ap":2,"hit":-12,"damage":1.4},"feint":{"ap":2,"hit":-5,"damage":0.85},"thrust":{"ap":1,"hit":5,"damage":0.9}}
const DEFENCES=["balanced","shield","parry","evade","brace"]
const LOCATIONS=["auto","torso","head","arms","legs"]

static func cost(a: Dictionary,aim: int=0) -> int:
 return Data.WEAPONS[Data.weapon(a.person)].ap+aim+ATTACKS[a.get("attack_style","normal")].ap+(0 if a.get("aim_location","auto")=="auto" else 1)

static func accuracy(a: Dictionary) -> int:
 return ATTACKS[a.get("attack_style","normal")].hit-(15 if a.get("aim_location","auto")=="head" else (0 if a.get("aim_location","auto")=="auto" else 8))-Data.injury(a.person,"arms")*2-Data.injury(a.person,"head")-(8 if a.get("defence_mode","balanced")=="brace" else 0)

static func defence_bonus(b: Dictionary,kind: String) -> int:
 return 15 if b.get("defence_mode","balanced")==kind else 0

static func risk(b,u: Dictionary,x: int,y: int) -> Dictionary:
 var threats=[]
 for other in b.t.units:
  if other.team==u.team or other.person.hp<=10 or not other.guard or not b.known(u.team,other.id): continue
  var weapon=Data.WEAPONS[Data.weapon(other.person)]
  if weapon.reach>0 and other.ap>=weapon.ap and b.distance(u,other)<=weapon.reach and maxi(absi(other.x-x),absi(other.y-y))>weapon.reach: threats.append(other.id)
 var step=b.step_cost(u,b.tile(u.x,u.y),b.tile(x,y))
 return {"threats":threats,"move_ap":step,"disengage_ap":step+4 if step>0 else -1}

static func disengage(b,u: Dictionary,p: Dictionary) -> bool:
 if b.t.phase!="combat": return b.fail("Disengage during combat")
 var dest=b.tile(p.get("x",-1),p.get("y",-1))
 var price=risk(b,u,p.get("x",-1),p.get("y",-1)).disengage_ap
 if dest.is_empty() or price<0 or b.distance(u,dest)!=1 or u.ap<price: return b.fail("Choose an adjacent free tile and reserve step cost plus 4 AP")
 # Deliberate withdrawal suppresses melee opportunities for this single step.
 # Ranged guard reactions still apply through the normal move executor.
 u.ap-=4
 u.disengaging=true
 var result=b.move(u,dest.x,dest.y)
 u.disengaging=false
 u.guard=false
 return result

static func hit(b,a: Dictionary,target: Dictionary,raw: int,kind: String,location: String="auto") -> int:
 if target.role=="cart": location="torso"
 if location=="auto": location=["torso","torso","arms","legs","head"][b.campaign.roll(5)]
 var body=Data.equipped(target.person,"body")
 var armour=int(Data.ARMOUR[Data.armour(target.person)][kind]*body.get("condition",100)/100.0)
 if location=="head":
  armour=int(8*Data.equipped(target.person,"helmet").get("condition",0)/100.0);raw=int(raw*1.3)
 var damage=maxi(1,raw-armour)
 var protection=Data.equipped(target.person,"helmet") if location=="head" else body
 if armour>0 and not protection.is_empty(): protection.condition=maxi(0,protection.condition-1)
 target.person.hp=maxi(0,target.person.hp-damage)
 target.person.wounds+=1
 if not target.person.has("injuries"): target.person.injuries=[]
 target.person.injuries.append({"location":location,"severity":clampi(int(ceil(damage/12.0)),1,5),"treated":false})
 if kind!="blunt" and target.role!="cart": target.person.bleeding+=maxi(1,int(damage/14))
 target.person.morale=maxi(0,target.person.morale-8-int(damage/5))
 a.person.morale=mini(100,a.person.morale+2)
 if target.person.hp==0:
  target.person.dead=true;a.person.kills+=1
  if int(a.person.kills)%3==0: a.person.experience+=1
  for other in b.t.units:
   if other.team==target.team and b.distance(other,target)<7: other.person.morale=maxi(0,other.person.morale-12)
  b.campaign.drop_inventory(target.person,target.x,target.y,b.t.ground)
 b.log_event("%s hit %s %s: %d - %d armour = %d" % [a.person.name,target.person.name,location,raw,armour,damage])
 return damage

static func throw_item(b,u: Dictionary,p: Dictionary) -> bool:
 var entry=Items.find(u.person.inventory,p.get("item",""))
 var target=b.unit(p.get("target",""))
 if b.t.phase!="combat" or entry.is_empty() or entry.kind not in ["stone","dagger","javelin"] or target==null or target.team==u.team or target.person.hp<=0 or not b.known(u.team,target.id) or b.distance(u,target)>6 or not b.los(u,target) or u.ap<6: return b.fail("Throw a carried stone, dagger or javelin at a perceived opponent within six tiles for 6 AP")
 u.ap-=6
 var thrown=entry
 if entry.quantity>1:
  entry.quantity-=1;thrown=Items.create(b.campaign.s,entry.kind,1,entry.condition)
 else:
  u.person.inventory.erase(entry)
  for slot in u.person.equipment.keys():
   if u.person.equipment[slot]==entry.id: u.person.equipment.erase(slot)
 b.t.ground.append({"x":target.x,"y":target.y,"item":thrown})
 var chance=clampi(30+int(u.person.ranged/2)-b.distance(u,target)*4-b.directional_cover(u,target),5,90)
 if b.campaign.roll(100)<chance: hit(b,u,target,9 if entry.kind=="stone" else int(Data.WEAPONS[entry.kind].damage*0.8),"blunt" if entry.kind=="stone" else "pierce")
 else: b.log_event(u.person.name+" missed a throw; item remains on the ground")
 b.refresh_knowledge()
 return true

static func valid_person(p: Dictionary) -> bool:
 if not p.has("injuries"): return false
 if not p.injuries is Array: return false
 for injury in p.injuries:
  if not injury is Dictionary or not injury.has_all(["location","severity","treated"]) or injury.location not in LOCATIONS or injury.location=="auto": return false
  if not (injury.severity is int or injury.severity is float) or injury.severity<0 or injury.severity>5 or injury.severity!=floor(injury.severity) or not injury.treated is bool: return false
 return true

static func parry_chance(a: Dictionary,b: Dictionary) -> int:
 var chance=int(b.person.melee/5)+Data.WEAPONS[Data.weapon(b.person)].defence+defence_bonus(b,"parry")-Data.injury(b.person,"arms")*2
 return maxi(0,int(chance/2) if a.get("attack_style","normal")=="feint" else chance)

static func dodge_chance(a: Dictionary,b: Dictionary) -> int:
 return maxi(0,int(b.person.agility/7)+defence_bonus(b,"evade")-Data.injury(b.person,"legs")*2)

static func charge(b,u: Dictionary,p: Dictionary) -> bool:
 var target=b.unit(p.get("target",""))
 var weapon=Data.WEAPONS[Data.weapon(u.person)]
 if b.t.phase!="combat" or target==null or target.team==u.team or not b.known(u.team,target.id) or weapon.reach<=0 or b.distance(u,target)<2 or b.distance(u,target)>6: return b.fail("Charge a perceived opponent two to six tiles away with a melee weapon")
 var dest=b.tile(target.x-signi(target.x-u.x),target.y-signi(target.y-u.y))
 if dest.is_empty(): return b.fail("No charge destination")
 var route=b.path(u,dest.x,dest.y,true)
 var price=weapon.ap+2+(0 if u.get("aim_location","auto")=="auto" else 1)
 if route.cost<=0 or route.cost+price>u.ap: return b.fail("Reserve movement AP plus the power strike cost")
 if not b.move(u,dest.x,dest.y): return false
 if b.distance(u,target)>weapon.reach or u.person.hp<=10: b.log_event("Charge stopped before striking");return true
 var previous=u.get("attack_style","normal");u.attack_style="power"
 var result=b.attack(u,target)
 u.attack_style=previous
 return result

static func bash(b,u: Dictionary,p: Dictionary) -> bool:
 var target=b.unit(p.get("target",""))
 if b.t.phase!="combat" or not Data.shield(u.person) or target==null or target.team==u.team or target.person.hp<=0 or b.distance(u,target)!=1 or not b.los(u,target) or not b.known(u.team,target.id) or u.ap<5: return b.fail("Shield bash needs a working shield, adjacent perceived opponent and 5 AP")
 u.ap-=5
 var shield=Data.equipped(u.person,"shield");shield.condition=maxi(0,shield.condition-2)
 var chance=clampi(40+int(u.person.melee/2)-int(target.person.agility/4),5,95)
 if b.campaign.roll(100)<chance:
  hit(b,u,target,8+int(u.person.strength/20),"blunt","torso")
  var dest=b.tile(target.x+signi(target.x-u.x),target.y+signi(target.y-u.y))
  if target.role!="cart" and target.person.hp>0 and not dest.is_empty() and not dest.block and b.at(dest.x,dest.y)==null and absi(dest.elevation-b.tile(target.x,target.y).elevation)<=1:
   target.x=dest.x;target.y=dest.y
  target.ap=maxi(0,target.ap-2);target.guard=false
 else: b.log_event(u.person.name+" missed a shield bash")
 b.refresh_knowledge();return true

static func protect(b,u: Dictionary,p: Dictionary) -> bool:
 var ally=b.unit(p.get("target",""))
 if b.t.phase!="combat" or not Data.shield(u.person) or ally==null or ally.id==u.id or ally.team!=u.team or ally.person.hp<=0 or b.distance(u,ally)>1 or u.ap<3: return b.fail("Protect an adjacent ally with a working shield for 3 AP")
 u.ap-=3;u.protecting=ally.id;u.guard=true
 return true

static func intercept(b,attacker: Dictionary,target: Dictionary) -> bool:
 for defender in b.t.units:
  if defender.get("protecting","")!=target.id or defender.team!=target.team or defender.person.hp<=10 or not defender.guard or defender.ap<3 or not Data.shield(defender.person) or b.distance(defender,target)>1 or b.rear(attacker,defender) or not b.visible(defender,attacker): continue
  defender.ap-=3
  var shield=Data.equipped(defender.person,"shield");shield.condition=maxi(0,shield.condition-4)
  b.log_event(defender.person.name+" intercepted part of the attack with a shield")
  return true
 return false

static func charge_preview(b,u: Dictionary,target: Dictionary) -> Dictionary:
 var dest={"x":target.x-signi(target.x-u.x),"y":target.y-signi(target.y-u.y)}
 var route=b.path(u,dest.x,dest.y,true)
 var actor=u.duplicate();actor.attack_style="power"
 return {"movement":route.cost,"strike":cost(actor),"hit":b.hit_chance(actor,target),"reactions":risk(b,u,dest.x,dest.y).threats.size()}
