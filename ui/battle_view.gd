extends SubViewportContainer
signal cell_selected(x: int,y: int)
var battle
var viewport: SubViewport
var world: Node3D
var geometry: Node3D
var camera: Camera3D
var selected="mara"
var preview=[]
var show_roofs=true
var pressed=false
var dragged=false
var down=Vector2.ZERO
var fingers={}
var terrain_stamp=0
var floor_multi: MultiMesh
var marked_cells=[]

func _ready() -> void:
 stretch=true
 viewport=SubViewport.new()
 viewport.size=Vector2i(850,580)
 viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
 viewport.handle_input_locally=false
 add_child(viewport)
 world=Node3D.new()
 viewport.add_child(world)
 var light=DirectionalLight3D.new()
 light.rotation_degrees=Vector3(-55,-25,0)
 world.add_child(light)
 var environment=WorldEnvironment.new()
 environment.environment=Environment.new()
 environment.environment.background_mode=Environment.BG_COLOR
 environment.environment.background_color=Color("162128")
 environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
 environment.environment.ambient_light_color=Color.WHITE
 environment.environment.ambient_light_energy=0.7
 world.add_child(environment)
 camera=Camera3D.new()
 camera.projection=Camera3D.PROJECTION_ORTHOGONAL
 camera.size=21
 camera.position=Vector3(24,25,28)
 world.add_child(camera)
 camera.look_at(Vector3(8.5,0,6.5))
 gui_input.connect(input_event)
 redraw()

func material(color: Color) -> StandardMaterial3D:
 var mat=StandardMaterial3D.new()
 mat.albedo_color=color
 mat.roughness=1.0
 return mat

func box(parent: Node3D,pos: Vector3,dimensions: Vector3,color: Color) -> MeshInstance3D:
 var mesh=MeshInstance3D.new()
 var primitive=BoxMesh.new()
 primitive.size=dimensions
 mesh.mesh=primitive
 mesh.material_override=material(color)
 mesh.position=pos
 parent.add_child(mesh)
 return mesh

func redraw() -> void:
 if world==null or battle==null: return
 var chosen=battle.unit(selected)
 var cutaways={}
 for fighter in battle.t.units:
  if fighter.team=="company" or battle.known("company",fighter.id):
   var occupied=battle.Visibility.cell(battle,fighter.x,fighter.y)
   if occupied.has("room"): cutaways[occupied.room]=true
 var stamp=[battle.get_instance_id(),battle.t.tiles.hash(),battle.t.get("fog",{}).get("company",{}).hash(),battle.t.get("sight",{}).get("company",{}).hash(),battle.t.phase,battle.t.get("night",false),battle.t.get("illumination",{}).hash(),show_roofs,cutaways].hash()
 var multi: MultiMesh
 var instance: MultiMeshInstance3D
 var rebuild=geometry==null or stamp!=terrain_stamp
 if rebuild:
  if geometry!=null:
   world.remove_child(geometry)
   geometry.queue_free()
  geometry=Node3D.new()
  world.add_child(geometry)
  # One MultiMesh draws the tile grid; logical cells never own nodes or bodies.
  instance=MultiMeshInstance3D.new()
  multi=MultiMesh.new()
  multi.transform_format=MultiMesh.TRANSFORM_3D
  multi.use_colors=true
  var cube=BoxMesh.new()
  cube.size=Vector3(0.94,0.12,0.94)
  var mat=material(Color.WHITE)
  mat.vertex_color_use_as_albedo=true
  cube.material=mat
  multi.mesh=cube
  multi.instance_count=battle.t.tiles.size()
  floor_multi=multi
  terrain_stamp=stamp
  var obstacles={"palisade":"806044","rock":"656c75","tree":"344a36"}
  for i in range(battle.t.tiles.size()):
   var actual=battle.t.tiles[i]
   var level=battle.Visibility.level(battle,actual.x,actual.y)
   var c=battle.Visibility.cell(battle,actual.x,actual.y)
   var color=paint_cell(c,level,i,chosen)
   multi.set_instance_transform(i,Transform3D(Basis.IDENTITY,Vector3(c.x,c.elevation*0.5,c.y)))
   multi.set_instance_color(i,color)
   if show_roofs and level>0 and c.get("roof",false) and not cutaways.has(c.get("room","")):
    box(geometry,Vector3(c.x,2.0+c.elevation*0.5,c.y),Vector3(0.96,0.15,0.96),Color("594c3d").darkened(0.4 if level==1 else 0.0))
   if level>0 and c.get("light",0)>0: box(geometry,Vector3(c.x,0.6,c.y),Vector3(0.15,1.0,0.15),Color("ffd16d"))
   if c.block and level>0:
    var obstacle=Color(obstacles.get(c.kind,"8c8170")) if not c.door else Color("8e663f")
    var structure=box(geometry,Vector3(c.x,0.65+c.elevation*0.5,c.y),Vector3(0.85,1.25 if c.kind!="window" else 0.5,0.85),obstacle.darkened(0.65) if level==1 else obstacle)
    structure.set_meta("terrain_cell",i)
   elif c.cover>0 and level>0:
    box(geometry,Vector3(c.x,0.3+c.elevation*0.5,c.y),Vector3(0.9,0.5,1.1 if c.kind=="tent" else 0.4),Color("8a7356").darkened(0.65) if level==1 else Color("8a7356"))
  instance.multimesh=multi
  geometry.add_child(instance)
 else:
  for child in geometry.get_children():
   if child.has_meta("dynamic"):
    geometry.remove_child(child);child.queue_free()
 # Only changed selection/route colours need uploading when terrain/fog is unchanged.
 var dirty=marked_cells.duplicate()
 marked_cells=preview.duplicate()
 if chosen!=null: marked_cells.append(int(chosen.y)*int(battle.t.width)+int(chosen.x))
 dirty.append_array(marked_cells)
 for i in dirty:
  if i>=0 and i<battle.t.tiles.size(): floor_multi.set_instance_color(i,tile_color(i,chosen))
 var static_count=geometry.get_child_count()
 var piles={}
 for placement in battle.t.ground:
  if battle.Visibility.level(battle,placement.x,placement.y)!=2: continue
  var key="%d:%d" % [placement.x,placement.y]
  if not piles.has(key): piles[key]={"x":placement.x,"y":placement.y,"count":0}
  piles[key].count+=1
 for pile in piles.values():
  var height=battle.tile(pile.x,pile.y).elevation*0.5
  var loot=box(geometry,Vector3(pile.x,height+0.2,pile.y),Vector3(0.35,0.25,0.35),Color("e7c969"))
  loot.set_meta("ground_pile",true)
 for u in battle.t.units:
  if u.person.hp<=0: continue
  if u.team!="company" and not battle.known("company",u.id): continue
  var elevation=battle.tile(u.x,u.y).elevation*0.5
  var mesh=MeshInstance3D.new()
  if u.role=="cart":
   var cart=BoxMesh.new();cart.size=Vector3(1.1,0.7,0.8);mesh.mesh=cart
  else:
   var capsule=CapsuleMesh.new();capsule.radius=0.24;capsule.height=1.2;mesh.mesh=capsule
  mesh.material_override=material(Color("74cbe3") if u.team=="company" else Color("e77b62"))
  mesh.position=Vector3(u.x,elevation+0.7,u.y)
  geometry.add_child(mesh)
  var label=Label3D.new()
  label.text="%s\n%d HP · %d AP" % [u.person.name,u.person.hp,u.ap]
  label.font_size=32
  label.pixel_size=0.008
  label.position=Vector3(u.x,elevation+1.8,u.y)
  label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
  geometry.add_child(label)
  var angle=u.facing*PI/4
  box(geometry,Vector3(u.x+cos(angle)*0.32,elevation+0.8,u.y+sin(angle)*0.32),Vector3(0.13,0.15,0.13),Color("ffe2a0"))

 for i in range(static_count,geometry.get_child_count()): geometry.get_child(i).set_meta("dynamic",true)

