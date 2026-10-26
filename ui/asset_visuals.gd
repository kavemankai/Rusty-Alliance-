extends RefCounted
const Catalog=preload("res://ui/asset_catalog.gd")
const Data=preload("res://sim/catalog.gd")

static func meshes(node: Node) -> Array:
 var found=[]
 if node is MeshInstance3D and node.visible: found.append(node)
 for child in node.get_children(): found.append_array(meshes(child))
 return found

static func bounds(node: Node3D) -> AABB:
 var result=AABB()
 var first=true
 for mesh in meshes(node):
  var transform=Transform3D.IDENTITY
  var cursor: Node=mesh
  while cursor!=node:
   if cursor is Node3D: transform=cursor.transform*transform
   cursor=cursor.get_parent()
  var box: AABB=transform*mesh.get_aabb()
  result=box if first else result.merge(box)
  first=false
 return result

static func model(key: String,dimensions: Vector3,uniform: bool=true,source_override: Resource=null) -> Node3D:
 var source=source_override if source_override!=null else Catalog.MODELS.get(key)
 if source is String: source=load(source)
 if source==null: return null
 var root=Node3D.new()
 root.set_meta("asset_key",key)
 # Keep only live models resident; the engine cache reuses this resource during
 # redraw while previous nodes await deferred deletion. No static cache cycle.
 root.set_meta("asset_resource",source)
 var content: Node3D
 if source is PackedScene: content=source.instantiate()
 elif source is Mesh:
  content=MeshInstance3D.new();content.mesh=source
 else:
  root.free();return null
 root.add_child(content)
 # Imported RPG props are replaced by the actor's actual equipped items.
 for mesh in meshes(content):
  if str(mesh.name) in ["Cleric_Staff","Ranger_Bow","Rogue_Dagger","Warrior_Sword","Wizard_Staff"]: mesh.hide()
 var box: AABB=bounds(content)
 var extent=box.size.max(Vector3.ONE*0.001)
 var factor=dimensions/extent
 if uniform: factor=Vector3.ONE*minf(factor.x,minf(factor.y,factor.z))
 content.scale=factor
 content.position=-(box.position+Vector3(box.size.x/2,0,box.size.z/2))*factor
 root.set_meta("fit_scale",factor)
 return root

static func place(parent: Node3D,key: String,pos: Vector3,dimensions: Vector3,uniform: bool=true,remembered: bool=false) -> Node3D:
 var result=model(key,dimensions,uniform)
 if result==null: return null
 result.position=pos
 parent.add_child(result)
 if remembered:
  for mesh in meshes(result):
   for surface in range(mesh.mesh.get_surface_count()):
    var original=mesh.get_active_material(surface)
    if original is StandardMaterial3D:
     var mat=original.duplicate()
     mat.albedo_color=mat.albedo_color.darkened(0.65)
     mesh.set_surface_override_material(surface,mat)
 return result

static func skeleton(node: Node) -> Skeleton3D:
 if node is Skeleton3D: return node
 for child in node.get_children():
  var found=skeleton(child)
  if found!=null: return found
 return null

static func idle(node: Node) -> void:
 if node is AnimationPlayer:
  for clip in node.get_animation_list():
   if str(clip).get_file() in ["Idle","Idle_Weapon"]:
    # Duplicate the clip before changing loop mode; shared imports stay untouched.
    var animation=node.get_animation(clip).duplicate()
    animation.loop_mode=Animation.LOOP_LINEAR
    var library=AnimationLibrary.new()
    library.add_animation("idle",animation)
    node.add_animation_library("presentation",library)
    node.play("presentation/idle")
    return
 for child in node.get_children(): idle(child)

static func attach(actor: Node3D,key: String,bone_name: String,height: float) -> void:
 if not Catalog.MODELS.has(key): return
 var rig=skeleton(actor)
 if rig==null: return
 var bone=rig.find_bone(bone_name)
 if bone<0: return
 var socket=BoneAttachment3D.new()
 socket.bone_name=bone_name
 rig.add_child(socket)
 var factor: Vector3=actor.get_meta("fit_scale",Vector3.ONE)
 var size=height/maxf(factor.y,0.001)
 var gear=model(key,Vector3.ONE*size)
 socket.add_child(gear)
 gear.position.y=-size*0.1
 gear.set_meta("equipped_visual",true)

static func actor(parent: Node3D,u: Dictionary,pos: Vector3) -> Node3D:
 var key="cart" if u.role=="cart" else u.person.get("background","soldier")
 if not Catalog.MODELS.has(key): key="rogue" if u.team!="company" else "soldier"
 var result=place(parent,key,pos,Vector3(0.85,1.35,0.8) if key!="cart" else Vector3(1.1,0.9,0.9))
 if result==null: return null
 result.set_meta("actor_id",u.id)
 result.rotation.y=-u.facing*PI/4+PI/2
 if key!="cart":
  idle(result)
  var weapon=Data.weapon(u.person)
  attach(result,weapon,"Weapon.R",1.25 if weapon in ["spear","javelin","greatsword"] else 0.7)
  if Data.shield(u.person): attach(result,"shield","Fist.L",0.55)
  if Data.helmet(u.person): attach(result,"helmet","Head",0.35)
  # Stance remains visible while full stance animation retargeting is outstanding.
  if u.get("stance","stand")=="crouch": result.scale.y=0.72
  elif u.get("stance","stand")=="prone":
   result.rotation.z=PI/2;result.position.y+=0.25
 return result

static func terrain_key(cell: Dictionary) -> String:
 if cell.get("door",false): return "door"
 if cell.kind in ["tree","brush","rock","ore","wall","window","palisade","barricade","stall","workbench","dummy","crop","tent"]: return cell.kind
 return ""

static func terrain_size(key: String) -> Vector3:
 match key:
  "tree": return Vector3(0.95,1.9,0.95)
  "wall","window": return Vector3(0.94,1.3,0.28)
  "door","palisade": return Vector3(0.9,1.25,0.25)
  "brush","crop": return Vector3(0.85,0.45,0.85)
  "tent": return Vector3(0.85,0.7,0.9)
  "rock": return Vector3(0.85,1.2,0.85)
 return Vector3(0.9,0.55,0.8)
