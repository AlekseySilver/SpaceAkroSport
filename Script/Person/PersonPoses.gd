class_name PersonPoses
extends Node

var _person: Person

func init(person: Person):
	_person = person


func goto_pose(pose_id: int) -> void:
	if pose_id >= 0 and pose_id < get_child_count():
		var pose := get_child(pose_id) as PersonPose
		if pose:
			for bone in pose.bones:
				var b = _person.get_node(bone) as PersonBody
				b.start_limit(pose.bones[bone])



