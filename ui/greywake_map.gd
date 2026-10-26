extends "res://ui/world_map.gd"
const World=preload("res://sim/greywake_world.gd")
const Shipping=preload("res://sim/greywake_shipping.gd")
const BASE=preload("res://assets/greywake/island.svg")
var middle=false
func _init() -> void: zoom=1.0;offset=Vector2.ZERO
func cell_size() -> float: return minf(size.x,size.y)*.09*zoom
func origin() -> Vector2: return (size-Vector2.ONE*cell_size()*10)/2+offset
func point(index: int) -> Vector2: return origin()+Vector2(index%16+.5,int(index/16)+.5)*cell_size()
func _draw() -> void:
 if campaign==null: return
 var step=cell_size();var top=origin()
 draw_rect(Rect2(Vector2.ZERO,size),Color("cbbb99"))
 draw_texture_rect(BASE,Rect2(top,Vector2.ONE*step*10),false)
 # Roads and location ink are separate from the base illustration.
 var roads=World.content().roads
 for raw in roads:
  var id=int(raw)
  for other in campaign.neighbors(id):
   if other>id and other in roads: draw_line(point(id),point(other),Color("b29b70"),maxf(1,zoom*2),true)
 # Fog affects live ownership/force information, not the publicly charted coastline.
 for cell in campaign.s.sectors:
  if cell.get("greywake_land",false) and not cell.known: draw_rect(Rect2(top+Vector2(cell.x,cell.y)*step,Vector2.ONE*step),Color(.25,.22,.17,.12))
 for row in World.content().locations:
  var id=int(row.sector);var p=point(id);var cell=campaign.s.sectors[id]
  draw_circle(p,5*zoom,Color("4d4437"))
  if row.facility=="garrison": draw_rect(Rect2(p-Vector2(5,8)*zoom,Vector2(10,13)*zoom),Color("4d4437"))
  if cell.known:
   var color=Color("3d7478") if cell.owner=="company" else (Color("8a4840") if cell.owner in ["bandits","nobles"] else Color("8b7c55"))
   draw_arc(p,9*zoom,0,TAU,20,color,2)
  var shift=Vector2(10,2)*zoom
  if row.id=="smugglers_cove": shift=Vector2(-105,22)*zoom
  elif row.id=="east_barracks": shift=Vector2(-66,25)*zoom
  elif row.id=="greyhold": shift=Vector2(-45,-19)*zoom
  elif row.id=="pinewood": shift=Vector2(-66,-2)*zoom
  draw_string(ThemeDB.fallback_font,p+shift,row.name,HORIZONTAL_ALIGNMENT_LEFT,-1,int(14*zoom),Color("3e392f"))
 for q in campaign.s.squads.values():
  if q.members.is_empty(): continue
  var p=point(q.sector);draw_circle(p+Vector2(0,-13)*zoom,5*zoom,Color("286774"))
  if q.id==squad:
   var prev=p
   for id in q.route:
    draw_line(prev,point(id),Color("9f6c2c"),3*zoom,true);prev=point(id)
 for j in campaign.s.jobs:
  if j.status in ["available","active"]: draw_string(ThemeDB.fallback_font,point(j.sector)+Vector2(-12,-8)*zoom,"!",HORIZONTAL_ALIGNMENT_LEFT,-1,int(21*zoom),Color("9a6027"))
 for g in campaign.s.groups:
  if campaign.s.sectors[g.sector].known and campaign.force_strength(g)>0: draw_circle(point(g.sector)+Vector2(12,10)*zoom,3*zoom,Color("874839"))
 var port=point(Shipping.dock(campaign.s))+Vector2(-14,20)*zoom
 var colour=Color("3d7478") if Shipping.accessible(campaign.s) else Color("8a4840")
 draw_line(port,port+Vector2(0,-15)*zoom,colour,2)
 draw_polyline(PackedVector2Array([port+Vector2(-8,-3)*zoom,port+Vector2(-4,3)*zoom,port+Vector2(6,3)*zoom,port+Vector2(10,-3)*zoom]),colour,2)
 if World.land(selected): draw_arc(point(selected),13*zoom,0,TAU,28,Color("a57430"),2)
 draw_string(ThemeDB.fallback_font,Vector2(16,28),"GREYWAKE ISLE",HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("433a2d"))
 draw_string(ThemeDB.fallback_font,Vector2(16,size.y-16),"Middle drag / touch drag: pan · Wheel / pinch: zoom",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("5d503a"))
func select_point(position: Vector2) -> void:
 var coord=(position-origin())/cell_size();var x=int(floor(coord.x));var y=int(floor(coord.y))
 if x<0 or y<0 or x>=10 or y>=10: return
 var id=y*16+x
 if World.land(id): selected=id;sector_selected.emit(id)
func input_event(event: InputEvent) -> void:
 if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_MIDDLE:
  middle=event.pressed;accept_event();return
 if event is InputEventMouseMotion and middle: offset+=event.relative;queue_redraw();return
 if event is InputEventMouseMotion and campaign!=null:
  var at=(event.position-origin())/cell_size();var id=int(floor(at.y))*16+int(floor(at.x))
  tooltip_text=campaign.s.sectors[id].name if at.x>=0 and at.y>=0 and at.x<10 and at.y<10 and World.land(id) else "Coastal waters · no overland passage"
 super.input_event(event)
func _notification(what: int) -> void:
 super._notification(what)
 if what==NOTIFICATION_APPLICATION_PAUSED: middle=false
