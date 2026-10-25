extends RefCounted
const META=["layout","layout_version","deployment_zones","enemy_spawns"]
const KINDS=["farm","settlement","mine","camp","wilderness"]

static func create(sector: Dictionary) -> Dictionary:
 var kind="wilderness"
 if sector.facility=="farm": kind="farm"
 elif sector.facility=="mine": kind="mine"
 elif sector.facility=="camp": kind="camp"
 elif sector.facility in ["market","workshop","garrison","training"]: kind="settlement"
 var field={"width":18,"height":14,"tiles":[],"ground":[],"layout":kind,"layout_version":1,"deployment_zones":[{"x":0,"y":0,"w":6,"h":14}],"enemy_spawns":[]}
 for y in range(14):
  for x in range(18):
   field.tiles.append({"x":x,"y":y,"cost":2,"elevation":0,"block":false,"cover":0,"conceal":0,"door":false,"open":false,"kind":"grass"})
 field.entry_zones={"west":field.deployment_zones.duplicate(true),"east":[{"x":15,"y":0,"w":3,"h":14}],"north":[{"x":0,"y":0,"w":18,"h":2}],"south":[{"x":0,"y":12,"w":18,"h":2}]}
 var preferred=[Vector2i(11,3),Vector2i(12,6),Vector2i(13,9)]
 match kind:
  "farm":
   field.deployment_zones=[{"x":0,"y":1,"w":6,"h":12}]
   for y in range(2,12): paint(field,7,y,{"block":true,"kind":"wall"})
   door(field,7,6)
   paint(field,7,4,{"kind":"window"})
   for y in range(9,14):
    for x in range(10,18): paint(field,x,y,{"elevation":1,"cost":3,"kind":"hill"})
   for y in [3,4,8,9]: paint(field,5,y,{"cover":25,"kind":"barricade"})
   for y in [4,5]: paint(field,10,y,{"conceal":20,"cost":4,"kind":"brush"})
   for y in [10,12]:
    for x in range(12,17): paint(field,x,y,{"cost":4,"conceal":25,"kind":"crop"})
  "settlement":
   for x in range(18):
    for y in [6,7]: paint(field,x,y,{"kind":"road","cost":1})
   house(field,9,1,4,4,10,4)
   house(field,11,9,5,4,12,9)
   for point in [Vector2i(6,3),Vector2i(8,8),Vector2i(14,6)]: paint(field,point.x,point.y,{"kind":"stall","cover":30})
   preferred=[Vector2i(11,6),Vector2i(14,8),Vector2i(15,3)]
  "mine":
   field.deployment_zones=[{"x":0,"y":0,"w":5,"h":14}]
   for y in range(5,12): paint(field,9,y,{"block":true,"kind":"rock"})
   paint(field,9,7,{"block":false,"kind":"road","cost":1})
   for y in range(8,14):
    for x in range(12,18): paint(field,x,y,{"elevation":1,"kind":"quarry","cost":3})
   house(field,13,1,4,5,14,5)
   for point in [Vector2i(6,5),Vector2i(11,8),Vector2i(14,10)]: paint(field,point.x,point.y,{"kind":"ore","cover":35})
  "camp":
   field.deployment_zones=[{"x":0,"y":0,"w":5,"h":6},{"x":0,"y":8,"w":5,"h":6}]
   for y in range(2,12): paint(field,8,y,{"block":true,"kind":"palisade"})
   door(field,8,6)
   paint(field,8,10,{"block":false,"kind":"road"})
   for point in [Vector2i(11,2),Vector2i(14,5),Vector2i(12,10)]: paint(field,point.x,point.y,{"kind":"tent","cover":25,"cost":3})
   for x in range(10,16): paint(field,x,12,{"kind":"brush","conceal":35,"cost":4})
  "wilderness":
   for y in range(3,12):
    for x in range(8,17):
     if (x+y+int(sector.id))%5==0:
      paint(field,x,y,{"kind":"brush","conceal":25,"cost":4})
   if sector.terrain=="road":
    for x in range(18): paint(field,x,6,{"kind":"road","cost":1})
   elif sector.terrain=="hills":
    for y in range(8,14):
     for x in range(10,18): paint(field,x,y,{"kind":"hill","elevation":1,"cost":3})
   elif sector.terrain=="marsh":
    for y in range(4,11):
     for x in range(9,14): paint(field,x,y,{"kind":"mud","cost":5})
   elif sector.terrain=="forest":
    for y in [2,5,8,11]: paint(field,10,y,{"kind":"tree","block":true})
 field.entry_zones.west=field.deployment_zones.duplicate(true)
 if kind=="settlement" and sector.facility=="training":
  for x in [6,8,10]: paint(field,x,10,{"kind":"dummy","cover":15})
 if kind=="settlement" and sector.facility=="workshop": paint(field,7,3,{"kind":"workbench","cover":30})
 for point in preferred:
  if not field.tiles[point.y*18+point.x].block: field.enemy_spawns.append({"x":point.x,"y":point.y})
 for y in range(2,12):
  for x in range(10,17):
   var point={"x":x,"y":y}
   if not field.tiles[y*18+x].block and point not in field.enemy_spawns: field.enemy_spawns.append(point)
 return field

