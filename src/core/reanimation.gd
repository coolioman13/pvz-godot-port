class_name Reanimation
extends RefCounted
## Port of the PopCap Reanimator runtime.

enum { REANIM_LOOP, REANIM_LOOP_FULL_LAST_FRAME, REANIM_PLAY_ONCE, REANIM_PLAY_ONCE_AND_HOLD,
	REANIM_PLAY_ONCE_FULL_LAST_FRAME, REANIM_PLAY_ONCE_FULL_LAST_FRAME_AND_HOLD }
const RENDER_GROUP_HIDDEN := -1
const RENDER_GROUP_NORMAL := 0
const NO_BASE_POSE := -2

class Transform:
	var tx := 0.0
	var ty := 0.0
	var kx := 0.0
	var ky := 0.0
	var sx := 1.0
	var sy := 1.0
	var frame := 0.0
	var alpha := 1.0
	var image: PvzImage
	var font: ImageFont
	var text := ""

	func copy_from(o: Transform) -> void:
		tx = o.tx; ty = o.ty; kx = o.kx; ky = o.ky; sx = o.sx; sy = o.sy
		frame = o.frame; alpha = o.alpha; image = o.image; font = o.font; text = o.text

class TrackInstance:
	var blend_counter := 0
	var blend_time := 0
	var blend_transform := Transform.new()
	var shake_override := 0.0
	var shake_x := 0.0
	var shake_y := 0.0
	var attachment: Attachment = null
	var image_override: PvzImage = null
	var render_group := 0
	var track_color := Color.WHITE
	var ignore_clip_rect := false
	var truncate_disappearing_frames := true
	var ignore_color_override := false
	var ignore_extra_additive_color := false
	var render_in_back := false

var reanim_type := -1
var anim_time := 0.0
var anim_rate := 12.0
var definition: Defs.ReanimDef
var loop_type := REANIM_PLAY_ONCE
var dead := false
var freed := false
var frame_start := 0
var frame_count := 0
var frame_base_pose := -1
var overlay_matrix := Transform2D.IDENTITY
var color_override := Color.WHITE
var track_instances: Array = []
var loop_count := 0
var is_attachment := false
var render_order := 0
var extra_additive_color := Color.WHITE
var enable_extra_additive_draw := false
var extra_overlay_color := Color.WHITE
var enable_extra_overlay_draw := false
var last_frame_time := -1.0
var filter_effect := -1  # PvZ.FILTER_EFFECT_* (NONE = -1)

# frame time scratch
var _ft_fraction := 0.0
var _ft_before := 0
var _ft_after := 0

static var _tmp := Transform.new()

func initialize(x: float, y: float, def: Defs.ReanimDef) -> void:
	dead = false
	set_position(x, y)
	definition = def
	anim_rate = def.fps
	last_frame_time = -1.0
	if def.tracks.size() != 0:
		frame_count = (def.tracks[0] as Defs.ReanimTrackDef).frame_count
		track_instances.resize(def.tracks.size())
		for i in def.tracks.size():
			track_instances[i] = TrackInstance.new()
	else:
		frame_count = 0

func update() -> void:
	if frame_count == 0 or dead:
		return
	last_frame_time = anim_time
	anim_time += Tod.SECONDS_PER_UPDATE * anim_rate / frame_count
	if anim_rate > 0:
		match loop_type:
			REANIM_LOOP, REANIM_LOOP_FULL_LAST_FRAME:
				while anim_time >= 1.0:
					loop_count += 1
					anim_time -= 1.0
			REANIM_PLAY_ONCE, REANIM_PLAY_ONCE_FULL_LAST_FRAME:
				if anim_time >= 1.0:
					loop_count = 1
					anim_time = 1.0
					dead = true
			REANIM_PLAY_ONCE_AND_HOLD, REANIM_PLAY_ONCE_FULL_LAST_FRAME_AND_HOLD:
				if anim_time >= 1.0:
					loop_count = 1
					anim_time = 1.0
	else:
		match loop_type:
			REANIM_LOOP, REANIM_LOOP_FULL_LAST_FRAME:
				while anim_time < 0.0:
					loop_count += 1
					anim_time += 1.0
			REANIM_PLAY_ONCE, REANIM_PLAY_ONCE_FULL_LAST_FRAME:
				if anim_time < 0.0:
					loop_count = 1
					anim_time = 0.0
					dead = true
			REANIM_PLAY_ONCE_AND_HOLD, REANIM_PLAY_ONCE_FULL_LAST_FRAME_AND_HOLD:
				if anim_time < 0.0:
					loop_count = 1
					anim_time = 0.0
	var tracks := definition.tracks
	for i in tracks.size():
		var ti: TrackInstance = track_instances[i]
		if ti.blend_counter > 0:
			ti.blend_counter -= 1
		if ti.shake_override != 0.0:
			ti.shake_x = Tod.rand_range_float(-ti.shake_override, ti.shake_override)
			ti.shake_y = Tod.rand_range_float(-ti.shake_override, ti.shake_override)
		if (tracks[i] as Defs.ReanimTrackDef).is_attacher:
			update_attacher_track(i)
		if ti.attachment != null:
			var m := get_attachment_overlay_matrix(i)
			Attachment.update_and_set_matrix(ti, m)

