class_name Xts25D


static func create_convex_collision(root_body: PhysicsBody3D) -> void:
	# remove shapes
	for child in root_body.get_children():
		if child is CollisionShape3D:
			child.queue_free()

	for node in root_body.get_children():
		var mesh := node as MeshInstance3D
		if mesh:
			mesh.create_convex_collision()

			var new_body := mesh.get_child(mesh.get_child_count() - 1) as PhysicsBody3D
			if new_body:
				var coll := new_body.get_child(0) as CollisionShape3D
				var conv := coll.shape as ConvexPolygonShape3D
				var arr: PackedVector3Array = conv.points.duplicate()
				for i in range(len(arr)):
					var point: Vector3 = arr[i]
					arr.set(i, mesh.transform.basis * point)

				coll = CollisionShape3D.new()
				conv = ConvexPolygonShape3D.new()
				conv.points = arr
				coll.shape = conv
				root_body.add_child(coll)
				coll.owner = root_body.owner
				coll.global_position = new_body.global_position
				coll.name = mesh.name
				

			# remove bodies from mesh
			for child in mesh.get_children():
				if child is PhysicsBody3D:
					child.queue_free()


