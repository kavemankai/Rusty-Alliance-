extends Control
# Contextual presentation of the existing validated controls. No combat rules live here.
var app
var center=Vector2.ZERO
var pages=[]
var roots=[]
var entries=[]
var page=0
var submenu=false
var heading=""
var buttons=[]
var battle_id=0
var actor_id=""
var state_hash=0
var panel: Control
var context_cell=Vector2i.ZERO
var orbit=123.0

func _ready() -> void:
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 mouse_filter=Control.MOUSE_FILTER_IGNORE;hide()
 resized.connect(dismiss)

func context_valid() -> bool:
 return visible and app.game!=null and app.game.battle!=null and app.game.battle.get_instance_id()==battle_id and app.selected==actor_id and app.tab=="sector" and app.game.battle.t.hash()==state_hash

func gather(node: Node) -> Array:
 var result=[]
 if node is Button: result.append(node)
 for child in node.get_children(): result.append_array(gather(child))
 return result

func open_at(point: Vector2,cell: Vector2i) -> void:
 context_cell=cell;app.pan_keys.clear();app.advanced_controls=true;app.show_panel()
 var b=app.game.battle;var actor=b.unit(app.selected)
 if actor==null: return
 battle_id=b.get_instance_id();actor_id=app.selected
 var groups={"Movement":[],"Attack options":[],"Defence":[],"Stance / pace":[],"Support":[],"More":[]}
 var primary={}
 for button in gather(app.side):
  var title=button.text;var entry={"text":title,"source":button,"disabled":button.disabled}
  if title.begins_with("Defence "): entry.disabled=actor.ap<2 or (title.begins_with("Defence shield") and not app.Data.shield(actor.person)) or not b.can_act(actor)
  if title.get_slice(" · ",0) in ["Stand","Crouch","Prone"]: entry.disabled=actor.ap<2 or actor.stance==title.get_slice(" · ",0).to_lower() or not b.can_act(actor)
  if title=="Reload":
   var weapon=app.Data.WEAPONS[app.Data.weapon(actor.person)]
   entry.disabled=weapon.reach>0 or actor.person.loaded or app.Data.ammo(actor.person)<=0 or actor.ap<weapon.reload or not b.can_act(actor)
  if title=="Confirm movement":
   var route=b.path(actor,app.destination.x,app.destination.y,true)
   entry.text="Move\n%d AP"%route.cost;entry.disabled=route.path.is_empty() or route.cost<=0 or not b.can_act(actor) or (b.t.phase=="combat" and route.cost>actor.ap)
   primary=entry;continue
  if title=="Confirm attack":
   var victim=b.unit(app.target)
   if victim==null or not b.known("company",victim.id): continue
   var cost=b.Combat.cost(actor,app.aim)
   var weapon=app.Data.WEAPONS[app.Data.weapon(actor.person)]
   entry.text="Attack\n%d%% · %d AP"%[b.hit_chance(actor,victim,app.aim),cost]
   entry.disabled=not b.can_act(actor) or actor.ap<cost or b.t.phase!="combat" or b.distance(actor,victim)>weapon.range or not b.los(actor,victim) or (weapon.reach==0 and (not actor.person.loaded or app.Data.ammo(actor.person)<=0))
   primary=entry;continue
  if title=="Confirm placement": primary=entry;continue
  if title.begins_with("Aim ") or title.begins_with("Aim at:") or title.begins_with("Attack style:") or title.begins_with("Charge target") or title.begins_with("Shield bash") or title.begins_with("Throw ") or title=="Reload": groups["Attack options"].append(entry)
  elif title.begins_with("Order ") or title.begins_with("Disengage") or title.begins_with("Open / close") or title.begins_with("Build ") or title.begins_with("Rotate facing") or title.begins_with("Approach from"): groups.Movement.append(entry)
  elif title.begins_with("Defence ") or title.begins_with("Prepare defence") or title.begins_with("Guard / "): groups.Defence.append(entry)
  elif title.get_slice(" · ",0) in ["Stand","Crouch","Prone","Walk","Run","Cautious"]: groups["Stance / pace"].append(entry)
  elif title.begins_with("Rally ") or title.begins_with("Aid ") or title.begins_with("Protect ") or title.begins_with("Repair ") or title.begins_with("First aid") or title.begins_with("Loot "): groups.Support.append(entry)
  elif title=="Toggle roofs" or title.begins_with("Turn 45") or title=="Resume exploration": groups.More.append(entry)
 if b.t.phase=="deployment":
  groups.More.append({"text":"Begin combat","call":app.run_command.bind("confirm_deployment",{}),"disabled":false})
  groups.More.append({"text":"Scout before contact","call":app.run_command.bind("confirm_deployment",{"explore":true}),"disabled":false})
 elif b.t.phase=="exploration":
  groups.More.append({"text":"Wait / scout","call":app.run_command.bind("explore_wait",{}),"disabled":false})
  if not b.t.get("peaceful",false): groups.More.append({"text":"Enter combat","call":app.run_command.bind("combat",{}),"disabled":false})
 else: groups.More.append({"text":"End turn","call":app.end_player_turn,"disabled":b.t.turn!="company"})
 groups.More.append({"text":"Equipment","call":app.change_tab.bind("inventory"),"disabled":false})
 groups.More.append({"text":"Full details","call":show_details,"disabled":false})
 roots=[]
 if not primary.is_empty(): roots.append(primary)
 for group in groups:
  if not groups[group].is_empty(): roots.append({"text":group,"children":groups[group],"disabled":false})
 heading=actor.person.name.get_slice(" · ",0)+"\n%d AP · %d:%d"%[actor.ap,cell.x,cell.y]
 var field=app.battle_view.get_global_rect()
 orbit=clampf((field.size.y-60)*.5,100,123)
 var padding=Vector2(orbit+60,orbit+28)
 var minimum=field.position+padding
 center=Vector2(clampf(point.x,minimum.x,maxf(minimum.x,field.end.x-padding.x)),clampf(point.y,minimum.y,maxf(minimum.y,field.end.y-padding.y)))
 state_hash=b.t.hash();submenu=false;page=0;entries=roots;show();render()

