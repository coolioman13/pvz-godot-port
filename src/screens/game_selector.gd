class_name GameSelector
extends Widget
## Port of GameSelector (main menu) + GameSelectorOverlay.

enum { SELECTOR_OPEN, SELECTOR_NEW_USER, SELECTOR_SHOW_SIGN, SELECTOR_SUB_MENU, SELECTOR_IDLE }

const GAMESELECTOR_ADVENTURE := 100
const GAMESELECTOR_MINIGAME := 101
const GAMESELECTOR_PUZZLE := 102
const GAMESELECTOR_OPTIONS := 103
const GAMESELECTOR_HELP := 104
const GAMESELECTOR_QUIT := 105
const GAMESELECTOR_CHANGE_USER := 106
const GAMESELECTOR_STORE := 107
const GAMESELECTOR_ALMANAC := 108
const GAMESELECTOR_ZEN_GARDEN := 109
const GAMESELECTOR_SURVIVAL := 110
const GAMESELECTOR_ACHIEVEMENT := 111
const GAMESELECTOR_QUICK_PLAY := 112
const GAMESELECTOR_CREDITS := 113

const HAS_QUICKPLAY := true
const HAS_ACHIEVEMENTS := true
const FLOWER_CENTER := [[765.0, 483.0], [663.0, 455.0], [701.0, 439.0]]

class GameSelectorOverlay:
	extends Widget
	var owner_selector: GameSelector

	func _init(gs: GameSelector) -> void:
		owner_selector = gs
		mouse_visible = false

	func draw(g: Graphics) -> void:
		owner_selector.draw_overlay(g)

var adventure_button: NewLawnButton
var minigame_button: NewLawnButton
var puzzle_button: NewLawnButton
var options_button: NewLawnButton
var quit_button: NewLawnButton
var help_button: NewLawnButton
var store_button: NewLawnButton
var almanac_button: NewLawnButton
var zen_garden_button: NewLawnButton
var achievement_button: NewLawnButton
var quick_play_button: NewLawnButton
var credits_button: NewLawnButton
var survival_button: NewLawnButton
var change_user_button: NewLawnButton
var overlay_widget: GameSelectorOverlay
var starting_game := false
var starting_game_counter := 0
var minigames_locked := false
var puzzle_locked := false
var survival_locked := false
var show_start_button := false
var trophy_particle: TodParticleSystem = null
var selector_reanim: Reanimation = null
var cloud_reanims: Array = []
var cloud_counter := [0, 0, 0, 0, 0, 0]
var flower_reanims: Array = []
var leaf_reanim: Reanimation = null
var hand_reanim: Reanimation = null
var leaf_counter := 0
var selector_state := SELECTOR_OPEN
var level := 1
var loading := false
var tool_tip: ToolTipWidget
var has_trophy := false
var unlock_selector_cheat := false
var debug_text := false
var movement_timer := 0
var current_y := 0
var destination_y := 0
var current_x := 0
var destination_x := 0
var enable_buttons_transition := false

static func _img(id: String) -> PvzImage:
	return Res.get_image(id)

func _make(bid: int, normal: String, over: String, down: String) -> NewLawnButton:
	return LawnButtons.make_new_button(bid, self, "", null, _img(normal), _img(over), _img(down))

func _all_buttons() -> Array:
	return [adventure_button, minigame_button, puzzle_button, options_button, quit_button, help_button, change_user_button,
		credits_button, store_button, almanac_button, survival_button, zen_garden_button, achievement_button, quick_play_button]

