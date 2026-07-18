extends Control
signal closed

@onready var tabs : HBoxContainer = $Root/VBox/Tabs
@onready var pages : PanelContainer = $Root/VBox/Pages
@onready var dirtyLabel : Label = $Root/VBox/Footer/DirtyLabel
@onready var saveBtn : Button = $Root/VBox/Footer/SaveBtn
@onready var resetBtn : Button = $Root/VBox/Footer/ResetBtn
@onready var backBtn : Button = $Root/VBox/Footer/BackBtn

@onready var volumeSlider : HSlider = $Root/VBox/Pages/PageAudio/List/VolumeSlider
@onready var musicSlider : HSlider = $Root/VBox/Pages/PageAudio/List/MusicSlider
@onready var sfxSlider : HSlider = $Root/VBox/Pages/PageAudio/List/SfxSlider

@onready var displayOption : OptionButton = $Root/VBox/Pages/PageDisplay/List/DisplayOption
@onready var resOption : OptionButton = $Root/VBox/Pages/PageDisplay/List/ResOption
@onready var fovSlider : HSlider = $Root/VBox/Pages/PageDisplay/List/FovSlider
@onready var shakeSlider : HSlider = $Root/VBox/Pages/PageDisplay/List/ShakeSlider
@onready var flashCheck : CheckButton = $Root/VBox/Pages/PageDisplay/List/FlashCheck

@onready var scaleSlider : HSlider = $Root/VBox/Pages/PageGraphics/List/ScaleSlider
@onready var decalSlider : HSlider = $Root/VBox/Pages/PageGraphics/List/DecalSlider
@onready var fpsOption : OptionButton = $Root/VBox/Pages/PageGraphics/List/FpsOption
@onready var glowCheck : CheckButton = $Root/VBox/Pages/PageGraphics/List/GlowCheck
@onready var toonCheck : CheckButton = $Root/VBox/Pages/PageGraphics/List/ToonCheck

@onready var sensSlider : HSlider = $Root/VBox/Pages/PageControls/List/SensSlider
@onready var scopeSensSlider : HSlider = $Root/VBox/Pages/PageControls/List/ScopeSensSlider
@onready var invertCheck : CheckButton = $Root/VBox/Pages/PageControls/List/InvertCheck
@onready var scopeToggleCheck : CheckButton = $Root/VBox/Pages/PageControls/List/ScopeToggleCheck
@onready var slideToggleCheck : CheckButton = $Root/VBox/Pages/PageControls/List/SlideToggleCheck

@onready var bindList : VBoxContainer = $Root/VBox/Pages/PageKeybinds/List/BindList
@onready var resetBindsBtn : Button = $Root/VBox/Pages/PageKeybinds/List/ResetBindsBtn

@onready var ghostCheck : CheckButton = $Root/VBox/Pages/PageGame/List/GhostCheck

const BUS_MASTER := 0
const BUS_MUSIC := 1
const BUS_SFX := 2
const FPS_CAPS := [0, 30, 60, 120, 144, 240]
const TABS := [
	["AUDIO", "PageAudio"], ["DISPLAY", "PageDisplay"], ["GRAPHICS", "PageGraphics"],
	["CONTROLS", "PageControls"], ["KEYBINDS", "PageKeybinds"], ["GAME", "PageGame"],
]