func show_details() -> void:
 app.battle_details=true;app.show_panel()

func caption(value: String) -> String:
 if value.begins_with("Attack\n"): return value
 var result=value.replace("Charge target · movement + power strike","Charge").replace("Guard / disengagement reaction","Guard").replace("Confirm placement","Place here").replace("Disengage to tile","Disengage")
 if result.begins_with("Defence "): result=result.trim_prefix("Defence ").capitalize()
 return result.replace(" · ","\n")

func render() -> void:
 if panel!=null: remove_child(panel);panel.queue_free()
 panel=Control.new();panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);panel.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(panel);buttons=[]
 var per_page=6 if entries.size()<=6 else 5
 var total=int(ceil(entries.size()/float(per_page)));var first=page*per_page;var shown=entries.slice(first,mini(first+per_page,entries.size()))
 if total>1: shown.append({"text":"Next %d/%d"%[page+1,total],"next":true,"disabled":false})
 for i in range(shown.size()):
  var entry=shown[i];var angle=-PI*.5+i*TAU/6.0
  var button=Button.new();button.text=caption(entry.text);button.tooltip_text=entry.text;button.clip_text=true
  button.add_theme_font_size_override("font_size",13);app.desktop.style_button(button)
  button.position=center+Vector2(cos(angle),sin(angle))*orbit-Vector2(58,26);button.size=Vector2(116,52);button.custom_minimum_size=Vector2(116,52)
  button.disabled=entry.disabled;button.set_meta("radial_entry",entry.text);panel.add_child(button);buttons.append(button)
  button.pressed.connect(activate.bind(entry))
 var label=Label.new();label.text=heading;label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;label.add_theme_font_size_override("font_size",12);label.position=center-Vector2(70,34);label.size=Vector2(140,44);label.mouse_filter=Control.MOUSE_FILTER_IGNORE;panel.add_child(label)
 var back=Button.new();back.text="Back" if submenu else "Cancel";app.desktop.style_button(back);back.position=center+Vector2(-42,16);back.size=Vector2(84,34);panel.add_child(back);buttons.append(back)
 back.pressed.connect(func():
  if submenu: submenu=false;page=0;entries=roots;render()
  else: dismiss())
 for i in range(buttons.size()):
  var next=buttons[(i+1)%buttons.size()].get_path();var previous=buttons[posmod(i-1,buttons.size())].get_path()
  buttons[i].focus_next=next;buttons[i].focus_previous=previous
  buttons[i].focus_neighbor_right=next;buttons[i].focus_neighbor_left=previous
  buttons[i].focus_neighbor_bottom=next;buttons[i].focus_neighbor_top=previous
 for button in buttons:
  if not button.disabled: button.grab_focus();break
 queue_redraw()

func activate(entry: Dictionary) -> void:
 if not context_valid(): dismiss();app.status("Context changed; choose the tile or target again.");return
 if entry.disabled: return
 if entry.has("next"): page=posmod(page+1,int(ceil(entries.size()/5.0)));render();return
 if entry.has("children"): entries=entry.children;submenu=true;page=0;render();return
 var source=entry.get("source")
 var callback=entry.get("call",Callable())
 if source!=null and (not is_instance_valid(source) or source.disabled): dismiss();return
 # Run the same internal callable synchronously, preventing a deferred actor switch.
 var connections=source.get_signal_connection_list("pressed") if source!=null else []
 dismiss()
 if callback.is_valid(): callback.call()
 else:
  for connection in connections: connection.callable.call()

func dismiss() -> void:
 hide();get_viewport().gui_release_focus();queue_redraw()

func _input(event: InputEvent) -> void:
 if not visible: return
 if event is InputEventKey and event.pressed and event.keycode==KEY_SPACE:
  get_viewport().set_input_as_handled();return
 if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
  dismiss();get_viewport().set_input_as_handled();return
 if event is InputEventMouseButton and event.pressed:
  if event.button_index in [MOUSE_BUTTON_MIDDLE,MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]: dismiss();return
  if event.button_index==MOUSE_BUTTON_RIGHT: dismiss();get_viewport().set_input_as_handled();return
  if event.button_index==MOUSE_BUTTON_LEFT:
   for button in buttons:
    if button.get_global_rect().has_point(event.position): return
   dismiss()
   if event.position.distance_to(center)<orbit+65: get_viewport().set_input_as_handled()

func _draw() -> void:
 if visible:
  draw_circle(center,orbit-32,Color(.035,.055,.045,.92))
  draw_arc(center,orbit-32,0,TAU,64,Color("8d8259"),2,true)
