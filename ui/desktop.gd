extends RefCounted
# Presentation preferences are separate from campaign saves and never alter rules.
const DEFAULT_KEYS={"confirm":KEY_ENTER,"end_turn":KEY_SPACE,"reload":KEY_R,"guard":KEY_G,"next_unit":KEY_TAB,"center":KEY_F,"reset_camera":KEY_HOME,"save":KEY_F5,"load":KEY_F9,"help":KEY_F1,"fullscreen":KEY_F11,"inventory":KEY_I,"company":KEY_C,"contracts":KEY_J,"map":KEY_M}
const TITLES={"confirm":"Confirm preview","end_turn":"End turn","reload":"Reload","guard":"Guard","next_unit":"Next fighter","center":"Center selected fighter","reset_camera":"Reset camera","save":"Save campaign","load":"Load campaign","help":"Controls help","fullscreen":"Fullscreen","inventory":"Inventory","company":"Company","contracts":"Contracts","map":"Map / battle"}
var path="user://desktop-settings.cfg"
var fullscreen=false
var ui_scale=1.0
var render_scale=1.0
var frame_limit=60
var vsync=true
var keys=DEFAULT_KEYS.duplicate()
static func enabled() -> bool: return not OS.has_feature("android") and not OS.has_feature("web")
func load_settings() -> void:
 keys=DEFAULT_KEYS.duplicate()
 var config=ConfigFile.new()
 if config.load(path)!=OK: return
 var value=config.get_value("display","fullscreen",false)
 if value is bool: fullscreen=value
 value=config.get_value("display","ui_scale",1.0)
 if (value is float or value is int) and is_finite(float(value)): ui_scale=clampf(float(value),.9,1.3)
 value=config.get_value("display","render_scale",1.0)
 if (value is float or value is int) and is_finite(float(value)): render_scale=clampf(float(value),.5,1.25)
 value=config.get_value("display","frame_limit",60)
 if value is int and value in [30,60,120,0]: frame_limit=int(value)
 value=config.get_value("display","vsync",true)
 if value is bool: vsync=value
 var proposed={}
 for action in DEFAULT_KEYS:
  value=config.get_value("keys",action,DEFAULT_KEYS[action])
  if not value is int or value<=0 or value in proposed.values() or reserved(value): return
  proposed[action]=value
 keys=proposed
func save_settings() -> Error:
 var config=ConfigFile.new()
 for field in ["fullscreen","ui_scale","render_scale","frame_limit","vsync"]: config.set_value("display",field,get(field))
 for action in keys: config.set_value("keys",action,keys[action])
 return config.save(path)
static func reserved(key: int) -> bool:
 return key in [KEY_ESCAPE,KEY_W,KEY_A,KEY_S,KEY_D,KEY_UP,KEY_DOWN,KEY_LEFT,KEY_RIGHT,KEY_SHIFT,KEY_CTRL,KEY_ALT,KEY_META] or key==(KEY_TAB|KEY_MASK_SHIFT) or key==(KEY_S|KEY_MASK_CTRL)
func bind_key(action: String,key: int) -> String:
 if reserved(key): return "WASD/arrows, Escape, Shift+Tab and Ctrl+S are reserved. Choose another key."
 for other in keys:
  if other!=action and keys[other]==key: return "Already assigned to "+TITLES[other]+". Choose another key."
 keys[action]=key;save_settings();return ""
func matches(action: String,event: InputEventKey) -> bool: return event.get_keycode_with_modifiers()==keys[action]
func key_name(action: String) -> String: return OS.get_keycode_string(keys[action])
func apply_window(window: Window,resize: bool=false) -> void:
 if not enabled(): return
 window.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
 window.content_scale_size=Vector2i.ZERO
 window.min_size=Vector2i(1280,720)
 if resize and not fullscreen:
  var available=DisplayServer.screen_get_usable_rect().size-Vector2i(64,64)
  window.size=Vector2i(clampi(available.x,1280,1600),clampi(available.y,720,900))
 window.mode=Window.MODE_FULLSCREEN if fullscreen else Window.MODE_WINDOWED
 DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)
 Engine.max_fps=frame_limit
func style_button(button: Button) -> void:
 for state in ["normal","hover","pressed","disabled","focus"]:
  var style=StyleBoxFlat.new();style.set_corner_radius_all(4);style.set_content_margin_all(7)
  style.set_content_margin(SIDE_TOP,5);style.set_content_margin(SIDE_BOTTOM,5)
  style.bg_color=Color("222c32") if state=="normal" else Color("34454e")
  if state=="disabled": style.bg_color=Color("192126")
  style.border_color=Color("c5ab73") if state in ["hover","pressed","focus"] else Color("4c5b61")
  style.set_border_width_all(1 if state!="focus" else 2)
  if state=="focus": style.bg_color=Color(0,0,0,0)
  button.add_theme_stylebox_override(state,style)
 button.custom_minimum_size.y=round(34*ui_scale)
 button.add_theme_color_override("font_color",Color("f1e8d5"))
 button.add_theme_color_override("font_disabled_color",Color("7f8b90"))