func _init() -> void:
	level = 1
	tool_tip = ToolTipWidget.new()
	current_y = y
	destination_y = current_y
	current_x = x
	destination_x = current_x

	adventure_button = _make(GAMESELECTOR_ADVENTURE, "IMAGE_REANIM_SELECTORSCREEN_ADVENTURE_BUTTON", "IMAGE_REANIM_SELECTORSCREEN_ADVENTURE_HIGHLIGHT", "IMAGE_REANIM_SELECTORSCREEN_ADVENTURE_HIGHLIGHT")
	adventure_button.resize(0, 0, _img("IMAGE_REANIM_SELECTORSCREEN_ADVENTURE_BUTTON").width, 125)
	adventure_button.clip = false
	adventure_button.mouse_visible = false
	adventure_button.polygon_shape = [Vector2(7, 1), Vector2(328, 30), Vector2(314, 125), Vector2(1, 78)]
	adventure_button.use_polygon_shape = true

	minigame_button = _make(GAMESELECTOR_MINIGAME, "IMAGE_REANIM_SELECTORSCREEN_SURVIVAL_BUTTON", "IMAGE_REANIM_SELECTORSCREEN_SURVIVAL_HIGHLIGHT", "IMAGE_REANIM_SELECTORSCREEN_SURVIVAL_HIGHLIGHT")
	minigame_button.resize(0, 0, _img("IMAGE_REANIM_SELECTORSCREEN_SURVIVAL_BUTTON").width, 130)
	minigame_button.clip = false
	minigame_button.btn_no_draw = true
	minigame_button.mouse_visible = false
	minigame_button.polygon_shape = [Vector2(4, 2), Vector2(312, 51), Vector2(296, 130), Vector2(7, 77)]
	minigame_button.use_polygon_shape = true

	puzzle_button = _make(GAMESELECTOR_PUZZLE, "IMAGE_REANIM_SELECTORSCREEN_CHALLENGES_BUTTON", "IMAGE_REANIM_SELECTORSCREEN_CHALLENGES_HIGHLIGHT", "IMAGE_REANIM_SELECTORSCREEN_CHALLENGES_HIGHLIGHT")
	puzzle_button.resize(0, 0, _img("IMAGE_REANIM_SELECTORSCREEN_CHALLENGES_BUTTON").width, 121)
	puzzle_button.clip = false
	puzzle_button.btn_no_draw = true
	puzzle_button.mouse_visible = false
	puzzle_button.polygon_shape = [Vector2(2, 0), Vector2(281, 55), Vector2(268, 121), Vector2(3, 60)]
	puzzle_button.use_polygon_shape = true

	survival_button = _make(GAMESELECTOR_SURVIVAL, "IMAGE_REANIM_SELECTORSCREEN_VASEBREAKER_BUTTON", "IMAGE_REANIM_SELECTORSCREEN_VASEBREAKER_HIGHLIGHT", "IMAGE_REANIM_SELECTORSCREEN_VASEBREAKER_HIGHLIGHT")
	survival_button.resize(0, 0, _img("IMAGE_REANIM_SELECTORSCREEN_VASEBREAKER_BUTTON").width, 124)
	survival_button.clip = false
	survival_button.btn_no_draw = true
	survival_button.mouse_visible = false
	survival_button.polygon_shape = [Vector2(7, 1), Vector2(267, 62), Vector2(257, 124), Vector2(7, 57)]
	survival_button.use_polygon_shape = true

	zen_garden_button = _make(GAMESELECTOR_ZEN_GARDEN, "IMAGE_SELECTORSCREEN_ZENGARDEN", "IMAGE_SELECTORSCREEN_ZENGARDENHIGHLIGHT", "IMAGE_SELECTORSCREEN_ZENGARDENHIGHLIGHT")
	zen_garden_button.resize(0, 0, 130, 130)
	zen_garden_button.mouse_visible = false
	zen_garden_button.clip = false

	options_button = _make(GAMESELECTOR_OPTIONS, "IMAGE_SELECTORSCREEN_OPTIONS1", "IMAGE_SELECTORSCREEN_OPTIONS2", "IMAGE_SELECTORSCREEN_OPTIONS2")
	options_button.resize(0, 0, _img("IMAGE_SELECTORSCREEN_OPTIONS1").width, _img("IMAGE_SELECTORSCREEN_OPTIONS1").height + 23)
	options_button.btn_no_draw = true
	options_button.mouse_visible = false
	options_button.button_offset_y = 15
	options_button.clip = false

	help_button = _make(GAMESELECTOR_HELP, "IMAGE_SELECTORSCREEN_HELP1", "IMAGE_SELECTORSCREEN_HELP2", "IMAGE_SELECTORSCREEN_HELP2")
	help_button.resize(0, 0, _img("IMAGE_SELECTORSCREEN_HELP1").width, _img("IMAGE_SELECTORSCREEN_HELP1").height + 33)
	help_button.btn_no_draw = true
	help_button.mouse_visible = false
	help_button.button_offset_y = 30
	help_button.clip = false

	quit_button = _make(GAMESELECTOR_QUIT, "IMAGE_SELECTORSCREEN_QUIT1", "IMAGE_SELECTORSCREEN_QUIT2", "IMAGE_SELECTORSCREEN_QUIT2")
	quit_button.resize(0, 0, _img("IMAGE_SELECTORSCREEN_QUIT1").width + 10, _img("IMAGE_SELECTORSCREEN_QUIT1").height + 10)
	quit_button.btn_no_draw = true
	quit_button.mouse_visible = false
	quit_button.button_offset_x = 5
	quit_button.button_offset_y = 5
	quit_button.clip = false

	change_user_button = _make(GAMESELECTOR_CHANGE_USER, "IMAGE_BLANK", "IMAGE_BLANK", "IMAGE_BLANK")
	change_user_button.resize(0, 0, 250, 30)
	change_user_button.btn_no_draw = true
	change_user_button.mouse_visible = false

	overlay_widget = GameSelectorOverlay.new(self)
	overlay_widget.resize(0, 0, PvZ.BOARD_WIDTH, PvZ.BOARD_HEIGHT)

	store_button = _make(GAMESELECTOR_STORE, "IMAGE_SELECTORSCREEN_STORE", "IMAGE_SELECTORSCREEN_STOREHIGHLIGHT", "IMAGE_SELECTORSCREEN_STOREHIGHLIGHT")
	store_button.resize(405, 484, _img("IMAGE_SELECTORSCREEN_STORE").width, _img("IMAGE_SELECTORSCREEN_STORE").height)
	store_button.mouse_visible = false
	store_button.clip = false

	almanac_button = _make(GAMESELECTOR_ALMANAC, "IMAGE_SELECTORSCREEN_ALMANAC", "IMAGE_SELECTORSCREEN_ALMANACHIGHLIGHT", "IMAGE_SELECTORSCREEN_ALMANACHIGHLIGHT")
	almanac_button.resize(327, 428, _img("IMAGE_SELECTORSCREEN_ALMANAC").width, _img("IMAGE_SELECTORSCREEN_ALMANAC").height)
	almanac_button.mouse_visible = false
	almanac_button.clip = false

	achievement_button = _make(GAMESELECTOR_ACHIEVEMENT, "IMAGE_ACHIEVEMENT_BUTTON", "IMAGE_ACHIEVEMENT_HIGHLIGHT", "IMAGE_ACHIEVEMENT_HIGHLIGHT")
	var ab := _img("IMAGE_ACHIEVEMENT_BUTTON")
	achievement_button.resize(20, PvZ.BOARD_HEIGHT - ab.height - 35, ab.width, ab.height)
	achievement_button.clip = false
	achievement_button.mouse_visible = false

	quick_play_button = _make(GAMESELECTOR_QUICK_PLAY, "IMAGE_QUICKPLAY_BUTTON", "IMAGE_QUICKPLAY_BUTTON_HIGHLIGHT", "IMAGE_QUICKPLAY_BUTTON_HIGHLIGHT")
	var qb := _img("IMAGE_QUICKPLAY_BUTTON")
	quick_play_button.resize(300, PvZ.BOARD_HEIGHT - qb.height - 100, qb.width, qb.height)
	quick_play_button.clip = false
	quick_play_button.mouse_visible = false
	quick_play_button.set_disabled(false)
	quick_play_button.visible = true

	credits_button = _make(GAMESELECTOR_CREDITS, "IMAGE_BLANK", "IMAGE_BLANK", "IMAGE_BLANK")
	var w3 := _img("IMAGE_REANIM_SELECTORSCREEN_WOODSIGN3_PRESS")
	credits_button.resize(0, 0, w3.width, w3.height)
	credits_button.btn_no_draw = true
	credits_button.mouse_visible = false

	App.music.make_sure_music_is_playing(PvZ.MUSIC_TUNE_TITLE_CRAZY_DAVE_MAIN_THEME)

	selector_reanim = App.add_reanimation(0.5 + PvZ.BOARD_ADDITIONAL_WIDTH, 0.5 + PvZ.BOARD_OFFSET_Y, 0, PvZ.REANIM_SELECTOR_SCREEN)
	selector_reanim.play_reanim("anim_open", Reanimation.REANIM_PLAY_ONCE_AND_HOLD, 0, 30.0)
	selector_reanim.assign_render_group_to_prefix("flower", Reanimation.RENDER_GROUP_HIDDEN)
	selector_reanim.assign_render_group_to_prefix("leaf", Reanimation.RENDER_GROUP_HIDDEN)
	selector_reanim.assign_render_group_to_track("SelectorScreen_BG", 1)
	selector_reanim.assign_render_group_to_prefix("SelectorScreen_Adventure_", Reanimation.RENDER_GROUP_NORMAL)
	selector_reanim.assign_render_group_to_prefix("SelectorScreen_StartAdventure_", Reanimation.RENDER_GROUP_HIDDEN)
	selector_state = SELECTOR_OPEN
	var frames := selector_reanim.get_frames_for_layer("anim_sign")
	selector_reanim.frame_base_pose = frames.x + frames.y - 1

	for i in 6:
		var cloud := App.add_reanimation(0.5, 0.5, 0, PvZ.REANIM_SELECTOR_SCREEN)
		cloud.play_reanim("anim_cloud%d" % (i + 2 if i > 1 else i + 1), Reanimation.REANIM_PLAY_ONCE_AND_HOLD, 0, 0.0)
		cloud_reanims.append(cloud)
		cloud_counter[i] = Tod.rand_range_int(-6000, 2000)
		if cloud_counter[i] < 0:
			cloud.anim_time = -cloud_counter[i] / 6000.0
			cloud.anim_rate = 0.5
			cloud_counter[i] = 0
		else:
			cloud.anim_rate = 0.0

	for i in 3:
		var flower := App.add_reanimation(0.5 + PvZ.BOARD_ADDITIONAL_WIDTH, 0.5 + PvZ.BOARD_OFFSET_Y, 0, PvZ.REANIM_SELECTOR_SCREEN)
		flower.play_reanim("anim_flower%d" % (i + 1), Reanimation.REANIM_PLAY_ONCE_AND_HOLD, 0, 0.0)
		flower.anim_rate = 0.0
		flower.attach_to_another_reanimation(selector_reanim, "SelectorScreen_BG_Right")
		flower.is_attachment = false
		flower_reanims.append(flower)

	leaf_reanim = App.add_reanimation(0.5 + PvZ.BOARD_ADDITIONAL_WIDTH, 0.5 + PvZ.BOARD_OFFSET_Y, 0, PvZ.REANIM_SELECTOR_SCREEN)
	leaf_reanim.play_reanim("anim_grass", Reanimation.REANIM_LOOP, 0, 6.0)
	leaf_reanim.anim_rate = 0.0
	leaf_counter = 50

	sync_profile(false)
	App.play_sample("SOUND_ROLL_IN")

