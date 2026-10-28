extends PanelContainer
const Overview=preload("res://ui/battle_overview.gd")
const Tavern=preload("res://ui/tavern_scene.gd")
const PAINTING=preload("res://assets/greywake/scenes/03_tavern_recruitment_interactive_v2.png")
var app
var roster: HBoxContainer
var empty_slots: HBoxContainer
var info: Label
var gear: Label
var overview
var details_button: Button
func _ready() -> void:
 var frame=StyleBoxFlat.new();frame.bg_color=Color("202b27");frame.border_color=Color("827651");frame.set_border_width_all(1);frame.set_content_margin_all(7)
 add_theme_stylebox_override("panel",frame)
 var row=HBoxContainer.new();row.add_theme_constant_override("separation",10);add_child(row)
 var scroll=ScrollContainer.new();scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.custom_minimum_size.x=860;row.add_child(scroll)
 var slots=HBoxContainer.new();scroll.add_child(slots)
 roster=HBoxContainer.new();slots.add_child(roster);app.crew=roster
 empty_slots=HBoxContainer.new();slots.add_child(empty_slots)
 var selected=VBoxContainer.new();selected.custom_minimum_size.x=225;selected.size_flags_horizontal=SIZE_EXPAND_FILL;row.add_child(selected)
 info=app.label(selected,"");info.add_theme_font_size_override("font_size",round(14*app.desktop.ui_scale))
 gear=app.label(selected,"");gear.add_theme_font_size_override("font_size",round(13*app.desktop.ui_scale))
 var actions=HBoxContainer.new();selected.add_child(actions)
 app.button(actions,"Equipment",func():app.change_tab("inventory"))
 details_button=app.button(actions,"Details",func():app.battle_details=not app.battle_details;app.show_panel())
 overview=Overview.new();overview.app=app;row.add_child(overview)
func bar(parent: Node,value: float,maximum: float,color: Color,tip: String) -> void:
 var meter=ProgressBar.new();meter.show_percentage=false;meter.max_value=maxf(1,maximum);meter.value=value
 meter.custom_minimum_size=Vector2(0,5);meter.size_flags_horizontal=SIZE_EXPAND_FILL;meter.mouse_filter=Control.MOUSE_FILTER_IGNORE;meter.tooltip_text=tip
 var fill=StyleBoxFlat.new();fill.bg_color=color;meter.add_theme_stylebox_override("fill",fill)
 var background=StyleBoxFlat.new();background.bg_color=Color("101713");meter.add_theme_stylebox_override("background",background);parent.add_child(meter)
func refresh_roster() -> void:
 for child in roster.get_children(): roster.remove_child(child);child.queue_free()
 for child in empty_slots.get_children(): empty_slots.remove_child(child);child.queue_free()
 var available=app.fighters()
 for i in range(available.size()):
  var unit=available[i];var person=unit.person;var caption=person.name.get_slice(" · ",0)
  if unit.id.begins_with("greywake-recruit-"): caption="#"+unit.id.trim_prefix("greywake-recruit-")
  var choice=app.button(roster,"",app.select_fighter.bind(i));choice.name="crew_"+unit.id
  choice.size_flags_horizontal=SIZE_SHRINK_BEGIN;choice.custom_minimum_size=Vector2(140,144)
  choice.tooltip_text=person.name+" · "+app.Data.weapon(person)+" · %d HP / %d AP"%[person.hp,unit.ap]
  choice.toggle_mode=true;choice.set_pressed_no_signal(unit.id==app.selected)
  var frame=StyleBoxFlat.new();frame.bg_color=Color("30423a") if unit.id==app.selected else Color("1a2420");frame.border_color=Color("efd283") if unit.id==app.selected else Color("5b6856");frame.set_border_width_all(2 if unit.id==app.selected else 1);frame.set_corner_radius_all(3)
  var hover=frame.duplicate();hover.border_color=Color("f4dc9b")
  choice.add_theme_stylebox_override("normal",frame);choice.add_theme_stylebox_override("pressed",frame)
  choice.add_theme_stylebox_override("hover",hover);choice.add_theme_stylebox_override("hover_pressed",hover)
  var box=VBoxContainer.new();box.add_theme_constant_override("separation",2);box.mouse_filter=Control.MOUSE_FILTER_IGNORE;choice.add_child(box);box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);box.offset_left=5;box.offset_right=-5;box.offset_top=4;box.offset_bottom=-4
  var title=Label.new();title.text="%d · %s"%[i+1,caption];title.clip_text=true;title.add_theme_font_size_override("font_size",round(13*app.desktop.ui_scale));title.mouse_filter=Control.MOUSE_FILTER_IGNORE;box.add_child(title)
  var image=TextureRect.new();var template=person.get("template_id","")
  image.texture=Tavern.portrait(PAINTING,template) if Tavern.REGIONS.has(template) else app.Icons.get_icon(person.background)
  image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;image.custom_minimum_size=Vector2(0,66);image.size_flags_vertical=SIZE_EXPAND_FILL;image.mouse_filter=Control.MOUSE_FILTER_IGNORE;box.add_child(image)
  bar(box,person.hp,person.max_hp,Color("80b379"),"Health")
  bar(box,unit.ap,maxi(unit.ap,app.Data.ap(person)),Color("75c9d5"),"Action points")
  bar(box,maxi(0,100-person.fatigue),100,Color("d2ba70"),"Energy")
  var stats=Label.new();stats.text="%d HP · %d AP"%[person.hp,unit.ap];stats.add_theme_font_size_override("font_size",round(12*app.desktop.ui_scale));stats.mouse_filter=Control.MOUSE_FILTER_IGNORE;box.add_child(stats)
 for unused in range(maxi(0,6-available.size())):
  var empty=PanelContainer.new();empty.custom_minimum_size=Vector2(140,144)
  var frame=StyleBoxFlat.new();frame.bg_color=Color("151d19");frame.border_color=Color("3d4b3e");frame.set_border_width_all(1);empty.add_theme_stylebox_override("panel",frame);empty_slots.add_child(empty)
  var title=Label.new();title.text="Empty";title.modulate=Color(.7,.75,.65,.5);title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;empty.add_child(title)
 refresh_info()
func refresh_info() -> void:
 if app.game==null or app.game.battle==null: return
 var b=app.game.battle;var actor=b.unit(app.selected)
 if actor==null: return
 var banner=StyleBoxFlat.new();banner.bg_color=Color("263e2c") if b.t.turn=="company" else Color("4b3029");banner.set_content_margin_all(4)
 app.header.add_theme_stylebox_override("normal",banner)
 info.text=actor.person.name+"\nHP %d/%d · AP %d · Morale %d"%[actor.person.hp,actor.person.max_hp,actor.ap,actor.person.morale]
 gear.text="%s · %s · Ammo %d\n%s / %s · Defence: %s"%[app.Data.weapon(actor.person).capitalize(),app.Data.armour(actor.person),app.Data.ammo(actor.person),actor.stance,actor.mode,actor.get("defence_mode","balanced")]
 if app.target!="" and b.known("company",app.target):
  var victim=b.unit(app.target)
  if victim!=null: gear.text+="\nTarget: "+victim.person.name+" · %d%%"%b.hit_chance(actor,victim,app.aim)
 details_button.set_pressed_no_signal(app.battle_details);details_button.toggle_mode=true
 overview.queue_redraw()
