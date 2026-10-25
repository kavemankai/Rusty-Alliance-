extends RefCounted
const ASSIGNMENTS=["rest","medical","training","repair","guard","scout","garrison"]
const EVENTS=["hour","arrival","employment","deadline"]

class Scalar:
 static func integer(value: Variant,low: int=-1000000000000,high: int=1000000000000) -> bool:
  return (value is int or value is float) and is_finite(float(value)) and value==floor(value) and value>=low and value<=high

static func integer(value: Variant,low: int=-1000000000000,high: int=1000000000000) -> bool:
 return Scalar.integer(value,low,high)

class Event extends Scalar:
 var id: int
 var at: int
 var kind: String
 var payload: Dictionary
 func _init(event_id: int,minute: int,event_kind: String,body: Dictionary) -> void:
  id=event_id;at=minute;kind=event_kind;payload=body.duplicate(true)
 func pack() -> Dictionary: return {"id":id,"at":at,"kind":kind,"payload":payload}
 static func decode(value: Variant):
  if not value is Dictionary or not value.has_all(["id","at","kind","payload"]): return null
  if not integer(value.id,1) or not integer(value.at,0) or value.kind not in EVENTS or not value.payload is Dictionary: return null
  var p=value.payload
  if value.kind in ["employment","deadline"] and (not p.get("id") is String or p.id==""): return null
  if value.kind=="arrival" and (not p.get("squad") is String or p.squad=="" or (p.has("token") and not integer(p.token,0))): return null
  return Event.new(int(value.id),int(value.at),value.kind,p)

class Transaction extends Scalar:
 var at: int
 var amount: int
 var reason: String
 var balance: int
 func _init(minute: int,delta: int,description: String,total: int) -> void:
  at=minute;amount=delta;reason=description;balance=total
 func pack() -> Dictionary: return {"time":at,"amount":amount,"reason":reason,"balance":balance}
 static func decode(value: Variant):
  if not value is Dictionary or not value.has_all(["time","amount","reason","balance"]): return null
  if not integer(value.time,0) or not integer(value.amount) or not integer(value.balance) or not value.reason is String or value.reason=="": return null
  return Transaction.new(int(value.time),int(value.amount),value.reason,int(value.balance))

class Assignment extends Scalar:
 var actor: String
 var kind: String
 var sector: int
 var since: int
 func _init(person: String,task: String,location: int,minute: int) -> void:
  actor=person;kind=task;sector=location;since=minute
 func pack() -> Dictionary: return {"actor":actor,"kind":kind,"sector":sector,"since":since}
 static func decode(value: Variant):
  if not value is Dictionary or not value.has_all(["actor","kind","sector","since"]): return null
  if not value.actor is String or value.actor=="" or value.kind not in ASSIGNMENTS or not integer(value.sector,-1,255) or not integer(value.since,0): return null
  return Assignment.new(value.actor,value.kind,int(value.sector),int(value.since))