var _bindRows : Dictionary = {}
var _listening : String = ""
var _tabBtns : Array[Button] = []
var _pageNodes : Array[Control] = []
var _current : int = 0
var _dirty : bool = false
var _snapshot : Dictionary = {}

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
	_buildTabs()

	volumeSlider.value_changed.connect(func(v): Global.masterVol = v; Global._applyVol(BUS_MASTER, v); _touch())
	musicSlider.value_changed.connect(func(v): Global.musicVol = v; Global._applyVol(BUS_MUSIC, v); _touch())
	sfxSlider.value_changed.connect(func(v): Global.sfxVol = v; Global._applyVol(BUS_SFX, v); _touch())
	displayOption.item_selected.connect(func(i): Global.displayMode = i; Global._applyDisplay(); _syncResEnabled(); _touch())
	resOption.item_selected.connect(func(i): Global.resIndex = i; Global._applyDisplay(); _touch())
	fovSlider.value_changed.connect(func(v): Global.fov = v; _touch())
	shakeSlider.value_changed.connect(func(v): Global.screenShake = v; _touch())
	flashCheck.toggled.connect(func(v): Global.reducedFlash = v; _touch())
	scaleSlider.value_changed.connect(func(v): Global.renderScale = v; Global._applyGraphics(); _touch())
	decalSlider.value_changed.connect(func(v): Global.decalDensity = v; _touch())
	fpsOption.item_selected.connect(func(i): Global.fpsCap = FPS_CAPS[i]; Global._applyGraphics(); _touch())
	glowCheck.toggled.connect(func(v): Global.glowOn = v; Global._applyGlow(); _touch())
	toonCheck.toggled.connect(func(v): Global.toonOutlines = v; _touch())
	sensSlider.value_changed.connect(func(v): Global.sensitivity = v; _touch())
	scopeSensSlider.value_changed.connect(func(v): Global.scopedSens = v; _touch())
	invertCheck.toggled.connect(func(v): Global.invertY = v; _touch())
	scopeToggleCheck.toggled.connect(func(v): Global.toggleScope = v; _touch())
	slideToggleCheck.toggled.connect(func(v): Global.toggleSlide = v; _touch())
	ghostCheck.toggled.connect(func(v): Global.showGhost = v; _touch())
	resetBindsBtn.pressed.connect(_on_reset_binds)
	resetBtn.pressed.connect(_on_reset_pressed)
	saveBtn.pressed.connect(_on_save_pressed)
	backBtn.pressed.connect(_on_back_pressed)

	_buildBinds()
	_takeSnapshot()
	_syncAll()

func _buildTabs() -> void:
	for i in TABS.size():
		var b = Button.new()
		b.text = TABS[i][0]
		b.custom_minimum_size = Vector2(0, 60)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(_showTab.bind(i))
		tabs.add_child(b)
		_tabBtns.append(b)
		_pageNodes.append(pages.get_node(TABS[i][1]))
	_showTab(0)

func _showTab(idx : int) -> void:
	_current = idx
	for i in _pageNodes.size():
		_pageNodes[i].visible = i == idx
		_tabBtns[i].disabled = i == idx
		if i == idx:
			_pageNodes[i].scroll_vertical = 0

func open() -> void:
	show()
	_takeSnapshot()
	_syncAll()
	_showTab(0)

# --- deferred save ---------------------------------------------------------

const WATCHED := ["toonOutlines", "masterVol", "musicVol", "sfxVol", "displayMode", "resIndex", "sensitivity",
	"scopedSens", "fov", "screenShake", "reducedFlash", "renderScale", "glowOn", "decalDensity",
	"fpsCap", "invertY", "toggleScope", "toggleSlide", "showGhost"]

func _takeSnapshot() -> void:
	_snapshot.clear()
	for k in WATCHED:
		_snapshot[k] = Global.get(k)
	_snapshot["keybinds"] = Global.keybinds.duplicate(true)
	_setDirty(false)

func _restoreSnapshot() -> void:
	if _snapshot.is_empty():
		return
	for k in WATCHED:
		Global.set(k, _snapshot[k])
	Global.keybinds = _snapshot["keybinds"].duplicate(true)
	Global._applyVol(BUS_MASTER, Global.masterVol)
	Global._applyVol(BUS_MUSIC, Global.musicVol)
	Global._applyVol(BUS_SFX, Global.sfxVol)
	Global._applyDisplay()
	Global._applyGraphics()
	Global._resetKeybinds()
	Global._applyKeybinds()
	_setDirty(false)

func _touch() -> void:
	_setDirty(true)

