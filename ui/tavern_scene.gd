extends TextureRect
# Normalized regions authored against interactive_v2, never the old backdrop.
# Back row: two militia, Oswin, Ada, Nessa, Sabine. Front: Mara to Ysra.
const REGIONS={
 "militia_spearman":Rect2(.012,.125,.133,.245),
 "militia_crossbowman":Rect2(.175,.155,.135,.225),
 "oswin":Rect2(.345,.125,.135,.255),
 "ada":Rect2(.528,.135,.137,.250),
 "nessa":Rect2(.690,.135,.137,.250),
 "sabine":Rect2(.850,.145,.137,.285),
 "mara":Rect2(.018,.405,.145,.255),
 "bram":Rect2(.180,.385,.150,.275),
 "elin":Rect2(.345,.425,.135,.260),
 "garran":Rect2(.490,.395,.150,.280),
 "roderic":Rect2(.660,.395,.178,.300),
 "ysra":Rect2(.850,.465,.137,.290)
}
var hotspots={}
func _ready() -> void:
 expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 resized.connect(layout_hotspots)
 layout_hotspots()
func picture_rect() -> Rect2:
 if texture==null: return Rect2()
 var pixels=texture.get_size()
 var scale=minf(size.x/pixels.x,size.y/pixels.y)
 var fitted=pixels*scale
 return Rect2((size-fitted)*.5,fitted)
func add_candidate(id: String) -> Button:
 var button=Button.new();button.name="image_"+id
 button.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
 button.set_meta("scene_candidate",true)
 add_child(button);hotspots[id]=button;layout_hotspots()
 return button
func layout_hotspots() -> void:
 var picture=picture_rect()
 for id in hotspots:
  var region=REGIONS[id]
  hotspots[id].position=picture.position+region.position*picture.size
  hotspots[id].size=region.size*picture.size
static func portrait(atlas: Texture2D,id: String) -> AtlasTexture:
 var result=AtlasTexture.new();result.atlas=atlas
 result.region=Rect2(REGIONS[id].position*atlas.get_size(),REGIONS[id].size*atlas.get_size())
 return result
