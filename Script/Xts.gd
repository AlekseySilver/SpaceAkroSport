class_name Xts


const SMALL_FLOAT = .000001
const SIN05 = .08715574274765
const SIN10 = .17364817766693
const SIN15 = .25881904510252
const SIN20 = .34202014332567
const SIN30 = .5
const SIN45 = .707106781186548
const SIN50 = .766044443118978
const SIN60 = .866025403784439
const SIN65 = .90630778703665
const SIN75 = .965925826289
const SIN80 = .984807753012208
const SIN85 = .9961946980917455

# Sum = TermFirst * TermSecond
# <param name="Sum">the result of two consecutive turns</param>
# <param name="TermSecond">2nd turn</param>
# <returns>1st turn</returns>
static func term_first(sum: Basis, term_second_: Basis) -> Basis:
	return sum * term_second_.transposed()


# Sum = TermFirst * TermSecond
# <param name="Sum">the result of two consecutive turns</param>
# <param name="TermFirst">1st turn</param>
# <returns>2nd turn</returns>
static func term_second(sum: Basis, term_first_: Basis) -> Basis:
	sum = sum.transposed()
	sum *= term_first_
	return sum.transposed()


static func get_local_scale(b: Basis) -> Vector3:
	return Vector3(b.x.length(), b.y.length(), b.z.length())


static func  mult_local_scale(b: Basis, scale: Vector3) -> Basis:
	b.x *= scale.x
	b.y *= scale.y
	b.z *= scale.z
	return b


static func is_between(t: float, a: float, b: float) -> bool:
	return t >= a and t <= b


static func up_align(basis: Basis, up_dir: Vector3) -> Basis:
	var scale = get_local_scale(basis)
	# Z = [X * Y]
	# X = [Y * Z]
	if (is_between(basis.x.dot(up_dir), -SIN45, SIN45)):
		basis.z = basis.x.cross(up_dir).normalized()
		basis.x = up_dir.cross(basis.z)
	else:
		basis.x = up_dir.cross(basis.z).normalized()
		basis.z = basis.x.cross(up_dir)
	basis.y = up_dir
	#print($"basis {basis.ToString()}")
	basis = mult_local_scale(basis, scale)
	return basis



static func XY0(v2: Vector2) -> Vector3:
	return Vector3(v2.x, v2.y, 0.0)

static func XYA(v2: Vector2, a: float) -> Vector3:
	return Vector3(v2.x, v2.y, a)

static func XY(v3: Vector3) -> Vector2:
	return Vector2(v3.x, v3.y)


static func distance_sq(a: Vector3, b: Vector3) -> float:
	return (a - b).length_squared()


static func node_distance_sq(a: Node3D, b: Node3D) -> float:
	return distance_sq(a.global_position, b.global_position)




static func first_child(node: Node, recursive: bool = false, name_class: String = "", name_node: String = "") -> Node:
	for r in node.get_children():
		if ((r.get_class() == name_class or name_class == "") and (r.name == name_node or name_node == "")):
			return r
		if (recursive):
			for c in node.get_children():
				var n := first_child(c, true, name_class, name_node)
				if n:
					return n
	return null



static func foreach_child(node: Node, action: Callable, recursive: bool = false, name_class: String = "", name_node: String = "") -> void:
	for r in node.get_children():
		if ((r.get_class() == name_class or name_class == "") and (r.name == name_node or name_node == "")):
			action.call(r)
		if (recursive):
			for c in node.get_children():
				var n := first_child(c, true, name_class, name_node)
				if n:
					action.call(r)




static func get_center(control: Control) -> Vector2:
	return control.size * 0.5 + control.position


static func set_center(control: Control, center: Vector2) -> void:
	control.position = control.size * -0.5 + center