# ---------------------------------------------------------------- transforms
func get_frame_time() -> void:
	var fc := frame_count
	if loop_type != REANIM_PLAY_ONCE_FULL_LAST_FRAME and loop_type != REANIM_LOOP_FULL_LAST_FRAME and loop_type != REANIM_PLAY_ONCE_FULL_LAST_FRAME_AND_HOLD:
		fc = frame_count - 1
	var pos := frame_start + anim_time * fc
	var before := floorf(pos)
	_ft_fraction = pos - before
	_ft_before = Tod.round_to_int(before)
	if _ft_before >= frame_start + frame_count - 1:
		_ft_before = frame_start + frame_count - 1
		_ft_after = _ft_before
	else:
		_ft_after = _ft_before + 1

func get_transform_at_time(track_index: int, out: Transform, fraction: float, before: int, after: int) -> void:
	var td: Defs.ReanimTrackDef = definition.tracks[track_index]
	out.tx = lerpf(td.x[before], td.x[after], fraction)
	out.ty = lerpf(td.y[before], td.y[after], fraction)
	out.kx = lerpf(td.kx[before], td.kx[after], fraction)
	out.ky = lerpf(td.ky[before], td.ky[after], fraction)
	out.sx = lerpf(td.sx[before], td.sx[after], fraction)
	out.sy = lerpf(td.sy[before], td.sy[after], fraction)
	out.alpha = lerpf(td.a[before], td.a[after], fraction)
	out.image = td.images[before]
	out.font = td.fonts[before]
	out.text = td.texts[before]
	if td.f[before] != -1.0 and td.f[after] == -1.0 and fraction > 0.0 and (track_instances[track_index] as TrackInstance).truncate_disappearing_frames:
		out.frame = -1.0
	else:
		out.frame = td.f[before]

static func blend_transform(result: Transform, t1: Transform, t2: Transform, factor: float) -> void:
	var tx := lerpf(t1.tx, t2.tx, factor)
	var ty := lerpf(t1.ty, t2.ty, factor)
	var sx := lerpf(t1.sx, t2.sx, factor)
	var sy := lerpf(t1.sy, t2.sy, factor)
	var al := lerpf(t1.alpha, t2.alpha, factor)
	var skx2 := t2.kx
	var sky2 := t2.ky
	# The original "while" loops assign rather than wrap; they terminate after one step.
	if skx2 > t1.kx + 180.0 or skx2 < t1.kx - 180.0:
		skx2 = t1.kx
	if sky2 > t1.ky + 180.0 or sky2 < t1.ky - 180.0:
		sky2 = t1.ky
	var kx := lerpf(t1.kx, skx2, factor)
	var ky := lerpf(t1.ky, sky2, factor)
	result.tx = tx; result.ty = ty; result.sx = sx; result.sy = sy; result.alpha = al
	result.kx = kx; result.ky = ky
	result.frame = t1.frame
	result.font = t1.font
	result.text = t1.text
	result.image = t1.image

func get_current_transform(track_index: int, out: Transform) -> void:
	get_frame_time()
	get_transform_at_time(track_index, out, _ft_fraction, _ft_before, _ft_after)
	var ti: TrackInstance = track_instances[track_index]
	if Tod.round_to_int(out.frame) >= 0 and ti.blend_counter > 0:
		var f := float(ti.blend_counter) / float(ti.blend_time)
		blend_transform(out, out, ti.blend_transform, f)