func dispose() -> void:
	for r in cloud_reanims + flower_reanims + [selector_reanim, leaf_reanim, hand_reanim]:
		if r and not r.dead:
			r.die()
	if trophy_particle and not trophy_particle.dead:
		trophy_particle.particle_system_die()

func sync_buttons() -> void:
	var almanac_available := App.can_show_almanac() or unlock_selector_cheat
	var store_open := App.can_show_store() or unlock_selector_cheat
	var zen_open := App.can_show_zen_garden() or unlock_selector_cheat

	almanac_button.disabled = not almanac_available
	almanac_button.visible = almanac_available
	quick_play_button.disabled = not App.has_finished_adventure()
	quick_play_button.visible = App.has_finished_adventure()
	store_button.disabled = not store_open
	store_button.visible = store_open

	if almanac_available:
		selector_reanim.assign_render_group_to_prefix("almanac_key_shadow", Reanimation.RENDER_GROUP_NORMAL)
		selector_reanim.set_image_override("almanac_key_shadow", null if store_open else _img("IMAGE_REANIM_SELECTORSCREEN_ALMANAC_SHADOW"))
	elif store_open:
		selector_reanim.assign_render_group_to_prefix("almanac_key_shadow", Reanimation.RENDER_GROUP_NORMAL)
		selector_reanim.set_image_override("almanac_key_shadow", _img("IMAGE_REANIM_SELECTORSCREEN_KEY_SHADOW"))
	else:
		selector_reanim.assign_render_group_to_prefix("almanac_key_shadow", Reanimation.RENDER_GROUP_HIDDEN)

	zen_garden_button.disabled = not zen_open
	zen_garden_button.visible = zen_open

	var locks := [[minigame_button, minigames_locked, "SURVIVAL"], [puzzle_button, puzzle_locked, "CHALLENGES"], [survival_button, survival_locked, "VASEBREAKER"]]
	for l in locks:
		var b: NewLawnButton = l[0]
		if l[1]:
			b.over_image = _img("IMAGE_REANIM_SELECTORSCREEN_%s_BUTTON" % l[2])
			b.down_image = b.over_image
			b.set_color(ButtonWidget.COLOR_BKG, Color8(128, 128, 128))
		else:
			b.over_image = _img("IMAGE_REANIM_SELECTORSCREEN_%s_HIGHLIGHT" % l[2])
			b.down_image = b.over_image
			b.set_color(ButtonWidget.COLOR_BKG, Color.WHITE)

	selector_reanim.get_track_instance("SelectorScreen_Survival_button").track_color = minigame_button.get_color(ButtonWidget.COLOR_BKG)
	selector_reanim.get_track_instance("SelectorScreen_Challenges_button").track_color = puzzle_button.get_color(ButtonWidget.COLOR_BKG)
	selector_reanim.get_track_instance("SelectorScreen_ZenGarden_button").track_color = survival_button.get_color(ButtonWidget.COLOR_BKG)

	if show_start_button:
		adventure_button.button_image = _img("IMAGE_REANIM_SELECTORSCREEN_STARTADVENTURE_BUTTON")
		adventure_button.over_image = _img("IMAGE_REANIM_SELECTORSCREEN_STARTADVENTURE_HIGHLIGHT")
	else:
		adventure_button.button_image = _img("IMAGE_REANIM_SELECTORSCREEN_ADVENTURE_BUTTON")
		adventure_button.over_image = _img("IMAGE_REANIM_SELECTORSCREEN_ADVENTURE_HIGHLIGHT")
	adventure_button.down_image = adventure_button.over_image

func add_trophy_sparkle() -> void:
	trophy_particle = App.add_tod_particle(85.0 + PvZ.BOARD_ADDITIONAL_WIDTH, 380.0 + PvZ.BOARD_OFFSET_Y, PvZ.RENDER_LAYER_TOP, PvZ.PARTICLE_TROPHY_SPARKLE)

