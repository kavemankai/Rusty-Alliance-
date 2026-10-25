extends RefCounted

static func ensure(b) -> void:
 if not b.t.has("fog"): b.t.fog={"company":{},"enemy":{}}
 b.t.sight={"company":{},"enemy":{}}

static func reveal(b,team: String,cell: Dictionary) -> void:
 var key=str(int(cell.y)*int(b.t.width)+int(cell.x))
 b.t.sight[team][key]=true
 if b.t.fog[team].get(key,{})!=cell: b.t.fog[team][key]=cell.duplicate(true)

static func refresh(b) -> void:
 var terrain_hash=b.t.tiles.hash()
 b.lighting(terrain_hash)
 var signature=[b.t.get("night",false),b.t.get("active_entry","west"),b.t.phase,b.t.width,b.t.height,terrain_hash]
 for u in b.t.units: signature.append([u.id,u.x,u.y,u.facing,u.person.hp,u.person.perception])
 var stamp=signature.hash()
 if b.fog_signature==stamp: return
 b.fog_signature=stamp
 ensure(b)
 if b.t.phase=="deployment":
  for zone in b.t.get("active_zones",b.t.get("deployment_zones",[{"x":0,"y":0,"w":mini(6,int(b.t.width)),"h":b.t.height}])):
   for y in range(zone.y,zone.y+zone.h):
    for x in range(zone.x,zone.x+zone.w): reveal(b,"company",b.tile(x,y))
  return
 for observer in b.t.units:
  if observer.person.hp<=0: continue
  reveal(b,observer.team,b.tile(observer.x,observer.y))
  if observer.person.hp<=10: continue
  var stamp_observer=[observer.x,observer.y,observer.facing,observer.person.perception,b.t.get("night",false),terrain_hash].hash()
  var entry=b.fog_observers.get(observer.id,{})
  if entry.get("stamp",-1)!=stamp_observer:
   var cells=[]
   var radius=8+int(observer.person.perception/10)
   for y in range(maxi(0,observer.y-radius),mini(b.t.height,observer.y+radius+1)):
    for x in range(maxi(0,observer.x-radius),mini(b.t.width,observer.x+radius+1)):
     var cell=b.tile(x,y)
     if b.visible(observer,cell): cells.append(y*int(b.t.width)+x)
   entry={"stamp":stamp_observer,"cells":cells}
   b.fog_observers[observer.id]=entry
  for index in entry.cells: reveal(b,observer.team,b.t.tiles[index])

static func level(b,x: int,y: int,team: String="company") -> int:
 var key=str(y*int(b.t.width)+x)
 if b.t.get("sight",{}).get(team,{}).has(key): return 2
 return 1 if b.t.get("fog",{}).get(team,{}).has(key) else 0

static func cell(b,x: int,y: int,team: String="company") -> Dictionary:
 if x<0 or y<0 or x>=b.t.width or y>=b.t.height: return {}
 var cached=b.t.get("fog",{}).get(team,{}).get(str(y*int(b.t.width)+x),{})
 if not cached.is_empty(): return cached
 # Unknown terrain is provisional open ground; it never reads hidden obstacles.
 return {"x":x,"y":y,"cost":2,"elevation":0,"block":false,"cover":0,"conceal":0,"door":false,"open":false,"kind":"unknown"}

static func valid(field: Dictionary) -> bool:
 if not field.has("fog"): return true
 if not field.fog is Dictionary or not field.fog.has_all(["company","enemy"]): return false
 for team in ["company","enemy"]:
  var records=field.fog[team]
  if not records is Dictionary or records.size()>field.width*field.height: return false
  for key in records:
   if not key is String or not key.is_valid_int() or str(int(key))!=key or int(key)<0 or int(key)>=field.width*field.height: return false
   var c=records[key]
   if not c is Dictionary or not c.has_all(["x","y","cost","elevation","block","cover","conceal","door","open","kind"]): return false
   for stat in ["x","y","cost","elevation","cover","conceal"]:
    if not (c[stat] is int or c[stat] is float) or c[stat]!=floor(c[stat]): return false
   if c.x<0 or c.y<0 or c.x>=field.width or c.y>=field.height or c.y*field.width+c.x!=int(key) or c.cost<1 or not c.kind is String: return false
   for flag in ["block","door","open"]:
    if not c[flag] is bool: return false
 return true