static func matrix_from_transform(t: Transform) -> Transform2D:
	var skx := -Tod.deg_to_rad_f(t.kx)
	var sky := -Tod.deg_to_rad_f(t.ky)
	return Transform2D(Vector2(cos(skx) * t.sx, -sin(skx) * t.sx), Vector2(sin(sky) * t.sy, cos(sky) * t.sy), Vector2(t.tx, t.ty))

# ---------------------------------------------------------------- drawing
func draw(g: Graphics) -> void:
	draw_render_group(g, RENDER_GROUP_NORMAL)

func draw_render_group(g: Graphics, group: int) -> void:
	if dead:
		return
	for i in definition.tracks.size():
		var ti: TrackInstance = track_instances[i]
		if ti.render_group == group:
			if ti.render_in_back and ti.attachment != null:
				ti.attachment.draw(g, false)
			var drawn := draw_track(g, i, group)
			if not ti.render_in_back and ti.attachment != null:
				ti.attachment.draw(g, not drawn)

func draw_track(g: Graphics, track_index: int, _group: int) -> bool:
	var t := _tmp
	var ti: TrackInstance = track_instances[track_index]
	get_current_transform(track_index, t)
	var image_frame := Tod.round_to_int(t.frame)
	if image_frame < 0:
		return false
	var col := ti.track_color
	if not ti.ignore_color_override:
		col = Tod.colors_multiply(col, color_override)
	if g.colorize_images:
		col = Tod.colors_multiply(col, g.color)
	var img_alpha := clampi(Tod.round_to_int(t.alpha * col.a8), 0, 255)
	if img_alpha <= 0:
		return false
	col.a8 = img_alpha
	var add_col := extra_additive_color
	if enable_extra_additive_draw:
		add_col.a8 = Tod.color_component_multiply(extra_additive_color.a8, img_alpha)
	var over_col := extra_overlay_color
	if enable_extra_overlay_draw:
		over_col.a8 = Tod.color_component_multiply(extra_overlay_color.a8, img_alpha)
	var clip_r := g.clip
	if ti.ignore_clip_rect:
		clip_r = Rect2(0, 0, PvZ.BOARD_WIDTH, PvZ.BOARD_HEIGHT)
	var image := t.image
	var local := Transform2D.IDENTITY
	var fullscreen := false
	if image != null:
		if ti.image_override != null:
			image = ti.image_override
		local.origin = Vector2(image.get_cel_width() * 0.5, image.get_cel_height() * 0.5)
	elif t.font != null and t.text != "":
		local.origin = Vector2(-t.font.string_width(t.text) * 0.5, t.font.get_ascent())
	else:
		if (definition.tracks[track_index] as Defs.ReanimTrackDef).name.to_lower() != "fullscreen":
			return false
		fullscreen = true
	var m := overlay_matrix * matrix_from_transform(t) * local
	m.origin += Vector2(ti.shake_x + g.trans_x, ti.shake_y + g.trans_y)
	if image != null:
		var frame := image_frame
		while frame >= image.num_cols:
			frame -= image.num_cols
		var cw := image.get_cel_width()
		var src := Rect2(frame * cw, 0, cw, image.get_cel_height())
		var old_filter := g.filter
		g.filter = filter_effect + 1
		g.blt_matrix(image, m, clip_r, col, g.draw_mode, src)
		if enable_extra_additive_draw:
			g.blt_matrix(image, m, clip_r, add_col, Graphics.DRAWMODE_ADDITIVE, src)
		if enable_extra_overlay_draw:
			g.filter = RenderTarget.FILTER_WHITE
			g.blt_matrix(image, m, clip_r, over_col, Graphics.DRAWMODE_NORMAL, src)
		g.filter = old_filter
	elif t.font != null and t.text != "":
		t.font.draw_string_matrix(g, m, t.text, col)
		if enable_extra_additive_draw:
			var old_mode := g.draw_mode
			g.draw_mode = Graphics.DRAWMODE_ADDITIVE
			t.font.draw_string_matrix(g, m, t.text, add_col)
			g.draw_mode = old_mode
	elif fullscreen:
		var old_color := g.color
		g.color = col
		g.fill_rect(-g.trans_x, -g.trans_y, PvZ.BOARD_WIDTH, PvZ.BOARD_HEIGHT)
		g.color = old_color
	return true

