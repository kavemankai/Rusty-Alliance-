extends Control
const Desktop=preload("res://ui/desktop.gd")
const Icons=preload("res://ui/asset_icons.gd")
signal sector_selected(index: int)
var campaign
var selected=17
var squad="first"
var middle=false
var zoom=0.9
var offset=Vector2(25,15)
var pressed=false
var dragged=false
var down=Vector2.ZERO
var fingers={}

func _ready() -> void:
 mouse_filter=Control.MOUSE_FILTER_STOP
 clip_contents=true
 gui_input.connect(input_event)

func _draw() -> void:
 if campaign==null: return
 var cell=32.0*zoom
 var colors={"road":Color("59534a"),"grass":Color("3b5542"),"forest":Color("283b31"),"hills":Color("605d4a"),"marsh":Color("354b51")}
 for sector in campaign.s.sectors:
  var r=Rect2(offset+Vector2(sector.x,sector.y)*cell,Vector2.ONE*(cell-2))
  var color=colors[sector.terrain]
  if not sector.known: color=color.darkened(0.6)
  if sector.owner=="company": color=Color("286c86")
  if sector.known and sector.owner=="bandits": color=Color("783f38")
  if sector.known and sector.owner=="nobles": color=Color("66507d")
  draw_rect(r,color)
  if sector.id==selected: draw_rect(r,Color("ffd27d"),false,3)
  if sector.known and sector.facility!="":
   var icon=Icons.get_icon(sector.facility)
   if icon!=null: draw_texture_rect(icon,Rect2(r.position+Vector2.ONE*2,r.size-Vector2.ONE*4),false)
   draw_string(ThemeDB.fallback_font,r.position+Vector2(4,cell*0.7),sector.facility.substr(0,1).to_upper(),HORIZONTAL_ALIGNMENT_LEFT,-1,int(16*zoom),Color.WHITE)
 for q in campaign.s.squads.values():
  if q.members.is_empty(): continue
  var center=offset+Vector2(int(q.sector)%16+0.5,int(q.sector/16)+0.5)*cell
  draw_circle(center,6*zoom,Color("8fe5ff"))
  if q.id==squad:
   var prev=center
   for index in q.route:
    var next=offset+Vector2(int(index)%16+0.5,int(index/16)+0.5)*cell
    draw_line(prev,next,Color("ffdd88"),2)
    prev=next
 for j in campaign.s.jobs:
  if j.type=="escort" and j.status=="active" and campaign.s.squads.has(j.squad):
   var q=campaign.s.squads[j.squad]
   var center=offset+Vector2(int(q.sector)%16+0.25,int(q.sector/16)+0.75)*cell
   draw_rect(Rect2(center-Vector2.ONE*4,Vector2.ONE*8),Color("ffd27d"))
 for g in campaign.s.groups:
  if campaign.force_strength(g)>0 and campaign.s.sectors[g.sector].known:
   var center=offset+Vector2(int(g.sector)%16+0.78,int(g.sector/16)+0.25)*cell
   draw_circle(center,4*zoom,Color("ff8d7f"))

func input_event(event: InputEvent) -> void:
 if (event is InputEventMouseButton or event is InputEventMouseMotion) and event.device==InputEvent.DEVICE_ID_EMULATION: return
 if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_MIDDLE:
  middle=event.pressed;accept_event();return
 if event is InputEventMouseMotion and middle: offset+=event.relative;queue_redraw();accept_event();return
 if event is InputEventMouseButton:
  if event.button_index==MOUSE_BUTTON_WHEEL_UP: zoom=clampf(zoom*1.1,0.65,2.8)
  elif event.button_index==MOUSE_BUTTON_WHEEL_DOWN: zoom=clampf(zoom/1.1,0.65,2.8)
  elif event.button_index==MOUSE_BUTTON_LEFT:
   pressed=event.pressed
   if pressed:
    down=event.position
    dragged=false
   elif not dragged:
    select_point(event.position)
 elif event is InputEventMouseMotion and pressed:
  if event.position.distance_to(down)>12: dragged=true
  if dragged and not Desktop.enabled(): offset+=event.relative
 elif event is InputEventPanGesture:
  offset-=event.delta*5.0;dragged=true
 elif event is InputEventMagnifyGesture: zoom=clampf(zoom*event.factor,0.65,2.8)
 elif event is InputEventScreenTouch:
  if event.pressed:
   if fingers.is_empty(): down=event.position;dragged=false
   fingers[event.index]=event.position
   if fingers.size()>1: dragged=true
  else:
   if fingers.has(event.index) and fingers.size()==1 and not dragged and not event.canceled: select_point(event.position)
   fingers.erase(event.index)
 elif event is InputEventScreenDrag and fingers.has(event.index):
  if fingers.size()==2:
   var keys=fingers.keys()
   var other=keys[0] if keys[1]==event.index else keys[1]
   var old=fingers[event.index].distance_to(fingers[other])
   var fresh=event.position.distance_to(fingers[other])
   if old>1 and fresh>1: zoom=clampf(zoom*fresh/old,0.65,2.8)
   offset+=event.relative*0.5
   dragged=true
  elif fingers.size()==1:
   if event.position.distance_to(down)>12: dragged=true
   if dragged: offset+=event.relative
  fingers[event.index]=event.position
 queue_redraw()

func select_point(position: Vector2) -> void:
 var point=(position-offset)/(32.0*zoom)
 var x=int(floor(point.x));var y=int(floor(point.y))
 if x>=0 and x<16 and y>=0 and y<16:
  selected=y*16+x;sector_selected.emit(selected)

func _notification(what: int) -> void:
 if what in [NOTIFICATION_APPLICATION_PAUSED,NOTIFICATION_APPLICATION_FOCUS_OUT]:
  middle=false
  fingers.clear();pressed=false;dragged=true

func reset_camera() -> void:
 zoom=.9;offset=Vector2(24,24);queue_redraw()

func center_on(index: int) -> void:
 var point=offset+Vector2(index%16+.5,int(index/16)+.5)*32*zoom
 offset+=size*.5-point;queue_redraw()