static func paint(field: Dictionary,x: int,y: int,values: Dictionary) -> void:
 field.tiles[y*int(field.width)+x].merge(values,true)

static func door(field: Dictionary,x: int,y: int) -> void:
 paint(field,x,y,{"block":true,"kind":"door","door":true,"open":false})

static func house(field: Dictionary,x: int,y: int,w: int,h: int,dx: int,dy: int) -> void:
 for cy in range(y,y+h):
  for cx in range(x,x+w):
   var edge=cx==x or cy==y or cx==x+w-1 or cy==y+h-1
   paint(field,cx,cy,{"kind":"wall" if edge else "floor","block":edge,"room":"%d_%d" % [x,y],"roof":true,"interior":not edge})
 door(field,dx,dy)

static func valid_metadata(field: Dictionary) -> bool:
 var present=0
 for key in META:
  if field.has(key): present+=1
 if present==0: return true # Older battlefields retain their exact geometry.
 if present!=META.size() or field.layout not in KINDS or field.layout_version!=1: return false
 if field.has("entry_zones"):
  if not field.entry_zones is Dictionary: return false
  for direction in field.entry_zones:
   if direction not in ["north","south","east","west"] or not valid_zones(field.entry_zones[direction],field.width,field.height): return false
 if not field.deployment_zones is Array or field.deployment_zones.is_empty() or not field.enemy_spawns is Array or field.enemy_spawns.is_empty(): return false
 for zone in field.deployment_zones:
  if not zone is Dictionary or not zone.has_all(["x","y","w","h"]): return false
  for key in ["x","y","w","h"]:
   if not integer(zone[key]): return false
  if zone.x<0 or zone.y<0 or zone.w<1 or zone.h<1 or zone.x+zone.w>field.width or zone.y+zone.h>field.height: return false
 for point in field.enemy_spawns:
  if not point is Dictionary or not point.has_all(["x","y"]) or not integer(point.x) or not integer(point.y): return false
  if point.x<0 or point.y<0 or point.x>=field.width or point.y>=field.height: return false
 return true

static func integer(value: Variant) -> bool:
 return (value is int or value is float) and value==floor(value)

static func valid_zones(zones: Variant,w: int,h: int) -> bool:
 if not zones is Array or zones.is_empty(): return false
 for zone in zones:
  if not zone is Dictionary or not zone.has_all(["x","y","w","h"]): return false
  for key in ["x","y","w","h"]:
   if not integer(zone[key]): return false
  if zone.x<0 or zone.y<0 or zone.w<1 or zone.h<1 or zone.x+zone.w>w or zone.y+zone.h>h: return false
 return true