func sync_profile(show_loading: bool) -> void:
	if show_loading:
		loading = true
		loading = false

	if trophy_particle and not trophy_particle.dead:
		trophy_particle.particle_system_die()
	trophy_particle = null

	level = 1
	if App.player_info:
		level = App.player_info.level
	show_start_button = true
	minigames_locked = true
	puzzle_locked = true
	survival_locked = true
	if App.player_info and not App.is_ice_demo():
		if level >= 2:
			show_start_button = false
		if App.has_finished_adventure():
			minigames_locked = false
			survival_locked = false
			puzzle_locked = false
			show_start_button = false
		if App.player_info.has_unlocked_minigames:
			minigames_locked = false
		if App.player_info.has_unlocked_puzzle_mode:
			puzzle_locked = false
		if App.player_info.has_unlocked_survival_mode:
			survival_locked = false
		if App.is_trial_stage_locked():
			puzzle_locked = true
			survival_locked = true

	has_trophy = App.has_finished_adventure() and not App.is_trial_stage_locked()
	if has_trophy and selector_state != SELECTOR_OPEN:
		add_trophy_sparkle()
	sync_buttons()
	AlmanacDialog.almanac_init_for_player()
	BoardCore.shown_more_sun_tutorial = false  # BoardInitForPlayer

func _track_transform(track: String) -> Reanimation.Transform:
	var t := Reanimation.Transform.new()
	selector_reanim.get_current_transform(selector_reanim.find_track_index(track), t)
	return t

func draw(g: Graphics) -> void:
	if App.get_dialog(PvZ.DIALOG_STORE) or App.get_dialog(PvZ.DIALOG_ALMANAC):
		return
	g.set_linear_blend(true)
	selector_reanim.draw_render_group(g, 1)
	for c in cloud_reanims:
		c.draw(g)
	selector_reanim.draw_render_group(g, Reanimation.RENDER_GROUP_NORMAL)

	if selector_state == SELECTOR_OPEN:
		var t := _track_transform("SelectorScreen_BG_Right")
		var fx := fmod(t.tx, 1.0)
		var fy := fmod(t.ty, 1.0)
		for b in [options_button, quit_button, help_button]:
			g.draw_image_f(b.button_image, b.x + b.button_offset_x + fx, b.y + b.button_offset_y + fy)

	if App.player_info and App.player_info.name.length() > 0 and selector_state != SELECTOR_OPEN and selector_state != SELECTOR_NEW_USER:
		var welcome: String = App.player_info.name + "!"
		var overlay := selector_reanim.get_attachment_overlay_matrix(selector_reanim.find_track_index("woodsign1"))
		var font := Res.get_font("FONT_BRIANNETOD16")
		var sw := font.string_width(welcome)
		var offset := Transform2D(Vector2(1, 0), Vector2(0, 1), Vector2(170.5 - int(sw * 0.5) + x, 102.5 + y))
		font.draw_string_matrix(g, overlay * offset, welcome, Color8(255, 245, 200))

func draw_overlay(g: Graphics, _priority: int = 0) -> void:
	g.set_linear_blend(true)
	if App.player_info == null:
		return

	if not App.is_ice_demo() and not show_start_button:
		var ox := 1 if adventure_button.is_down and adventure_button.is_over else 0
		var oy := ox
		var t := _track_transform("SelectorScreen_BG_Right")
		var area_x: float = t.tx + ox + PvZ.BOARD_ADDITIONAL_WIDTH
		var area_y: float = t.ty + oy + PvZ.BOARD_OFFSET_Y
		var sub_x := area_x
		var sub_y := area_y

		var stage := clampi(Tod.idiv(level - 1, 10) + 1, 1, 6)
		var sub := level - (stage - 1) * 10
		if App.is_trial_stage_locked() and (level >= 25 or App.has_finished_adventure()):
			stage = 3
			sub = 4
		else:
			if stage == 1:
				area_y += 1.0
			elif stage == 4:
				area_x -= 1.0
			if sub == 3:
				sub_x -= 1.0

		var nums := _img("IMAGE_SELECTORSCREEN_LEVELNUMBERS")
		g.set_colorize_images(true)
		g.set_color(adventure_button.colors[ButtonWidget.COLOR_BKG])
		g.tod_draw_image_cel_f(nums, area_x + 486.0 + 111, area_y + 125.0 - 77.5 + 80, stage, 0)
		if sub < 10:
			g.tod_draw_image_cel_f(nums, sub_x + 512.0 + 111, sub_y + 128.0 - 77.5 + 80, sub, 0)
		elif sub == 10:
			g.tod_draw_image_cel_f(nums, sub_x + 506.0 + 111, sub_y + 128.0 - 77.5 + 80, 1, 0)
			g.tod_draw_image_cel_f(nums, sub_x + 515.0 + 111, sub_y + 129.0 - 77.5 + 80, 0, 0)
		g.set_colorize_images(false)

		var tl := _track_transform("SelectorScreen_BG_Left")
		if has_trophy:
			var ach_offset := 0.0 if HAS_ACHIEVEMENTS else 45.0
			var cel := 1 if App.earned_gold_trophy() else 0
			g.tod_draw_image_cel_f(_img("IMAGE_SUNFLOWER_TROPHY"), tl.tx + 10.0 + PvZ.BOARD_ADDITIONAL_WIDTH + 370, tl.ty + 350.0 + PvZ.BOARD_OFFSET_Y + 60 + ach_offset, cel, 0)
			if trophy_particle and not trophy_particle.dead:
				trophy_particle.draw(g)

	if zen_garden_button.visible and App.zen_garden.plants_need_water():
		g.draw_image(_img("IMAGE_PLANTSPEECHBUBBLE"), zen_garden_button.x + 106, zen_garden_button.y + 36)
		g.draw_image(_img("IMAGE_WATERDROP"), zen_garden_button.x + 123, zen_garden_button.y + 45)

	if hand_reanim and not hand_reanim.dead:
		var hg := g.copy()
		hg.set_clip_rect(0, 0, PvZ.BOARD_WIDTH, PvZ.BOARD_HEIGHT - 40)
		hand_reanim.draw(hg)
	leaf_reanim.draw(g)

	for i in 3:
		var flower: Reanimation = flower_reanims[i]
		if flower.track_instances[i].blend_transform.frame == flower.frame_count:
			break
		flower.draw(g)

	tool_tip.draw(g)

