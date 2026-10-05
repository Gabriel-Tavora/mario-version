@tool
extends TileMap
## Copia a colisão de um bloco de tiles (a primeira "variante" do atlas)
## para as outras variantes do mesmo atlas (outras cores/estilos).
##
## Uso:
## 1. No TileSet, desenhe as colisões (e o One Way) só no primeiro bloco.
## 2. Anexe este script ao nó TileMap (ou troque "extends TileMap" por
##    "extends TileMapLayer" se usar TileMapLayer).
## 3. Preencha os campos abaixo e marque "Generate Shapes".
## 4. Confira no painel TileSet. Depois pode remover o script.

@export_group("Copiar colisões")
## Marque para executar (volta a desmarcar sozinho)
@export var generate_shapes := false
@export var physics_layer := 0
## ID da fonte (atlas) no TileSet que será processada
@export var atlas_id := 0
## Tamanho do PRIMEIRO bloco, em tiles (ex.: 16 x 16 tiles)
@export var first_atlas_size := Vector2i.ZERO
## Quantos blocos existem em cada direção, contando o primeiro
## (ex.: 3 colunas e 2 linhas de variantes = Vector2i(3, 2))
@export var tiles_to_span := Vector2i.ZERO


func _process(_delta: float) -> void:
	if generate_shapes:
		generate_shapes = false
		copy_tile_shapes()


func copy_tile_shapes() -> void:
	if tile_set == null:
		push_warning("Este nó não tem TileSet.")
		return

	var atlas := tile_set.get_source(atlas_id) as TileSetAtlasSource
	if atlas == null:
		push_warning("A fonte %d não existe ou não é um atlas." % atlas_id)
		return

	if first_atlas_size.x <= 0 or first_atlas_size.y <= 0 \
			or tiles_to_span.x <= 0 or tiles_to_span.y <= 0:
		push_warning("Preencha first_atlas_size e tiles_to_span.")
		return

	var copied := 0

	for tile_y in first_atlas_size.y:
		for tile_x in first_atlas_size.x:
			var src_coords := Vector2i(tile_x, tile_y)

			# Pula se não existe tile nessa posição
			if atlas.get_tile_at_coords(src_coords) != src_coords:
				continue

			var src: TileData = atlas.get_tile_data(src_coords, 0)
			var count := src.get_collision_polygons_count(physics_layer)
			if count == 0:
				continue

			for block_y in tiles_to_span.y:
				for block_x in tiles_to_span.x:
					# O bloco (0, 0) é o próprio original
					if block_x == 0 and block_y == 0:
						continue

					var dst_coords := src_coords + Vector2i(
						block_x * first_atlas_size.x,
						block_y * first_atlas_size.y
					)

					if atlas.get_tile_at_coords(dst_coords) != dst_coords:
						continue

					var dst: TileData = atlas.get_tile_data(dst_coords, 0)
					dst.set_collision_polygons_count(physics_layer, count)

					# Copia cada polígono, com o One Way e a margem do original
					for p in count:
						dst.set_collision_polygon_points(
							physics_layer, p,
							src.get_collision_polygon_points(physics_layer, p)
						)
						dst.set_collision_polygon_one_way(
							physics_layer, p,
							src.is_collision_polygon_one_way(physics_layer, p)
						)
						dst.set_collision_polygon_one_way_margin(
							physics_layer, p,
							src.get_collision_polygon_one_way_margin(physics_layer, p)
						)
					copied += 1

	_save_tile_set()
	print("Colisões copiadas para %d tiles." % copied)


func _save_tile_set() -> void:
	var path := tile_set.resource_path

	if path.ends_with(".tres") or path.ends_with(".res"):
		ResourceSaver.save(tile_set, path)
		print("TileSet salvo em ", path)
	else:
		# TileSet embutido na cena: não dá para salvar à parte
		print("O TileSet está dentro da cena. Salve a cena (Ctrl+S) para gravar as colisões.")