func get_current_track_image(track_name: String) -> PvzImage:
	var t := Transform.new()
	get_current_transform(find_track_index(track_name), t)
	return t.image

func get_track_matrix(track_index: int) -> Transform2D:
	var ti: TrackInstance = track_instances[track_index]
	var t := Transform.new()
	get_current_transform(track_index, t)
	var frame := Tod.round_to_int(t.frame)
	var local := Transform2D.IDENTITY
	if t.image != null and frame >= 0:
		local.origin = Vector2(t.image.get_cel_width() * 0.5, t.image.get_cel_height() * 0.5)
	elif t.font != null and t.text != "":
		local.origin = Vector2(0, t.font.get_ascent())
	var m := overlay_matrix * matrix_from_transform(t) * local
	m.origin += Vector2(ti.shake_x, ti.shake_y)
	return m

## Convenience used all over the game code: the track's current anchor position (m02, m12).
func get_track_position(track_name: String) -> Vector2:
	return get_track_matrix(find_track_index(track_name)).origin

func get_track_base_pose_matrix(track_index: int) -> Transform2D:
	if frame_base_pose == NO_BASE_POSE:
		return Transform2D.IDENTITY
	var base := frame_start if frame_base_pose == -1 else frame_base_pose
	var t := Transform.new()
	get_transform_at_time(track_index, t, 0.0, base, base + 1)
	return matrix_from_transform(t)

func attach_particle_to_track(track_name: String, ps: TodParticleSystem, px: float, py: float) -> Attachment.Effect:
	var idx := find_track_index(track_name)
	var ti: TrackInstance = track_instances[idx]
	var pos := get_track_base_pose_matrix(idx) * Vector2(px, py)
	return Attachment.attach_particle(ti, ps, pos.x, pos.y)

func get_attachment_overlay_matrix(track_index: int) -> Transform2D:
	var t := Transform.new()
	get_current_transform(track_index, t)
	var m := overlay_matrix * matrix_from_transform(t)
	var base := get_track_base_pose_matrix(track_index)
	return m * base.affine_inverse()

func get_frames_for_layer(track_name: String) -> Vector2i:
	if definition.tracks.size() == 0:
		return Vector2i(0, 0)
	var idx := find_track_index(track_name)
	var td: Defs.ReanimTrackDef = definition.tracks[idx]
	var start := 0
	var count := 1
	for i in td.frame_count:
		if td.f[i] >= 0.0:
			start = i
			break
	for j in range(start, td.frame_count):
		if td.f[j] >= 0.0:
			count = j - start + 1
	return Vector2i(start, count)

func set_frames_for_layer(track_name: String) -> void:
	anim_time = 0.0 if anim_rate >= 0 else 0.9999999
	last_frame_time = -1.0
	var fc := get_frames_for_layer(track_name)
	frame_start = fc.x
	frame_count = fc.y

func track_exists(track_name: String) -> bool:
	return definition.track_index.has(track_name.to_lower())

func find_track_index(track_name: String) -> int:
	var i: int = definition.track_index.get(track_name.to_lower(), -1)
	return 0 if i < 0 else i

func get_track_instance(track_name: String) -> TrackInstance:
	return track_instances[find_track_index(track_name)]

func start_blend(blend_time: int) -> void:
	for i in definition.tracks.size():
		var t := Transform.new()
		get_current_transform(i, t)
		if Tod.round_to_int(t.frame) >= 0:
			var ti: TrackInstance = track_instances[i]
			ti.blend_transform = t
			ti.blend_time = blend_time
			ti.blend_counter = blend_time
			t.font = null
			t.text = ""
			t.image = null

func die() -> void:
	if not dead:
		dead = true
		for ti in track_instances:
			Attachment.die_on(ti)

func set_shake_override(track_name: String, amount: float) -> void:
	get_track_instance(track_name).shake_override = amount

func set_position(x: float, y: float) -> void:
	overlay_matrix.origin = Vector2(x, y)

func override_scale(sx: float, sy: float) -> void:
	overlay_matrix.x = Vector2(sx, overlay_matrix.x.y)
	overlay_matrix.y = Vector2(overlay_matrix.y.x, sy)

func get_image_override(track_name: String) -> PvzImage:
	return get_track_instance(track_name).image_override

