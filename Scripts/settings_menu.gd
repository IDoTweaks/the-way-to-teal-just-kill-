extends Control
signal closed

@onready var scroll : ScrollContainer = $Center/Panel/Margin/VBox/Scroll
@onready var volumeSlider : HSlider = $Center/Panel/Margin/VBox/Scroll/List/VolumeSlider
@onready var musicSlider : HSlider = $Center/Panel/Margin/VBox/Scroll/List/MusicSlider
@onready var sfxSlider : HSlider = $Center/Panel/Margin/VBox/Scroll/List/SfxSlider
@onready var displayOption : OptionButton = $Center/Panel/Margin/VBox/Scroll/List/DisplayOption
@onready var resOption : OptionButton = $Center/Panel/Margin/VBox/Scroll/List/ResOption
@onready var sensSlider : HSlider = $Center/Panel/Margin/VBox/Scroll/List/SensSlider
@onready var scopeSensSlider : HSlider = $Center/Panel/Margin/VBox/Scroll/List/ScopeSensSlider
@onready var fovSlider : HSlider = $Center/Panel/Margin/VBox/Scroll/List/FovSlider
@onready var shakeSlider : HSlider = $Center/Panel/Margin/VBox/Scroll/List/ShakeSlider
@onready var flashCheck : CheckButton = $Center/Panel/Margin/VBox/Scroll/List/FlashCheck
@onready var scaleSlider : HSlider = $Center/Panel/Margin/VBox/Scroll/List/ScaleSlider
@onready var decalSlider : HSlider = $Center/Panel/Margin/VBox/Scroll/List/DecalSlider
@onready var fpsOption : OptionButton = $Center/Panel/Margin/VBox/Scroll/List/FpsOption
@onready var glowCheck : CheckButton = $Center/Panel/Margin/VBox/Scroll/List/GlowCheck
@onready var resetBtn : Button = $Center/Panel/Margin/VBox/ResetBtn
@onready var backBtn : Button = $Center/Panel/Margin/VBox/BackBtn

const BUS_MASTER := 0
const BUS_MUSIC := 1
const BUS_SFX := 2
const FPS_CAPS := [0, 30, 60, 120, 144, 240]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for s in [volumeSlider, musicSlider, sfxSlider]:
		s.min_value = 0.0
		s.max_value = 1.0
		s.step = 0.01
	resOption.clear()
	for res in Global.SETTINGS_RES:
		resOption.add_item("%d x %d" % [res.x, res.y])
	fpsOption.clear()
	for c in FPS_CAPS:
		fpsOption.add_item("UNLIMITED" if c == 0 else str(c))
	_syncVolumes()
	volumeSlider.value_changed.connect(_on_volume_changed)
	musicSlider.value_changed.connect(_on_music_changed)
	sfxSlider.value_changed.connect(_on_sfx_changed)
	displayOption.item_selected.connect(_on_display_selected)
	resOption.item_selected.connect(_on_res_selected)
	sensSlider.value_changed.connect(_on_sens_changed)
	scopeSensSlider.value_changed.connect(_on_scope_sens_changed)
	fovSlider.value_changed.connect(_on_fov_changed)
	shakeSlider.value_changed.connect(_on_shake_changed)
	flashCheck.toggled.connect(_on_flash_toggled)
	scaleSlider.value_changed.connect(_on_scale_changed)
	decalSlider.value_changed.connect(_on_decal_changed)
	fpsOption.item_selected.connect(_on_fps_selected)
	glowCheck.toggled.connect(_on_glow_toggled)
	resetBtn.pressed.connect(_on_reset_pressed)
	backBtn.pressed.connect(_on_back_pressed)
	_syncDisplay()
	_syncControls()

func open() -> void:
	_syncVolumes()
	_syncDisplay()
	_syncControls()
	show()
	scroll.scroll_vertical = 0

func _syncControls() -> void:
	sensSlider.set_value_no_signal(Global.sensitivity)
	scopeSensSlider.set_value_no_signal(Global.scopedSens)
	fovSlider.set_value_no_signal(Global.fov)
	shakeSlider.set_value_no_signal(Global.screenShake)
	flashCheck.set_pressed_no_signal(Global.reducedFlash)
	scaleSlider.set_value_no_signal(Global.renderScale)
	decalSlider.set_value_no_signal(Global.decalDensity)
	glowCheck.set_pressed_no_signal(Global.glowOn)
	fpsOption.selected = max(FPS_CAPS.find(Global.fpsCap), 0)

func _on_sens_changed(value : float) -> void:
	Global.sensitivity = value
	Global._saveSettings()

func _on_scope_sens_changed(value : float) -> void:
	Global.scopedSens = value
	Global._saveSettings()

func _on_fov_changed(value : float) -> void:
	Global.fov = value
	Global._saveSettings()

func _on_shake_changed(value : float) -> void:
	Global.screenShake = value
	Global._saveSettings()

func _on_flash_toggled(pressed : bool) -> void:
	Global.reducedFlash = pressed
	Global._saveSettings()

func _on_scale_changed(value : float) -> void:
	Global.renderScale = value
	Global._applyGraphics()
	Global._saveSettings()

func _on_decal_changed(value : float) -> void:
	Global.decalDensity = value
	Global._saveSettings()

func _on_fps_selected(index : int) -> void:
	Global.fpsCap = FPS_CAPS[index]
	Global._applyGraphics()
	Global._saveSettings()

func _on_glow_toggled(pressed : bool) -> void:
	Global.glowOn = pressed
	Global._applyGlow()
	Global._saveSettings()

func _on_reset_pressed() -> void:
	Global._resetDefaults()
	_syncVolumes()
	_syncDisplay()
	_syncControls()

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
