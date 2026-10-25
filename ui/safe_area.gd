extends RefCounted
static func insets(safe: Rect2i,physical: Vector2i,logical: Vector2) -> Vector4:
 if safe.size.x<=0 or safe.size.y<=0 or physical.x<=0 or physical.y<=0: return Vector4.ZERO
 var scale=logical/Vector2(physical)
 return Vector4(clampf(safe.position.x,0,physical.x)*scale.x,clampf(safe.position.y,0,physical.y)*scale.y,clampf(physical.x-safe.end.x,0,physical.x)*scale.x,clampf(physical.y-safe.end.y,0,physical.y)*scale.y)
