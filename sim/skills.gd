extends RefCounted
const R=preload("res://sim/records.gd")
const ATTRIBUTES=["strength","agility","dexterity","endurance","perception","wisdom","leadership"]
const ALL=["melee","ranged","medical","smithing","stealth","fieldcraft","athletics"]
const ADDED=["stealth","fieldcraft","athletics"]
const LEGACY_BASE=40

static func normalize(p: Dictionary) -> void:
 for key in ADDED:
  if not p.has(key): p[key]=LEGACY_BASE
 if not p.has("training_skill"): p.training_skill="melee"
 if not p.has("training_bank"):
  p.training_bank={}
  for key in ALL: p.training_bank[key]=p.get("training",0) if key==p.training_skill else 0
 if not p.has("trained_hour"): p.trained_hour=-1

static func valid(p: Dictionary,strict: bool=false) -> bool:
 for key in ADDED:
  if not p.has(key):
   if strict: return false
  elif not R.integer(p[key],0,100): return false
 if p.has("training_skill") and p.training_skill not in ALL: return false
 if p.has("trained_hour") and not R.integer(p.trained_hour,-1): return false
 if p.has("training_bank"):
  if not p.training_bank is Dictionary or p.training_bank.size()!=ALL.size(): return false
  for key in ALL:
   if not R.integer(p.training_bank.get(key),0,11): return false
  if p.training_bank.get(p.get("training_skill","melee"),-1)!=p.get("training",0): return false
 elif strict: return false
 return not strict or p.has_all(["training_skill","trained_hour"])

static func select_training(p: Dictionary,key: String) -> bool:
 if key not in ALL: return false
 p.training_bank[p.training_skill]=p.training
 p.training_skill=key
 p.training=int(p.training_bank[key])
 return true

static func train(p: Dictionary,hour: int,facility: bool) -> bool:
 if p.trained_hour>=hour or not p.hired or p.dead or p.get("captured",false) or p.hp<=10: return false
 p.trained_hour=hour
 var key=p.training_skill
 if p[key]>=95: return false
 p.training+=1+int(p.wisdom/40)+(2 if facility else 0)
 if p.training>=12:
  p.training-=12;p[key]+=1
 p.training_bank[key]=p.training
 return true

static func advantage(p: Dictionary,key: String) -> int:
 # Forty is a neutral legacy baseline, preserving pre-update save behaviour.
 return maxi(0,int(p.get(key,LEGACY_BASE))-LEGACY_BASE)

static func wilderness_cost(p: Dictionary,cell: Dictionary,base: int,layout: String) -> int:
 if layout!="wilderness" or cell.get("kind","") not in ["grass","brush","hill","mud","forest"] or base<=2: return base
 return maxi(2,base-mini(2,int(advantage(p,"fieldcraft")/25)))

static func running_fatigue(p: Dictionary) -> int:
 return maxi(1,5-int(p.endurance/20)-int(advantage(p,"athletics")/20))

static func withdrawal_fatigue(p: Dictionary) -> int:
 return maxi(4,10-int(advantage(p,"athletics")/10))

static func withdrawal_ap(p: Dictionary) -> int:
 return maxi(2,4-int(advantage(p,"athletics")/20))

static func stealth_reduction(target: Dictionary,cell: Dictionary) -> int:
 if not target.has("person") or target.get("mode","walk")=="run" or cell.get("conceal",0)<=0: return 0
 if target.get("mode","walk")!="cautious" and target.get("stance","stand") not in ["crouch","prone"]: return 0
 return mini(4,int(advantage(target.person,"stealth")/12))
