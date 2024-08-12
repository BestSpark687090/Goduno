extends Button

signal press(button)
func _pressed():
	press.emit(self)
