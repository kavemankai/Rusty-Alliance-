extends Control
var app
func _ready() -> void:
 custom_minimum_size=Vector2(148,100)
 mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
 tooltip_text="Battle overview · click to center the camera. Only observed terrain and visible enemies are shown."
 gui_input.connect(input_event)
func chart() -> Rect2:
 if app.game==null or app.game.battle==null: return Rect2()
 var b=app.game.battle
 var step=minf((size.x-12)/b.t.width,(size.y-12)/b.t.height)
 return Rect2((size-Vector2(b.t.width,b.t.height)*step)*.5,Vector2(b.t.width,b.t.height)*step)
func _draw() -> void:
 draw_rect(Rect2(Vector2.ZERO,size),Color("101916"))
 if app.game==null or app.game.battle==null: return
 var b=app.game.battle;var area=chart();var step=area.size.x/b.t.width
 for y in range(b.t.height):
  for x in range(b.t.width):
   var level=b.Visibility.level(b,x,y)
   var known=b.Visibility.cell(b,x,y)
   var color=Color("101916")
   if level>0:
    color=Color("67705a") if not known.get("block",false) else Color("3e493d")
    if known.get("kind","")=="water": color=Color("365562")
    if level==1: color=color.darkened(.45)
   draw_rect(Rect2(area.position+Vector2(x,y)*step,Vector2.ONE*step),color)
 for id in marker_ids():
  var unit=b.unit(id)
  var point=area.position+(Vector2(unit.x,unit.y)+Vector2.ONE*.5)*step
  draw_circle(point,3.5 if unit.id==app.selected else 2.5,Color("f4d278") if unit.id==app.selected else (Color("83d5d6") if unit.team=="company" else Color("f47b65")))
 draw_rect(area,Color("8c9570"),false,1)
func marker_ids() -> Array:
 if app.game==null or app.game.battle==null: return []
 var b=app.game.battle;var result=[]
 for unit in b.t.units:
  if unit.person.hp>0 and (unit.team=="company" or b.known("company",unit.id)): result.append(unit.id)
 return result
func input_event(event: InputEvent) -> void:
 if not event is InputEventMouseButton or not event.pressed or event.button_index!=MOUSE_BUTTON_LEFT: return
 var area=chart()
 if not area.has_point(event.position): return
 var b=app.game.battle;var point=(event.position-area.position)/area.size*Vector2(b.t.width,b.t.height)
 app.battle_view.center_at(Vector2i(point));accept_event()
