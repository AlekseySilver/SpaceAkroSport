@tool
extends MenuButton
class_name ActionMenu25D

var selection #: Node[]
var editor_camera: Camera3D
var method_dict: Dictionary


func _ready() -> void:
	var pu := get_popup()
	pu.clear(true)
	var id := 10
	for m in get_script().get_script_method_list():
		#print(m.name)
		if _popup_add(m.name, id):
			id += 1


func _popup_add(name, id) -> bool:
	if name.left(1) == "_":
		return false
	var arr: PackedStringArray = name.split("__")
	if len(arr) != 2:
		return false
	var submenu := arr[0]
	var menu := arr[1]
	
	var pu := get_popup()
	var pop: PopupMenu = pu.get_node_or_null(submenu)
	if pop == null:
		pop = PopupMenu.new()
		pop.set_name(submenu)
		pu.add_child(pop)
		pu.add_submenu_item(submenu, submenu)
		pop.id_pressed.connect(_on_menu_item_pressed)
	pop.add_item(menu, id)
	method_dict[id] = name
	return true


func _on_menu_item_pressed(id) -> void:
	var iname = method_dict[id]
	print("start menu ", iname)
	call(iname)


func test__test() -> void:
	print("test")


##################################################################################################
func mesh__create_convex_collision() -> void:
	print("v3")
	if selection == null:
		print("nothing selected")
		return
	var root_body: PhysicsBody3D

	for node in selection:
		root_body = node as PhysicsBody3D
		if root_body:
			break
	if root_body == null:
		print("no PhysicsBody3D selected")
		return

	Xts25D.create_convex_collision(root_body)


##################################################################################################
func mesh__fix_static_body() -> void:
	print("v2")
	if selection == null:
		print("nothing selected")
		return
	
	for node in selection:
		var mesh := node as MeshInstance3D
		if not mesh:
			continue
		var box := mesh.mesh as BoxMesh
		if not box:
			continue
		var body := mesh.get_parent() as PhysicsBody3D
		if not body:
			continue
		var coll := Xts.first_child(body, false, "CollisionShape3D") as CollisionShape3D
		if not coll:
			continue
		var shape := coll.shape as BoxShape3D
		if not shape:
			continue

		box = box.duplicate()
		mesh.mesh = box
		box.size *= mesh.scale
		shape = shape.duplicate()
		coll.shape = shape
		shape.size = box.size
		body.global_transform = Transform3D(mesh.global_basis.orthonormalized(), mesh.global_position)
		mesh.transform = Transform3D.IDENTITY
		coll.transform = Transform3D.IDENTITY






func _commit_mesh(mdt, mi) -> void:
	var mat: Material = mi.get_surface_material(0)
	mi.mesh.surface_remove(0)
	mdt.commit_to_surface(mi.mesh)
	mi.set_surface_material(0, mat)


##################################################################################################
func bone_global_transform(skel: Skeleton3D, bone_id: int) -> Transform3D:
	var xf := Transform3D.IDENTITY
	var i := bone_id
	while i >= 0:
		xf = skel.get_bone_pose(i) * xf
		i = skel.get_bone_parent(i)
	xf = skel.global_transform * xf
	xf = Transform3D(xf.basis.orthonormalized(), xf.origin)
	return xf

##################################################################################################
func bone_global_position(skel: Skeleton3D, bone_id: int) -> Vector3:
	return bone_global_transform(skel, bone_id).origin

