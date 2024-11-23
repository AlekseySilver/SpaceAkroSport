extends RichTextLabel

@export var font_scale: float = 0.5

func _ready():
	var font_size := int(get_rect().size.y * font_scale)
	set("theme_override_font_sizes/normal_font_size", font_size)