func _setDirty(v : bool) -> void:
	_dirty = v
	dirtyLabel.text = "UNSAVED CHANGES" if v else ""
	dirtyLabel.theme_type_variation = "Danger" if v else "Small"
	saveBtn.disabled = not v
	backBtn.text = "◀ DISCARD" if v else "◀ BACK"

func _on_save_pressed() -> void:
	Global._saveSettings()
	_takeSnapshot()
	Audio.play("ui_click", 1.2, -3.0)

func _on_back_pressed() -> void:
	if _dirty:
		_restoreSnapshot()
		_syncAll()
	hide()
	closed.emit()

func _on_reset_pressed() -> void:
	Global._resetDefaultsNoSave()
	Global._resetKeybinds(false)
	_buildBinds()
	_syncAll()
	_touch()

# --- syncing ---------------------------------------------------------------

func _syncAll() -> void:
	volumeSlider.set_value_no_signal(Global.masterVol)
	musicSlider.set_value_no_signal(Global.musicVol)
	sfxSlider.set_value_no_signal(Global.sfxVol)
	displayOption.selected = clamp(Global.displayMode, 0, displayOption.item_count - 1)
	resOption.selected = clamp(Global.resIndex, 0, resOption.item_count - 1)
	fovSlider.set_value_no_signal(Global.fov)
	shakeSlider.set_value_no_signal(Global.screenShake)
	flashCheck.set_pressed_no_signal(Global.reducedFlash)
	scaleSlider.set_value_no_signal(Global.renderScale)
	decalSlider.set_value_no_signal(Global.decalDensity)
	fpsOption.selected = max(FPS_CAPS.find(Global.fpsCap), 0)
	glowCheck.set_pressed_no_signal(Global.glowOn)
	toonCheck.set_pressed_no_signal(Global.toonOutlines)
	sensSlider.set_value_no_signal(Global.sensitivity)
	scopeSensSlider.set_value_no_signal(Global.scopedSens)
	invertCheck.set_pressed_no_signal(Global.invertY)
	scopeToggleCheck.set_pressed_no_signal(Global.toggleScope)
	slideToggleCheck.set_pressed_no_signal(Global.toggleSlide)
	ghostCheck.set_pressed_no_signal(Global.showGhost)
	_syncResEnabled()
	_refreshBinds()

func _syncResEnabled() -> void:
	resOption.disabled = DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_WINDOWED

# --- keybinds --------------------------------------------------------------

func _buildBinds() -> void:
	for c in bindList.get_children():
		c.queue_free()
	_bindRows.clear()
	for action in Global.REBINDABLE:
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		var name = Label.new()
		name.text = Global.REBINDABLE[action]
		name.theme_type_variation = "Accent"
		name.custom_minimum_size = Vector2(340, 0)
		name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(name)
		var btn = Button.new()
		btn.theme_type_variation = "SmallBtn"
		btn.custom_minimum_size = Vector2(220, 50)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(_on_bind_pressed.bind(action))
		row.add_child(btn)
		bindList.add_child(row)
		_bindRows[action] = btn
	_refreshBinds()

func _refreshBinds() -> void:
	for action in _bindRows:
		var btn = _bindRows[action]
		if is_instance_valid(btn):
			btn.text = "PRESS A KEY" if _listening == action else Global._bindLabel(action)

func _on_bind_pressed(action : String) -> void:
	_listening = action
	_refreshBinds()

func _on_reset_binds() -> void:
	_listening = ""
	Global._resetKeybinds(false)
	_refreshBinds()
	_touch()

func _input(event : InputEvent) -> void:
	if _listening == "":
		return
	if event is InputEventKey and event.pressed and not event.echo:
		get_viewport().set_input_as_handled()
		if event.keycode == KEY_ESCAPE:
			_listening = ""
		else:
			if Global._rebind(_listening, event):
				_touch()
			_listening = ""
		_refreshBinds()
	elif event is InputEventMouseButton and event.pressed:
		get_viewport().set_input_as_handled()
		if Global._rebind(_listening, event):
			_touch()
		_listening = ""
		_refreshBinds()
