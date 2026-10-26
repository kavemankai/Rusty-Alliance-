extends RefCounted

static func contact(b) -> bool:
 for team in ["company","enemy"]:
  for info in b.t.knowledge[team].values():
   if info.visible: return true
 return false

static func current_contact(b) -> bool:
 for observer in b.t.units:
  if observer.person.hp<=10: continue
  for other in b.t.units:
   if other.team!=observer.team and other.person.hp>0 and b.visible(observer,other): return true
 return false

static func begin(b) -> bool:
 b.t.phase="exploration"
 b.t.turn="company"
 b.t.quiet_rounds=0
 var elapsed=b.t.get("exploration",{}).get("elapsed",0)
 b.t.exploration={"elapsed":elapsed,"orders":{},"patrol":{},"running":false}
 for u in b.t.units:
  u.guard=false
  if u.team=="enemy" and u.person.hp>10: b.t.exploration.patrol[u.id]={"x":u.x,"y":u.y,"side":1}
 b.refresh_knowledge()
 if b.t.phase=="exploration": b.log_event("Exploration: movement and waiting advance local patrols")
 return true

static func combat(b,reason: String) -> void:
 b.t.phase="combat"
 b.t.turn="company"
 b.t.quiet_rounds=0
 b.t.exploration.orders.clear()
 b.t.exploration.running=false
 b.log_event(reason+"; company turn begins with remaining AP")

static func order(b,id: String,x: int,y: int) -> bool:
 if b.t.phase!="exploration": return b.fail("Not exploring")
 var actor=b.unit(id)
 if actor==null or actor.team!="company" or actor.person.hp<=10 or b.outcome()!="ongoing": return b.fail("Select a capable company fighter")
 var route=b.path(actor,x,y,true)
 if route.cost<=0: return b.fail("Unreachable exploration destination")
 b.t.exploration.orders[id]=route.path.duplicate()
 if b.t.exploration.get("running",false): return true
 # Commands are discrete. Each local pulse moves both sides at most one tile.
 # Stop immediately on detection; never execute the rest of a queued path.
 for i in range(512):
  if b.t.phase!="exploration" or not b.t.exploration.orders.has(id) or b.outcome()!="ongoing": break
  advance(b,1)
 return true

static func step(b,u: Dictionary,cell: Dictionary) -> bool:
 var cost=b.step_cost(u,b.tile(u.x,u.y),cell)
 if cost<0 or cost>u.ap: return false
 u.ap-=cost
 u.facing=b.heading(cell.x-u.x,cell.y-u.y)
 u.x=cell.x;u.y=cell.y
 u.person.fatigue=mini(100,u.person.fatigue+(b.Data.Skills.running_fatigue(u.person) if u.mode=="run" else 1))
 b.refresh_knowledge()
 return true

static func advance(b,count: int=1) -> bool:
 if b.t.phase!="exploration" or b.outcome()!="ongoing": return b.fail("No active exploration")
 if count<1 or count>16: return b.fail("Advance 1 to 16 local exploration pulses")
 for pulse in range(count):
  b.refresh_knowledge()
  if b.t.phase!="exploration": break
  var e=b.t.exploration
  e.elapsed+=1
  for u in b.t.units:
   if u.person.hp<=0: continue
   u.ap=mini(b.Data.ap(u.person),u.ap+2)
   if e.elapsed%10==0 and u.person.bleeding>0:
    u.person.hp=maxi(0,u.person.hp-u.person.bleeding)
    if u.person.hp==0:
     u.person.dead=true
     b.campaign.drop_inventory(u.person,u.x,u.y,b.t.ground)
  if b.outcome()!="ongoing":
   e.orders.clear();e.running=false
   break
  var ids=e.orders.keys();ids.sort()
  for id in ids:
   var u=b.unit(id)
   var route=e.orders[id]
   if u==null or u.person.hp<=10 or route.is_empty(): e.orders.erase(id);continue
   var cell=b.t.tiles[route[0]]
   if b.step_cost(u,b.tile(u.x,u.y),cell)<0:
    e.orders.erase(id);b.log_event("Exploration path obstructed");continue
   if step(b,u,cell):
    # Detection clears all orders, including this reference's dictionary key.
    if b.t.phase!="exploration": return true
    route.pop_front()
    if route.is_empty(): e.orders.erase(id)
  for u in b.t.units:
   if b.t.phase!="exploration": return true
   if u.team!="enemy" or u.person.hp<=10: continue
   var anchor=e.patrol.get(u.id,{"x":u.x,"y":u.y,"side":1})
   e.patrol[u.id]=anchor
   var target=b.tile(anchor.x+anchor.side,anchor.y) if u.x==anchor.x and u.y==anchor.y else b.tile(anchor.x,anchor.y)
   if target.is_empty() or b.step_cost(u,b.tile(u.x,u.y),target)<0:
    anchor.side=-anchor.side
    continue
   step(b,u,target)
  if b.t.phase!="exploration": break
 return true

static func valid(t: Dictionary) -> bool:
 if t.has("quiet_rounds") and (not integer(t.quiet_rounds) or t.quiet_rounds<0 or t.quiet_rounds>3): return false
 if not t.has("exploration"): return t.get("phase","combat")!="exploration"
 var e=t.exploration
 if e is Dictionary and not e.get("running",false) is bool: return false
 if not e is Dictionary or not e.has_all(["elapsed","orders","patrol"]) or not integer(e.elapsed) or e.elapsed<0 or not e.orders is Dictionary or not e.patrol is Dictionary: return false
 var units={}
 for u in t.units: units[u.id]=u
 for id in e.orders:
  if not units.has(id) or units[id].team!="company" or not e.orders[id] is Array: return false
  var last=Vector2i(units[id].x,units[id].y)
  for index in e.orders[id]:
   if not integer(index) or index<0 or index>=t.tiles.size(): return false
   var cell=t.tiles[int(index)]
   if maxi(absi(cell.x-last.x),absi(cell.y-last.y))!=1: return false
   last=Vector2i(cell.x,cell.y)
 for id in e.patrol:
  var p=e.patrol[id]
  if not units.has(id) or units[id].team!="enemy" or not p is Dictionary or not p.has_all(["x","y","side"]): return false
  if not integer(p.x) or not integer(p.y) or p.x<0 or p.y<0 or p.x>=t.width or p.y>=t.height or not integer(p.side) or p.side not in [-1,1]: return false
 if t.get("phase","combat")!="exploration" and not e.orders.is_empty(): return false
 return true

static func integer(value: Variant) -> bool:
 return (value is int or value is float) and value==floor(value)
