extends SceneTree
const Art=preload("res://ui/asset_visuals.gd")
func _init() -> void: call_deferred("run")
func run() -> void:
 root.size=Vector2i(1280,720)
 var world=Node3D.new();root.add_child(world)
 var camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL
 camera.size=10.5;camera.position=Vector3(6,9,13);world.add_child(camera);camera.look_at(Vector3(0,0.5,0))
 var light=DirectionalLight3D.new();light.rotation_degrees=Vector3(-55,-25,0);world.add_child(light)
 var environment=WorldEnvironment.new();environment.environment=Environment.new()
 environment.environment.background_mode=Environment.BG_COLOR;environment.environment.background_color=Color("162128")
 environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
 environment.environment.ambient_light_color=Color.WHITE;environment.environment.ambient_light_energy=0.7;world.add_child(environment)
 var keys=["soldier","hunter","physician","sword","shield","tree","wall","window","door","tent","cart","crop","workbench","rock","bow"]
 for i in range(keys.size()):
  var key=keys[i]
  var pos=Vector3((i%5-2)*2.0,0,(int(i/5)-1)*2.4)
  var size=Art.terrain_size(key) if key in ["tree","wall","window","door","tent","crop","workbench","rock"] else Vector3(1.2,1.35,1.2)
  var model=Art.place(world,key,pos,size)
  if model==null: push_error("Missing calibration asset: "+key);quit(1);return
  var label=Label3D.new();label.text=key.capitalize();label.font_size=36;label.pixel_size=0.008
  label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;label.position=pos+Vector3(0,-0.15,0.45);world.add_child(label)
 for frame in range(3): await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://asset-calibration-preview.png")
 print("ASSET_CALIBRATION: 15 models rendered, 0 failed; isolated presentation scene, not a campaign visibility test")
 world.queue_free();await process_frame;await process_frame;quit()