func set_image_override(track_name: String, img: PvzImage) -> void:
	get_track_instance(track_name).image_override = img

func set_truncate_disappearing_frames(track_name: String = "", on: bool = false) -> void:
	if track_name == "":
		for ti in track_instances:
			ti.truncate_disappearing_frames = on
	else:
		get_track_instance(track_name).truncate_disappearing_frames = on

func get_track_velocity(track_name: String) -> float:
	get_frame_time()
	var td: Defs.ReanimTrackDef = definition.tracks[find_track_index(track_name)]
	var dis := td.x[_ft_after] - td.x[_ft_before]
	return dis * Tod.SECONDS_PER_UPDATE * anim_rate

func is_track_showing(track_name: String) -> bool:
	get_frame_time()
	var td: Defs.ReanimTrackDef = definition.tracks[find_track_index(track_name)]
	return td.f[_ft_after] >= 0.0

func show_only_track(track_name: String) -> void:
	var lower := track_name.to_lower()
	for i in definition.tracks.size():
		(track_instances[i] as TrackInstance).render_group = RENDER_GROUP_NORMAL if (definition.tracks[i] as Defs.ReanimTrackDef).name.to_lower() == lower else RENDER_GROUP_HIDDEN

func assign_render_group_to_track(track_name: String, group: int) -> void:
	var lower := track_name.to_lower()
	for i in definition.tracks.size():
		if (definition.tracks[i] as Defs.ReanimTrackDef).name.to_lower() == lower:
			(track_instances[i] as TrackInstance).render_group = group
			return

func assign_render_group_to_prefix(prefix: String, group: int) -> void:
	var lower := prefix.to_lower()
	for i in definition.tracks.size():
		if (definition.tracks[i] as Defs.ReanimTrackDef).name.to_lower().begins_with(lower):
			(track_instances[i] as TrackInstance).render_group = group

func propogate_color_to_attachments() -> void:
	for ti in track_instances:
		Attachment.propogate_color_on(ti, color_override, enable_extra_additive_draw, extra_additive_color, enable_extra_overlay_draw, extra_overlay_color)

func should_trigger_timed_event(event_time: float) -> bool:
	if frame_count == 0 or last_frame_time <= 0.0 or anim_rate <= 0.0:
		return false
	if anim_time >= last_frame_time:
		return event_time >= last_frame_time and event_time < anim_time
	return event_time >= last_frame_time or event_time < anim_time

func play_reanim(track_name: String, loop: int, blend_time: int, rate: float) -> void:
	if blend_time > 0:
		start_blend(blend_time)
	if rate != 0.0:
		anim_rate = rate
	loop_type = loop
	loop_count = 0
	set_frames_for_layer(track_name)

func is_anim_playing(track_name: String) -> bool:
	var fc := get_frames_for_layer(track_name)
	return frame_start == fc.x and frame_count == fc.y

func set_base_pose_from_anim(track_name: String) -> void:
	frame_base_pose = get_frames_for_layer(track_name).x

func attach_to_another_reanimation(attach_reanim: Reanimation, track_name: String) -> void:
	if attach_reanim.definition.tracks.size() <= 0:
		return
	if attach_reanim.frame_base_pose == -1:
		attach_reanim.frame_base_pose = attach_reanim.frame_start
	Attachment.attach_reanim(attach_reanim.get_track_instance(track_name), self, 0.0, 0.0)

func find_sub_reanim(type: int) -> Reanimation:
	if reanim_type == type:
		return self
	for ti in track_instances:
		var r := Attachment.find_reanim_attachment(ti)
		if r != null:
			var s := r.find_sub_reanim(type)
			if s != null:
				return s
	return null

