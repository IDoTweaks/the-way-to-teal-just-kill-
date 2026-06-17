extends Control
var score = 0;
var targScore = 0
var upEach :float = 0
@onready var scoreShow = $UI/MainContainer/title/ScoreShow
@onready var ui = $UI
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _setScore(newScore:int):
	targScore = newScore
	upEach = newScore / 50

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if self.visible == false:
		ui.visible = false
	else:
		ui.visible = true
		_forceVisible(ui)
	if targScore > score:
		score += upEach * delta
		scoreShow.text = "SCORE: \n%d" % int(score)

func _forceVisible(entity):
	if entity.get_children().size() > 0:
		var children = entity.get_children()
		for child in children:
			_forceVisible(child)
	if entity is CanvasItem:
		entity.visible = true
	
