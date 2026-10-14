extends TileMapLayer
## Paves the whole visible area with plain planks, repeating a 2x2 block of tiles from the sheet.

const SOURCE_ID := 0
## Top-left atlas coords of the 2x2 block of plain planks (inside the framed floor).
const PLANKS := Vector2i(1, 1)


func _ready() -> void:
	_pave()
	# The window can grow (stretch aspect "expand"), so keep the floor covering it.
	get_viewport().size_changed.connect(_pave)


func _pave() -> void:
	var viewport := get_viewport()
	var screen := viewport.get_canvas_transform().affine_inverse() * viewport.get_visible_rect()
	var first := local_to_map(to_local(screen.position))
	var last := local_to_map(to_local(screen.end))
	clear()
	for x in range(first.x, last.x + 1):
		for y in range(first.y, last.y + 1):
			set_cell(Vector2i(x, y), SOURCE_ID, PLANKS + Vector2i(posmod(x, 2), posmod(y, 2)))
