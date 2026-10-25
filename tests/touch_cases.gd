extends RefCounted
static func touch(view,index: int,pressed: bool,point: Vector2,canceled: bool=false) -> void:
 var event=InputEventScreenTouch.new();event.index=index;event.pressed=pressed;event.position=point;event.canceled=canceled;view.input_event(event)
static func drag(view,index: int,point: Vector2,relative: Vector2) -> void:
 var event=InputEventScreenDrag.new();event.index=index;event.position=point;event.relative=relative;view.input_event(event)
static func run(test) -> void:
 var safe=preload("res://ui/safe_area.gd")
 test.check(safe.insets(Rect2i(80,0,2320,1032),Vector2i(2400,1080),Vector2(1600,720)).is_equal_approx(Vector4(53.333333,0,0,32)),"Cutout and navigation insets convert from physical pixels into logical UI space")
 test.check(safe.insets(Rect2i(),Vector2i.ZERO,Vector2(1280,720))==Vector4.ZERO,"Unavailable safe-area data preserves a usable full-window layout")
 var map=preload("res://ui/world_map.gd").new();var taps=[]
 map.sector_selected.connect(func(index):taps.append(index))
 var point=map.offset+Vector2(1.5,1.5)*32*map.zoom
 touch(map,0,true,point);touch(map,0,false,point)
 test.check(taps==[17],"Native strategic touch selects exactly once without mouse emulation")
 var old_offset=map.offset
 touch(map,0,true,point);drag(map,0,point+Vector2(40,20),Vector2(40,20));touch(map,0,false,point+Vector2(40,20))
 test.check(map.offset!=old_offset and taps.size()==1,"Strategic single-finger pan does not select on release")
 var old_zoom=map.zoom;old_offset=map.offset
 touch(map,0,true,Vector2(100,100));touch(map,1,true,Vector2(200,100));drag(map,0,Vector2(80,100),Vector2(-20,0));touch(map,0,false,Vector2(80,100));touch(map,1,false,Vector2(200,100))
 test.check(map.zoom>old_zoom and map.offset!=old_offset and taps.size()==1,"Strategic pinch pans/zooms and neither finger release selects")
 var mouse=InputEventMouseButton.new();mouse.device=InputEvent.DEVICE_ID_EMULATION;mouse.button_index=MOUSE_BUTTON_LEFT;mouse.position=point
 mouse.pressed=true;map.input_event(mouse);mouse.pressed=false;map.input_event(mouse)
 test.check(taps.size()==1,"Touch-generated mouse twin cannot duplicate strategic selection")
 point=map.offset+Vector2(2.5,1.5)*32*map.zoom
 touch(map,0,true,point);touch(map,0,false,point)
 test.check(taps[-1]==18 and taps.size()==2,"Fresh touch selects after a completed pinch")
 var prior=taps.size()
 touch(map,0,true,point);touch(map,0,false,point,true)
 test.check(taps.size()==prior,"Cancelled strategic touch never selects")
 touch(map,0,true,point);map.notification(Node.NOTIFICATION_APPLICATION_PAUSED);touch(map,0,false,point)
 test.check(map.fingers.is_empty() and taps.size()==prior,"Pause clears strategic gesture state without a late selection")
 var magnify=InputEventMagnifyGesture.new();magnify.factor=1.1
 old_zoom=map.zoom;map.input_event(magnify)
 test.check(map.zoom>old_zoom,"Strategic map handles Android native magnify gestures")
 var pan=InputEventPanGesture.new();pan.delta=Vector2(2,-3)
 old_offset=map.offset;map.input_event(pan)
 test.check(map.offset!=old_offset,"Strategic map handles Android native pan gestures")
 map.free()
 var c=preload("res://tests/exploration_cases.gd").field()
 var board=preload("res://ui/battle_view.gd").new();board.battle=c.battle;board.size=Vector2(850,580)
 test.root.add_child(board)
 var picks=[];board.cell_selected.connect(func(x,y):picks.append(Vector2i(x,y)))
 var actor=c.battle.unit("mara")
 point=board.camera.unproject_position(Vector3(actor.x,0.06,actor.y))*board.size/Vector2(board.viewport.size)
 touch(board,0,true,point);touch(board,0,false,point)
 test.check(picks==[Vector2i(actor.x,actor.y)],"Native tactical touch ray-picks the intended cell exactly once")
 var camera_position=board.camera.position
 touch(board,0,true,point);drag(board,0,point+Vector2(40,20),Vector2(40,20));touch(board,0,false,point+Vector2(40,20))
 test.check(board.camera.position!=camera_position and picks.size()==1,"Tactical single-finger pan suppresses cell selection")
 var zoom=board.camera.size;camera_position=board.camera.position
 touch(board,0,true,Vector2(100,100));touch(board,1,true,Vector2(200,100));drag(board,0,Vector2(80,100),Vector2(-20,0));touch(board,1,false,Vector2(200,100));touch(board,0,false,Vector2(80,100))
 test.check(board.camera.size<zoom and board.camera.position!=camera_position and picks.size()==1,"Tactical pinch pans/zooms with opposite release order and no accidental pick")
 mouse.pressed=true;board.input_event(mouse);mouse.pressed=false;board.input_event(mouse)
 test.check(picks.size()==1,"Touch-generated mouse twin cannot duplicate tactical picking")
 var prior_picks=picks.size()
 touch(board,0,true,point);touch(board,0,false,point,true)
 test.check(picks.size()==prior_picks,"Cancelled tactical touch never picks")
 touch(board,0,true,point);board.notification(Node.NOTIFICATION_APPLICATION_PAUSED);touch(board,0,false,point)
 test.check(board.fingers.is_empty() and picks.size()==prior_picks,"Pause clears tactical gesture state without a late pick")
 zoom=board.camera.size;board.input_event(magnify)
 test.check(board.camera.size<zoom,"Tactical camera handles Android native magnify gestures")
 camera_position=board.camera.position;board.input_event(pan)
 test.check(board.camera.position!=camera_position,"Tactical camera handles Android native pan gestures")
 board.free()