func update_tooltip() -> void:
	if not App.has_finished_adventure() or App.get_dialog(PvZ.DIALOG_MESSAGE):
		return
	if has_trophy:
		var mx := App.widget_manager.last_mouse_x
		var my := App.widget_manager.last_mouse_y
		if Rect2i(50 + PvZ.BOARD_ADDITIONAL_WIDTH, 325 + PvZ.BOARD_OFFSET_Y, 85, 142 if HAS_ACHIEVEMENTS else 225).has_point(Vector2i(mx, my)):
			if App.earned_gold_trophy():
				tool_tip.set_label(App.pluralize(App.player_info.finished_adventure, "[GOLD_SUNFLOWER_TOOLTIP]", "[GOLD_SUNFLOWER_TOOLTIP_PLURAL]"))
				tool_tip.x = 32 + PvZ.BOARD_ADDITIONAL_WIDTH
				tool_tip.y = 510 + PvZ.BOARD_OFFSET_Y
			else:
				tool_tip.set_label("[SILVER_SUNFLOWER_TOOLTIP]")
				tool_tip.x = 20 + PvZ.BOARD_ADDITIONAL_WIDTH
				tool_tip.y = 495 + PvZ.BOARD_OFFSET_Y
			tool_tip.visible = true
			return
	tool_tip.visible = false
	tool_tip.update()

func update() -> void:
	super.update()
	update_tooltip()
	App.zen_garden.update_plant_needs()

	if movement_timer > 0:
		var py := calc_y_pos(current_y, destination_y)
		var px := calc_x_pos(current_x, destination_x)
		y = py
		x = px
		if App.achievement_screen:
			App.achievement_screen.y = py + PvZ.BOARD_HEIGHT - 1
		if App.quick_play_screen:
			App.quick_play_screen.x = px + PvZ.BOARD_WIDTH - 1
		overlay_widget.x = px
		overlay_widget.y = py
		for b in [adventure_button, minigame_button, puzzle_button, store_button, almanac_button, zen_garden_button,
				survival_button, change_user_button, credits_button, achievement_button, quick_play_button]:
			b.set_button_offset(px, py)
		options_button.set_button_offset(px, py + 15)
		quit_button.set_button_offset(px + 5, py + 5)
		help_button.set_button_offset(px, py + 30)
		movement_timer -= 1
	elif movement_timer == 0:
		current_y = y
		current_x = x
		if enable_buttons_transition:
			for b in _all_buttons():
				b.set_disabled(false)
			enable_buttons_transition = false

	if trophy_particle and not trophy_particle.dead:
		trophy_particle.update()

	if starting_game:
		starting_game_counter += 1
		if starting_game_counter > 450:
			App.kill_game_selector()
			if App.is_ice_demo():
				App.pre_new_game(PvZ.GAMEMODE_CHALLENGE_ICE, false)
				return
			# WIDETWEAK: fixed the intro not playing the first time you start Adventure mode
			if App.is_first_time_adventure_mode() and level == 1:
				App.pre_new_game(PvZ.GAMEMODE_INTRO, false)
				return
			if App.player_info.needs_magic_taco_reward and level == 35:
				var store := App.show_store_screen()
				store.setup_for_intro(601)
				await store.wait_for_result(true)
				App.pre_new_game(PvZ.GAMEMODE_ADVENTURE, false)
				return
			if should_do_zen_tuturial_before_adventure():
				App.pre_new_game(PvZ.GAMEMODE_CHALLENGE_ZEN_GARDEN, false)
				App.zen_garden.setup_for_zen_tutorial()
				return
			App.pre_new_game(PvZ.GAMEMODE_ADVENTURE, true)
			return
		adventure_button.set_color(ButtonWidget.COLOR_BKG, Color8(80, 80, 80) if starting_game_counter % 20 < 10 else Color.WHITE)
		if starting_game_counter == 125:
			App.play_sample("SOUND_EVILLAUGH")

	match selector_state:
		SELECTOR_OPEN:
			if widget_manager:
				widget_manager.rehup_mouse()
			if selector_reanim.loop_count > 0:
				for t in ["SelectorScreen_Adventure_button", "SelectorScreen_StartAdventure_button", "SelectorScreen_Survival_button",
						"SelectorScreen_Challenges_button", "SelectorScreen_ZenGarden_button"]:
					selector_reanim.assign_render_group_to_track(t, Reanimation.RENDER_GROUP_HIDDEN)
				for b in [minigame_button, puzzle_button, survival_button, zen_garden_button, help_button, options_button, quit_button, quick_play_button]:
					b.btn_no_draw = false
				for b in _all_buttons():
					b.mouse_visible = true

				if App.player_info == null:
					App.do_create_user_dialog()
					selector_state = SELECTOR_NEW_USER
				else:
					selector_reanim.play_reanim("anim_sign", Reanimation.REANIM_PLAY_ONCE_AND_HOLD, 0, 30.0)
					selector_state = SELECTOR_IDLE

				if has_trophy:
					add_trophy_sparkle()

				if App.player_info and App.player_info.needs_message_on_game_selector:
					App.player_info.needs_message_on_game_selector = 0
					App.write_current_user_config()
					App.lawn_message_box(PvZ.DIALOG_MESSAGE, "[ADVENTURE_COMPLETE_HEADER]", "[ADVENTURE_COMPLETE_BODY]", "[DIALOG_BUTTON_OK]", "", Dialog.BUTTONS_FOOTER)
		SELECTOR_NEW_USER:
			if App.get_dialog(PvZ.DIALOG_CREATEUSER) == null:
				selector_reanim.play_reanim("anim_sign", Reanimation.REANIM_PLAY_ONCE_AND_HOLD, 0, 30.0)
				selector_state = SELECTOR_SHOW_SIGN
		SELECTOR_SHOW_SIGN:
			if selector_reanim.loop_count > 0:
				selector_state = SELECTOR_IDLE

	for i in 6:
		var cloud: Reanimation = cloud_reanims[i]
		if cloud_counter[i] > 0:
			cloud_counter[i] -= 1
			if cloud_counter[i] == 0:
				cloud.loop_count = 0
				cloud.anim_time = 0.0
				cloud.anim_rate = 0.5
		elif cloud.loop_count > 0:
			cloud_counter[i] = Tod.rand_range_int(2000, 4000)
	selector_reanim.update()

	leaf_reanim.update()
	var lt := _track_transform("SelectorScreen_BG_Right")
	leaf_reanim.set_position(lt.tx - 71.0 + PvZ.BOARD_ADDITIONAL_WIDTH, lt.ty - 41.0 + PvZ.BOARD_OFFSET_Y)
	leaf_counter -= 1
	if leaf_counter == 0:
		leaf_reanim.play_reanim("anim_grass", Reanimation.REANIM_LOOP, 20, Tod.rand_range_float(3.0, 12.0))
		leaf_counter = Tod.rand_range_int(200, 400)

	for c in cloud_reanims:
		c.update()
	if hand_reanim and not hand_reanim.dead:
		hand_reanim.update()

	if selector_state != SELECTOR_SUB_MENU:
		if movement_timer == 0:
			App.kill_achievement_screen()
			App.kill_quick_play_screen()
		var ax := PvZ.BOARD_ADDITIONAL_WIDTH
		var ay := PvZ.BOARD_OFFSET_Y
		track_button(adventure_button, "SelectorScreen_StartAdventure_button" if show_start_button else "SelectorScreen_Adventure_button", ax, ay)
		track_button(minigame_button, "SelectorScreen_Survival_button", ax, ay)
		track_button(puzzle_button, "SelectorScreen_Challenges_button", ax, ay)
		track_button(survival_button, "SelectorScreen_ZenGarden_button", ax, ay)
		track_button(zen_garden_button, "SelectorScreen_BG_Right", 100.0 + ax + 111, 360.0 + ay + 80)
		track_button(options_button, "SelectorScreen_BG_Right", 494.0 + ax + 111, 434.0 + ay + 80)
		track_button(quit_button, "SelectorScreen_BG_Right", 644.0 + ax + 111, 469.0 + ay + 80)
		track_button(help_button, "SelectorScreen_BG_Right", 576.0 + ax + 111, 458.0 + ay + 80)
		track_button(almanac_button, "SelectorScreen_BG_Right", 256.0 + ax + 111, 387.0 + ay + 80)
		track_button(store_button, "SelectorScreen_BG_Right", 334.0 + ax + 111, 441.0 + ay + 80)
		track_button(change_user_button, "woodsign2", 24.0 + ax, 10.0 + ay)
		track_button(credits_button, "woodsign3", 0.0 + ax, 0.0 + ay)
		track_button(achievement_button, "SelectorScreen_BG_Left", 390.0 + ax, 540.0 + ay)
		track_button(quick_play_button, "SelectorScreen_BG_Right", 190.0 + ax, 310.0 + ay)
		selector_reanim.set_image_override("woodsign2", _img("IMAGE_REANIM_SELECTORSCREEN_WOODSIGN2_PRESS") if (change_user_button.is_over or change_user_button.is_down) else null)
		selector_reanim.set_image_override("woodsign3", _img("IMAGE_REANIM_SELECTORSCREEN_WOODSIGN3_PRESS") if (credits_button.is_over or credits_button.is_down) else null)