# ---------------------------------------------------------------- attacher tracks
func update_attacher_track(track_index: int) -> void:
	var ti: TrackInstance = track_instances[track_index]
	var t := Transform.new()
	get_current_transform(track_index, t)
	var info := _parse_attacher_track(t)
	var type := -1
	if info.reanim_name != "":
		type = ReanimTypes.type_from_file("reanim/%s.reanim" % info.reanim_name)
	if type == -1:
		Attachment.die_on(ti)
		return
	var ar := Attachment.find_reanim_attachment(ti)
	if ar == null or ar.reanim_type != type:
		Attachment.die_on(ti)
		ar = EffectSystem.alloc_reanimation(0.0, 0.0, 0, type)
		ar.loop_type = info.loop_type
		ar.anim_rate = info.anim_rate
		Attachment.attach_reanim(ti, ar, 0.0, 0.0)
		frame_base_pose = NO_BASE_POSE
	if info.track_name != "":
		var fc := ar.get_frames_for_layer(info.track_name)
		if ar.frame_start != fc.x or ar.frame_count != fc.y:
			ar.start_blend(20)
			ar.set_frames_for_layer(info.track_name)
		if ar.anim_rate == 12.0 and info.track_name == "anim_walk" and ar.track_exists("_ground"):
			_attacher_synch_walk_speed(track_index, ar)
		else:
			ar.anim_rate = info.anim_rate
		ar.loop_type = info.loop_type
	var c := Tod.colors_multiply(color_override, ti.track_color)
	c.a8 = clampi(Tod.round_to_int(t.alpha * c.a8), 0, 255)
	Attachment.propogate_color_on(ti, c, enable_extra_additive_draw, extra_additive_color, enable_extra_overlay_draw, extra_overlay_color)

static func _parse_attacher_track(t: Transform) -> Dictionary:
	var info := {"reanim_name": "", "track_name": "", "anim_rate": 12.0, "loop_type": REANIM_LOOP}
	if t.frame == -1.0:
		return info
	var s := t.text
	var rn := s.find("__")
	if rn == -1:
		return info
	var tags := s.find("[", rn + 2)
	var tn := s.find("__", rn + 2)
	if tags != -1 and tn != -1 and tags < tn:
		return info
	if tn != -1:
		info.reanim_name = s.substr(rn + 2, tn - rn - 2)
		if tags != -1:
			info.track_name = s.substr(tn + 2, tags - tn - 2)
		else:
			info.track_name = s.substr(tn + 2)
	elif tags != -1:
		info.reanim_name = s.substr(rn + 2, tags - rn - 2)
	else:
		info.reanim_name = s.substr(rn + 2)
	while tags != -1:
		var te := s.find("]", tags + 1)
		if te == -1:
			break
		var code := s.substr(tags + 1, te - tags - 1)
		if code.is_valid_float():
			info.anim_rate = code.to_float()
		elif code == "hold":
			info.loop_type = REANIM_PLAY_ONCE_AND_HOLD
		elif code == "once":
			info.loop_type = REANIM_PLAY_ONCE
		tags = s.find("[", te + 1)
	return info

func _attacher_synch_walk_speed(track_index: int, ar: Reanimation) -> void:
	var td: Defs.ReanimTrackDef = definition.tracks[track_index]
	get_frame_time()
	var ph_start := _ft_before
	while ph_start > frame_start and td.texts[ph_start - 1] == td.texts[ph_start]:
		ph_start -= 1
	var ph_end := _ft_before
	while ph_end < frame_start + frame_count - 1 and td.texts[ph_end + 1] == td.texts[ph_end]:
		ph_end += 1
	var ph_count := ph_end - ph_start
	if Tod.approx_equal(anim_rate, 0.0):
		ar.anim_rate = 0.0
		return
	var ph_distance := -(td.x[ph_end] - td.x[ph_start])
	var ph_seconds := ph_count / anim_rate
	if Tod.approx_equal(ph_seconds, 0.0):
		ar.anim_rate = 0.0
		return
	var gi := ar.find_track_index("_ground")
	var gt: Defs.ReanimTrackDef = ar.definition.tracks[gi]
	var guy_start := gt.x[ar.frame_start]
	var guy_end := gt.x[ar.frame_start + ar.frame_count - 1]
	var guy_distance := guy_end - guy_start
	if guy_distance < Tod.FLT_EPSILON or ph_distance < Tod.FLT_EPSILON:
		ar.anim_rate = 0.0
		return
	var loops := ph_distance / guy_distance
	var cur := Transform.new()
	ar.get_current_transform(gi, cur)
	var eff := Attachment.find_first_attachment((track_instances[track_index] as TrackInstance))
	if eff != null:
		var cur_dist := cur.tx - guy_start
		var expected := guy_distance * ar.anim_time
		eff.offset.origin.x = expected - cur_dist
	ar.anim_rate = loops * ar.frame_count / ph_seconds
