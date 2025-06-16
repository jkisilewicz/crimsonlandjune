extends AudioStreamPlayer

var playlist = [
	preload("res://music/Bladinect.mp3"),
	preload("res://music/BanditAttack.mp3"),
	preload("res://music/FadeToBlack.mp3"),
	preload("res://music/Geni.mp3")
]

func _ready():
	randomize() # Zapewnia losowość przy każdym uruchomieniu gry
	stream = playlist[randi() % playlist.size()]
	play()
	finished.connect(_on_finished) # Podłączenie sygnału w kodzie

func _on_finished():
	stream = playlist[randi() % playlist.size()]
	play()