func track_button(button: Widget, track: String, ox: float, oy: float) -> void:
	var t := _track_transform(track)
	button.x = int(t.tx + ox)
	button.y = int(t.ty + oy)

func _managed_widgets() -> Array:
	var list := [adventure_button, minigame_button, puzzle_button, options_button, quit_button, help_button, store_button,
		almanac_button, survival_button, zen_garden_button, change_user_button, credits_button, overlay_widget]
	if HAS_ACHIEVEMENTS:
		list.append(achievement_button)
	if HAS_QUICKPLAY:
		list.append(quick_play_button)
	return list

func added_to_manager(wm: WidgetManager) -> void:
	super.added_to_manager(wm)
	for w in _managed_widgets():
		wm.add_widget(w)

func removed_from_manager(wm: WidgetManager) -> void:
	super.removed_from_manager(wm)
	for w in _managed_widgets():
		wm.remove_widget(w)

func order_in_manager_changed() -> void:
	for w in [overlay_widget, almanac_button, store_button, help_button, quit_button, options_button, adventure_button,
			minigame_button, puzzle_button, zen_garden_button, survival_button, change_user_button, credits_button]:
		widget_manager.put_infront(w, self)
	if HAS_ACHIEVEMENTS:
		widget_manager.put_infront(achievement_button, self)
	if HAS_QUICKPLAY:
		widget_manager.put_infront(quick_play_button, self)

func key_down(key: int) -> void:
	if App.konami_check.check(key):
		App.play_foley(PvZ.FOLEY_DROP)
		return
	if App.mustache_check.check(key) or App.moustache_check.check(key):
		App.play_foley(PvZ.FOLEY_POLEVAULT)
		App.mustache_mode = not App.mustache_mode
		return
	if App.super_mower_check.check(key) or App.super_mower_check2.check(key):
		App.play_foley(PvZ.FOLEY_ZAMBONI)
		App.super_mower_mode = not App.super_mower_mode
		return
	if App.future_check.check(key):
		App.play_sample("SOUND_BOING")
		App.future_mode = not App.future_mode
		return
	if App.pinata_check.check(key):
		if App.can_do_pinata_mode():
			App.play_foley(PvZ.FOLEY_JUICY)
			App.pinata_mode = not App.pinata_mode
		else:
			App.play_sample("SOUND_BUZZER")
		return
	if App.dance_check.check(key):
		if App.can_do_dance_mode():
			App.play_foley(PvZ.FOLEY_DANCER)
			App.dance_mode = not App.dance_mode
		else:
			App.play_sample("SOUND_BUZZER")
		return
	if App.daisy_check.check(key):
		if App.can_do_daisy_mode():
			App.play_sample("SOUND_LOADINGBAR_FLOWER")
			App.daisy_mode = not App.daisy_mode
		else:
			App.play_sample("SOUND_BUZZER")
		return
	if App.sukhbir_check.check(key):
		App.play_sample("SOUND_SUKHBIR")
		App.sukhbir_mode = not App.sukhbir_mode
		return