##################################################################################################
func person__make_collshapes_unique() -> void:
	print("v9")
	if selection == null:
		print("nothing selected")
		return
	var root: Node3D
	for node in selection:
		root = node as Node3D
		if root:
			break

	print("start find rbodies")
	var singles := []
	var doubles := []
	var lambda_find_bodies := func(rbody):
		match String(rbody.name)[0]:
			"L":
				var find_name = String(rbody.name)
				find_name[0] = "R"
				var fil := doubles.filter(func(y): return y[1] and y[1].name == find_name)
				if len(fil) > 0:
					fil[0][0] = rbody
				else:
					doubles.append([rbody, null])
			"R":
				var find_name = String(rbody.name)
				find_name[0] = "L"
				var fil := doubles.filter(func(y): return y[0] and y[0].name == find_name)
				if len(fil) > 0:
					fil[0][1] = rbody
				else:
					doubles.append([null, rbody])
			_:
				singles.append(rbody)

	Xts.foreach_child(root, lambda_find_bodies, false, "RigidBody3D")
	print("singles found ",  len(singles))
	print("doubles found ",  len(doubles))

	print("start singles duplicate")
	var lambda_singles := func(body):
		body.shape = body.shape.duplicate()

	for s in singles:
		Xts.foreach_child(s, lambda_singles, false, "CollisionShape3D")

	print("start doubles duplicate")
	var lambda_doubles := func(left_coll):
		var shape = left_coll.shape.duplicate()
		left_coll.shape = shape
		var fil := doubles.filter(func(y): return y[0] == left_coll.get_parent())
		var right_body := fil[0][1] as RigidBody3D
		var right_coll = right_body.get_node(String(left_coll.name))
		right_coll.shape = shape

	for d in doubles:
		Xts.foreach_child(d[0], lambda_doubles, false, "CollisionShape3D")


##################################################################################################
func skeleton__set_joints_pos() -> void:
	if selection == null:
		print("nothing selected")
		return
	var skel: Skeleton3D
	for node in selection:
		skel = node as Skeleton3D
		if skel:
			break
	if skel == null:
		print("no Skeleton3D selected")
		return

	var root: Node3D = skel.get_node("../..")

	for i in skel.get_bone_count():
		#print(_skel.get_bone_name(i))
		var joint: Node3D = null
		match skel.get_bone_name(i):
			"mixamorig7_Head":
				joint = root.get_node("J_Body_Head")
			"mixamorig7_LeftShoulder":
				joint = root.get_node("J_Body_LUArm0")
			"mixamorig7_LeftArm":
				joint = root.get_node("J_LUArm0_LUArm1")
			"mixamorig7_LeftForeArm":
				joint = root.get_node("J_LUArm1_LFArm")
			"mixamorig7_RightShoulder":
				joint = root.get_node("J_Body_RUArm0")
			"mixamorig7_RightArm":
				joint = root.get_node("J_RUArm0_RUArm1")
			"mixamorig7_RightForeArm":
				joint = root.get_node("J_RUArm1_RFArm")
			"mixamorig7_LeftUpLeg":
				joint = root.get_node("J_LThigh0_LThigh1")
			"mixamorig7_LeftLeg":
				joint = root.get_node("J_LThigh1_LCalf")
			"mixamorig7_RightUpLeg":
				joint = root.get_node("J_RThigh0_RThigh1")
			"mixamorig7_RightLeg":
				joint = root.get_node("J_RThigh1_RCalf")
		if joint:
			joint.global_position = bone_global_position(skel, i)
	print("_test_flag done")
# mixamorig7_Hips
# mixamorig7_Head
# 
# mixamorig7_LeftShoulder
# mixamorig7_LeftArm
# mixamorig7_LeftForeArm
# 
# mixamorig7_RightShoulder
# mixamorig7_RightArm
# mixamorig7_RightForeArm
# 
# mixamorig7_LeftUpLeg
# mixamorig7_LeftLeg
# 
# mixamorig7_RightUpLeg
# mixamorig7_RightLeg
# 
# #####################################
# 
# mixamorig7_Spine
# mixamorig7_Spine1
# mixamorig7_Spine2
# mixamorig7_Neck
# 
# mixamorig7_HeadTop_End
# 
# 
# mixamorig7_LeftHand
# 
# 
# mixamorig7_RightHand
# 
# mixamorig7_LeftFoot
# mixamorig7_LeftToeBase
# mixamorig7_LeftToe_End
# 
# mixamorig7_RightFoot
# mixamorig7_RightToeBase
# mixamorig7_RightToe_End