func tile_color(i: int,chosen) -> Color:
 var actual=battle.t.tiles[i]
 var level=battle.Visibility.level(battle,actual.x,actual.y)
 var c=battle.Visibility.cell(battle,actual.x,actual.y)
 return paint_cell(c,level,i,chosen)

func paint_cell(c: Dictionary,level: int,i: int,chosen) -> Color:
 var surfaces={"road":"77664b","floor":"777773","crop":"8b8143","quarry":"626971","mud":"55483b"}
 var color=Color("485546") if int(c.x+c.y)%2==0 else Color("404d3f")
 if surfaces.has(c.kind): color=Color(surfaces[c.kind])
 if c.cost>2 and not surfaces.has(c.kind): color=Color("62604a")
 if c.conceal>0: color=Color("2d523a")
 if battle.t.phase=="deployment" and battle.deployment_tile(battle.t,c.x,c.y): color=Color("397a58")
 if battle.t.get("night",false) and not (level==2 and battle.t.get("illumination",{}).get(str(i),0)>0): color=color.darkened(0.35)
 if level==0: color=Color("11191f")
 elif level==1: color=color.darkened(0.65)
 if i in preview and level>0: color=Color("a69745")
 if chosen!=null and c.x==chosen.x and c.y==chosen.y: color=Color("2898b4")
 return color

func pick(point: Vector2) -> void:
 var screen=point*Vector2(viewport.size)/size
 var origin=camera.project_ray_origin(screen)
 var direction=camera.project_ray_normal(screen)
 # Intersect logical tile tops, highest elevation first.
 for level in [1,0]:
  var plane=Plane(Vector3.UP,level*0.5+0.06)
  var hit=plane.intersects_ray(origin,direction)
  if hit!=null:
   var x=int(round(hit.x))
   var y=int(round(hit.z))
   var c=battle.Visibility.cell(battle,x,y)
   if not c.is_empty() and c.elevation==level:
    cell_selected.emit(x,y)
    return

func input_event(event: InputEvent) -> void:
 if battle==null: return
 if event is InputEventMouseButton:
  if event.button_index==MOUSE_BUTTON_WHEEL_UP: camera.size=clampf(camera.size-1,8,32)
  elif event.button_index==MOUSE_BUTTON_WHEEL_DOWN: camera.size=clampf(camera.size+1,8,32)
  elif event.button_index==MOUSE_BUTTON_LEFT:
   pressed=event.pressed
   if pressed:
    down=event.position
    dragged=false
   elif not dragged: pick(event.position)
 elif event is InputEventMouseMotion and pressed:
  if event.position.distance_to(down)>12: dragged=true
  if dragged: camera.position+=Vector3(-event.relative.x-event.relative.y,0,event.relative.x-event.relative.y)*camera.size/900
 elif event is InputEventMagnifyGesture: camera.size=clampf(camera.size/event.factor,8,32)
 elif event is InputEventScreenTouch:
  if event.pressed: fingers[event.index]=event.position
  else: fingers.erase(event.index)
  if fingers.size()>1: dragged=true
 elif event is InputEventScreenDrag and fingers.has(event.index):
  if fingers.size()==2:
   var keys=fingers.keys()
   var other=keys[0] if keys[1]==event.index else keys[1]
   var old=fingers[event.index].distance_to(fingers[other])
   var fresh=event.position.distance_to(fingers[other])
   if old>1 and fresh>1: camera.size=clampf(camera.size*old/fresh,8,32)
   dragged=true
  fingers[event.index]=event.position