func key_char(ch: String) -> void:
	if starting_game:
		return
	if App.debug_keys_enabled:
		if ch == "u" and App.player_info:
			var pi := App.player_info
			pi.finished_adventure = 2
			pi.add_coins(50000)
			pi.has_used_cheat_keys = 1
			pi.has_unlocked_minigames = 1
			pi.has_unlocked_puzzle_mode = 1
			pi.has_unlocked_survival_mode = 1
			for i in range(1, 100):
				if i != PvZ.GAMEMODE_TREE_OF_WISDOM and i != PvZ.GAMEMODE_SCARY_POTTER_ENDLESS and i != PvZ.GAMEMODE_PUZZLE_I_ZOMBIE_ENDLESS \
						and i != PvZ.GAMEMODE_SURVIVAL_ENDLESS_STAGE_3 and i - 1 < pi.challenge_records.size():
					pi.challenge_records[i - 1] = 20
			sync_profile(true)
			SaveGame.erase_saved_game(PvZ.GAMEMODE_ADVENTURE, pi.id)
		if ch == "c" or ch == "C":
			minigames_locked = false
			puzzle_locked = false
			survival_locked = false
			sync_buttons()
		if ch == "a":
			debug_text = not debug_text
			return
		if ch == "p":
			add_preview_profiles()

## GameSelector::AddPreviewProfiles (debug key 'p'): ready-made profiles at the start of each area.
func add_preview_profiles() -> void:
	var pm: ProfileMgr = App.profile_mgr
	var pr := pm.add_profile("2 Night")
	if pr:
		pr.level = 11
		pr.save_details()
	pr = pm.add_profile("3 Pool")
	if pr:
		pr.level = 21
		pr.has_unlocked_minigames = 1
		pr.coins = 400
		pr.purchases[PvZ.STORE_ITEM_PACKET_UPGRADE] = 1
		pr.save_details()
	pr = pm.add_profile("4 Fog")
	if pr:
		pr.level = 31
		pr.has_unlocked_minigames = 1
		pr.has_unlocked_survival_mode = 1
		pr.purchases[PvZ.STORE_ITEM_PACKET_UPGRADE] = 2
		pr.purchases[PvZ.STORE_ITEM_POOL_CLEANER] = 1
		pr.coins = 400
		pr.save_details()
	pr = pm.add_profile("5 Roof")
	if pr:
		pr.level = 41
		pr.has_unlocked_minigames = 1
		pr.has_unlocked_puzzle_mode = 1
		pr.has_unlocked_survival_mode = 1
		pr.purchases[PvZ.STORE_ITEM_PACKET_UPGRADE] = 2
		pr.purchases[PvZ.STORE_ITEM_POOL_CLEANER] = 1
		pr.coins = 500
		pr.save_details()
	pr = pm.add_profile("Complete")
	if pr:
		pr.level = 1
		pr.finished_adventure = 1
		pr.has_unlocked_minigames = 1
		pr.has_unlocked_puzzle_mode = 1
		pr.has_unlocked_survival_mode = 1
		pr.purchases[PvZ.STORE_ITEM_PACKET_UPGRADE] = 2
		pr.purchases[PvZ.STORE_ITEM_POOL_CLEANER] = 1
		pr.purchases[PvZ.STORE_ITEM_ROOF_CLEANER] = 1
		pr.coins = 1000
		pr.save_details()
	pr = pm.add_profile("Full Unlock")
	if pr:
		pr.level = 1
		pr.finished_adventure = 2
		pr.add_coins(50000)
		for item in [PvZ.STORE_ITEM_FERTILIZER, PvZ.STORE_ITEM_BUG_SPRAY, PvZ.STORE_ITEM_CHOCOLATE, PvZ.STORE_ITEM_TREE_FOOD]:
			pr.purchases[item] = PlayerInfo.PURCHASE_COUNT_OFFSET + 5
		pr.has_unlocked_minigames = 1
		pr.has_unlocked_puzzle_mode = 1
		for item in [PvZ.STORE_ITEM_PLANT_GATLINGPEA, PvZ.STORE_ITEM_PLANT_TWINSUNFLOWER, PvZ.STORE_ITEM_PLANT_GLOOMSHROOM,
				PvZ.STORE_ITEM_PLANT_CATTAIL, PvZ.STORE_ITEM_PLANT_WINTERMELON, PvZ.STORE_ITEM_PLANT_GOLD_MAGNET,
				PvZ.STORE_ITEM_PLANT_SPIKEROCK, PvZ.STORE_ITEM_PLANT_COBCANNON, PvZ.STORE_ITEM_PLANT_IMITATER,
				PvZ.STORE_ITEM_POOL_CLEANER, PvZ.STORE_ITEM_ROOF_CLEANER, PvZ.STORE_ITEM_PHONOGRAPH, PvZ.STORE_ITEM_GARDENING_GLOVE,
				PvZ.STORE_ITEM_MUSHROOM_GARDEN, PvZ.STORE_ITEM_WHEEL_BARROW, PvZ.STORE_ITEM_AQUARIUM_GARDEN, PvZ.STORE_ITEM_TREE_OF_WISDOM]:
			pr.purchases[item] = 1
		pr.purchases[PvZ.STORE_ITEM_PACKET_UPGRADE] = 3
		pr.challenge_records[PvZ.GAMEMODE_TREE_OF_WISDOM - 1] = 1
		# The original writes these trophies to the *current* profile, not the new one; kept as-is.
		if App.player_info:
			for i in range(1, 100):
				if i != PvZ.GAMEMODE_TREE_OF_WISDOM and i != PvZ.GAMEMODE_SCARY_POTTER_ENDLESS and i != PvZ.GAMEMODE_PUZZLE_I_ZOMBIE_ENDLESS \
						and i != PvZ.GAMEMODE_SURVIVAL_ENDLESS_STAGE_3 and i - 1 < App.player_info.challenge_records.size():
					App.player_info.challenge_records[i - 1] = 20
		pr.save_details()
	pm.save()

func mouse_down(mx: int, my: int, _click_count: int) -> void:
	for i in 3:
		var flower: Reanimation = flower_reanims[i]
		if flower.anim_rate <= 0.0 and Tod.distance_2d(mx - PvZ.BOARD_ADDITIONAL_WIDTH, my - PvZ.BOARD_OFFSET_Y, FLOWER_CENTER[i][0], FLOWER_CENTER[i][1]) < 20.0:
			flower.anim_rate = 24.0
			App.play_foley(PvZ.FOLEY_LIMBS_POP)
	if App.tod_cheat_keys and starting_game and starting_game_counter < 450:
		starting_game_counter = 450

func button_mouse_enter(bid: int) -> void:
	if (bid == GAMESELECTOR_MINIGAME and minigames_locked) or (bid == GAMESELECTOR_PUZZLE and puzzle_locked) or (bid == GAMESELECTOR_SURVIVAL and survival_locked):
		return
	App.play_foley(PvZ.FOLEY_BLEEP)

