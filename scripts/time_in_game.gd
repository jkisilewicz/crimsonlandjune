extends Label

var time_elapsed: float = 0.0

func _ready():
	# Initialize the label text
	text = "00:00"

func _process(delta):
	# Add the delta time to the total elapsed time
	time_elapsed += delta
	
	# Format the time as minutes:seconds
	var minutes = int(time_elapsed / 60)
	var seconds = int(time_elapsed) % 60
	
	# Format with leading zeros
	var minutes_string = "%02d" % minutes
	var seconds_string = "%02d" % seconds
	
	# Update the label
	text = minutes_string + ":" + seconds_string
	
	# If you want to include hours for longer games
	if minutes >= 60:
		@warning_ignore("integer_division")
		var hours = int(minutes / 60)
		minutes = minutes % 60
		minutes_string = "%02d" % minutes
		var hours_string = "%02d" % hours
		text = "Time: " + hours_string + ":" + minutes_string + ":" + seconds_string
