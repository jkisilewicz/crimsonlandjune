#actual_weapon.gd
extends TextureRect

# Metoda do ustawiania tekstury broni
func set_weapon_texture(texture_path: String):
	texture = load(texture_path)