func button_press(bid: int, _count: int = 1) -> void:
	if bid in [GAMESELECTOR_ADVENTURE, GAMESELECTOR_MINIGAME, GAMESELECTOR_PUZZLE, GAMESELECTOR_SURVIVAL]:
		App.play_sample("SOUND_GRAVEBUTTON")
	else:
		App.play_sample("SOUND_TAP")

func _set_buttons_disabled(d: bool) -> void:
	for b in _all_buttons():
		b.set_disabled(d)

func clicked_adventure() -> void:
	if App.is_trial_stage_locked() and (level >= 25 or App.has_finished_adventure()):
		var r := await App.lawn_message_box(PvZ.DIALOG_MESSAGE, "[REPLAY_LEVEL_HEADER]", "[REPLAY_LEVEL_BODY]", "[DIALOG_BUTTON_YES]", "[DIALOG_BUTTON_NO]", Dialog.BUTTONS_YES_NO)
		if r == Dialog.ID_NO:
			return
		App.player_info.level = 24
		App.player_info.finished_adventure = 0
		SaveGame.erase_saved_game(PvZ.GAMEMODE_ADVENTURE, App.player_info.id)

	App.music.stop_all_music()
	App.play_sample("SOUND_LOSEMUSIC")
	starting_game = true
	_set_buttons_disabled(true)

	hand_reanim = App.add_reanimation(-70.0 + PvZ.BOARD_ADDITIONAL_WIDTH, 10.0 + PvZ.BOARD_OFFSET_Y, 0, PvZ.REANIM_ZOMBIE_HAND)
	hand_reanim.loop_type = Reanimation.REANIM_PLAY_ONCE_AND_HOLD
	App.play_foley(PvZ.FOLEY_DIRT_RISE)
	for i in hand_reanim.definition.tracks.size():
		if hand_reanim.definition.tracks[i].name.substr(0, 4).to_lower() == "rock":
			hand_reanim.track_instances[i].ignore_clip_rect = true

func should_do_zen_tuturial_before_adventure() -> bool:
	return not App.has_finished_adventure() and App.player_info.level == 45 and App.player_info.num_potted_plants() == 0

func button_depress(bid: int) -> void:
	if bid == GAMESELECTOR_MINIGAME and minigames_locked:
		App.lawn_message_box(PvZ.DIALOG_MESSAGE, "[MODE_LOCKED]", "[MINIGAME_LOCKED_MESSAGE]", "[DIALOG_BUTTON_OK]", "", Dialog.BUTTONS_FOOTER)
		return
	if bid == GAMESELECTOR_PUZZLE and puzzle_locked:
		App.lawn_message_box(PvZ.DIALOG_MESSAGE, "[MODE_LOCKED]", "[PUZZLE_LOCKED_MESSAGE]", "[DIALOG_BUTTON_OK]", "", Dialog.BUTTONS_FOOTER)
		return
	if bid == GAMESELECTOR_SURVIVAL and survival_locked:
		App.lawn_message_box(PvZ.DIALOG_MESSAGE, "[MODE_LOCKED]", "[SURVIVAL_LOCKED_MESSAGE]", "[DIALOG_BUTTON_OK]", "", Dialog.BUTTONS_FOOTER)
		return

	match bid:
		GAMESELECTOR_ADVENTURE:
			clicked_adventure()
		GAMESELECTOR_MINIGAME:
			App.kill_game_selector()
			App.show_challenge_screen(PvZ.CHALLENGE_PAGE_CHALLENGE)
		GAMESELECTOR_PUZZLE:
			App.kill_game_selector()
			App.show_challenge_screen(PvZ.CHALLENGE_PAGE_PUZZLE)
		GAMESELECTOR_SURVIVAL:
			App.kill_game_selector()
			App.show_challenge_screen(PvZ.CHALLENGE_PAGE_SURVIVAL)
		GAMESELECTOR_QUIT:
			App.confirm_quit()
		GAMESELECTOR_HELP:
			App.kill_game_selector()
			App.show_award_screen(PvZ.AWARD_HELP_ZOMBIENOTE, false)
		GAMESELECTOR_OPTIONS:
			App.do_new_options(true)
		GAMESELECTOR_CHANGE_USER:
			App.do_user_dialog()
		GAMESELECTOR_STORE:
			var store := App.show_store_screen()
			await store.wait_for_result(true)
			if store.go_to_tree_now:
				App.kill_game_selector()
				App.pre_new_game(PvZ.GAMEMODE_TREE_OF_WISDOM, false)
			else:
				App.music.make_sure_music_is_playing(PvZ.MUSIC_TUNE_TITLE_CRAZY_DAVE_MAIN_THEME)
		GAMESELECTOR_ALMANAC:
			var almanac := App.do_almanac_dialog()
			await almanac.wait_for_result(true)
			App.music.make_sure_music_is_playing(PvZ.MUSIC_TUNE_TITLE_CRAZY_DAVE_MAIN_THEME)
		GAMESELECTOR_ACHIEVEMENT:
			movement_timer = 75
			destination_y = -PvZ.BOARD_HEIGHT
			selector_state = SELECTOR_SUB_MENU
			App.show_achievement_screen()
			_set_buttons_disabled(true)
		GAMESELECTOR_QUICK_PLAY:
			movement_timer = 75
			destination_x = -PvZ.BOARD_WIDTH
			selector_state = SELECTOR_SUB_MENU
			App.show_quick_play_screen()
			_set_buttons_disabled(true)
		GAMESELECTOR_ZEN_GARDEN:
			App.kill_game_selector()
			App.pre_new_game(PvZ.GAMEMODE_CHALLENGE_ZEN_GARDEN, false)
			if should_do_zen_tuturial_before_adventure():
				App.zen_garden.setup_for_zen_tutorial()
		GAMESELECTOR_CREDITS:
			App.kill_game_selector()
			App.show_mini_credit_screen()

func calc_y_pos(_og_y: int, new_y: int) -> int:
	destination_y = new_y
	return Tod.animate_curve(75, 0, movement_timer, current_y, destination_y, Tod.CURVE_EASE_IN_OUT)

func calc_x_pos(_og_x: int, new_x: int) -> int:
	destination_x = new_x
	return Tod.animate_curve(75, 0, movement_timer, current_x, destination_x, Tod.CURVE_EASE_IN_OUT)
