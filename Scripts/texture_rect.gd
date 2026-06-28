extends TextureRect


func _ready() -> void:
	self.anchor_left = .5
	self.anchor_right = .5
	self.anchor_top = .5
	self.anchor_bottom = .5
	self.offset_bottom = self.size.y/2
	self.offset_right = self.size.x/2
	self.offset_top = -self.size.y/2
	self.offset_left = -self.size.x/2
