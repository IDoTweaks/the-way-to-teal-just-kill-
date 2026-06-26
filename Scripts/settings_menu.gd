extends Control
signal closed

@onready var volumeSlider : HSlider = $Center/Panel/Margin/VBox/VolumeSlider
@onready var musicSlider : HSlider = $Center/Panel/Margin/VBox/MusicSlider
@onready var sfxSlider : HSlider = $Center/Panel/Margin/VBox/SfxSlider
@onready var displayOption : OptionButton = $Center/Panel/Margin/VBox/DisplayOption
@onready var resOption : OptionButton = $Center/Panel/Margin/VBox/ResOption
@onready var backBtn : Button = $Center/Panel/Margin/VBox/BackBtn

const BUS_MASTER := 0
const BUS_MUSIC := 1
const BUS_SFX := 2

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for s in [volumeSlider, musicSlider, sfxSlider]:
		s.min_value = 0.0
		s.max_value = 1.0
		s.step = 0.01
	_syncVolumes()
	volumeSlider.value_changed.connect(_on_volume_changed)
	musicSlider.value_changed.connect(_on_music_changed)
	sfxSlider.value_changed.connect(_on_sfx_changed)
	displayOption.item_selected.connect(_on_display_selected)
	resOption.item_selected.connect(_on_res_selected)
	backBtn.pressed.connect(_on_back_pressed)
	_syncDisplay()

func open() -> void:
	_syncVolumes()
	_syncDisplay()
	show()

func _syncVolumes() -> void:
	volumeSlider.set_value_no_signal(Global.masterVol)
	musicSlider.set_value_no_signal(Global.musicVol)
	sfxSlider.set_value_no_signal(Global.sfxVol)

func _syncDisplay() -> void:
	displayOption.selected = clamp(Global.displayMode, 0, displayOption.item_count - 1)
	resOption.selected = clamp(Global.resIndex, 0, resOption.item_count - 1)
	_syncResEnabled()

func _on_volume_changed(value : float) -> void:
	Global.masterVol = value
	Global._applyVol(BUS_MASTER, value)
	Global._saveSettings()

func _on_music_changed(value : float) -> void:
	Global.musicVol = value
	Global._applyVol(BUS_MUSIC, value)
	Global._saveSettings()

func _on_sfx_changed(value : float) -> void:
	Global.sfxVol = value
	Global._applyVol(BUS_SFX, value)
	Global._saveSettings()

func _on_display_selected(index : int) -> void:
	Global.displayMode = index
	Global._applyDisplay()
	Global._saveSettings()
	_syncResEnabled()

func _on_res_selected(index : int) -> void:
	Global.resIndex = index
	Global._applyDisplay()
	Global._saveSettings()

func _syncResEnabled() -> void:
	resOption.disabled = DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_WINDOWED

func _on_back_pressed() -> void:
	hide()
	closed.emit()
