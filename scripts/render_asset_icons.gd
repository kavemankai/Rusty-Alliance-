extends SceneTree
const Art=preload("res://ui/asset_visuals.gd")
const Thumbnails=preload("res://scripts/thumbnail_catalog.gd")
var viewport: SubViewport
var stage: Node3D
func _init() -> void: call_deferred("run")
func run() -> void:
 DirAccess.make_dir_recursive_absolute("res://assets/ui/icons")
 viewport=SubViewport.new();viewport.size=Vector2i(192,192)
 viewport.transparent_bg=true
 viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
 root.add_child(viewport)
 stage=Node3D.new();viewport.add_child(stage)
 var camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL
 camera.size=2.2;camera.position=Vector3(3,2.4,3)
 stage.add_child(camera);camera.look_at(Vector3(0,0.7,0))
 var light=DirectionalLight3D.new();light.rotation_degrees=Vector3(-45,-30,0);light.light_energy=1.3;stage.add_child(light)
 var environment=WorldEnvironment.new();environment.environment=Environment.new()
 environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
 environment.environment.ambient_light_color=Color.WHITE;environment.environment.ambient_light_energy=0.65
 stage.add_child(environment)
 var count=0
 for key in Thumbnails.MODELS:
  var model=Art.model(key,Vector3(1.5,1.6,1.5),true,load(Thumbnails.MODELS[key]))
  stage.add_child(model)
  await process_frame;await process_frame
  await RenderingServer.frame_post_draw
  var result=viewport.get_texture().get_image().save_png("res://assets/ui/icons/"+key+".png")
  if result!=OK: push_error("Cannot save icon: "+key);quit(1);return
  stage.remove_child(model);model.free();count+=1
 print("ASSET_ICONS: %d rendered, 0 failed" % count)
 viewport.queue_free();await process_frame;quit()
