extends RefCounted
# User-supplied UI art only. Concept boards and unmapped faces never enter runtime.
const Desktop=preload("res://ui/desktop.gd")
const ROOT="res://assets/greywake/production_ui/"
static func skin(file: String,margin: float=12.0) -> StyleBoxTexture:
 var style=StyleBoxTexture.new();style.texture=load(ROOT+file)
 for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:
  style.set_texture_margin(side,12.0);style.set_content_margin(side,margin)
 return style
static func panel() -> StyleBoxTexture:
 var style=skin("tavern_profile_panel_550x700.png",40.0)
 for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]: style.set_texture_margin(side,64.0)
 return style
static func apply_button(button: Button) -> void:
 for state in ([] if Desktop.enabled() else ["normal","hover","pressed","disabled"]):
  var file={"normal":"normal","hover":"hover","pressed":"selected","disabled":"disabled"}[state]
  var style=skin("button_"+file+".png",6.0)
  style.set_content_margin(SIDE_TOP,4.0);style.set_content_margin(SIDE_BOTTOM,4.0)
  button.add_theme_stylebox_override(state,style)
 var key=""
 var title=button.text.to_lower()
 if title in ["harbour","recruitment harbour"]: key="anchor"
 elif title=="set sail" or title=="confirm departure": key="ship"
 elif title.begins_with("recruit ") or title.begins_with("hire passenger "): key="recruit"
 if key!="":
  button.icon=load(ROOT+key+"_256.png");button.expand_icon=true
  button.add_theme_constant_override("icon_max_width",22)

static func harbour_image(s: Dictionary) -> Texture2D:
 var file="06_dock_town_1920x1080.png"
 for vessel in s.shipping.vessels:
  if vessel.status=="offshore": file="08_offshore_blockade_1920x1080.png";break
  if vessel.status=="docked" and s.time<vessel.recruitment_deadline: file="05_recruitment_vessel_1920x1080.png"
 return load("res://assets/greywake/scenes/"+file)
