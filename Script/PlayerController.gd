class_name PlayerController extends BaseController


@onready var _pose_actions: Array[StringName] = [&"pose1", &"pose2", &"pose3", &"pose4"]


func is_pose(pose_id: int) -> bool:
	return Input.is_action_pressed(_pose_actions[pose_id])


func axis_x() -> float:
	return Input.get_axis("move_left", "move_right")




