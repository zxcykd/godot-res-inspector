@tool
extends EditorPlugin

const MENU_NAME := "资源体检"

const IMAGE_EXTS := ["png", "jpg", "jpeg", "webp", "svg", "bmp", "tga"]
const AUDIO_EXTS := ["wav", "ogg", "mp3"]
const FONT_EXTS := ["ttf", "otf", "woff", "woff2"]

# 会被扫描引用的文本文件；.import / .uid 必须排除，否则源文件会被误判为“已使用”
const TEXT_SCAN_EXTS := ["gd", "tscn", "tres", "gdshader", "shader", "json", "csv", "tsv", "cfg", "txt", "md", "godot"]

const MAX_TEXTURE_SIZE := 2048
const MAX_TEXTURE_MB := 2.0
const MAX_AUDIO_MB := 1.0
const MAX_LIST_ITEMS := 30

var _dialog: AcceptDialog
var _report: RichTextLabel
var _ref_regex: RegEx


func _enter_tree() -> void:
	_ref_regex = RegEx.new()
	_ref_regex.compile("(?:res|uid)://[^\"'\\s\\)\\]\\},;]+")

	add_tool_menu_item(MENU_NAME, _run_scan)
	_build_dialog()


func _exit_tree() -> void:
	remove_tool_menu_item(MENU_NAME)
	if is_instance_valid(_dialog):
		_dialog.queue_free()


func _build_dialog() -> void:
	_dialog = AcceptDialog.new()
	_dialog.title = "资源体检报告"
	_dialog.ok_button_text = "关闭"
	_dialog.min_size = Vector2i(820, 600)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(780, 540)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

	_report = RichTextLabel.new()
	_report.bbcode_enabled = true
	_report.fit_content = true
	_report.selection_enabled = true
	_report.custom_minimum_size = Vector2(760, 0)
	scroll.add_child(_report)

	_dialog.add_child(scroll)
	EditorInterface.get_base_control().add_child(_dialog)


func _run_scan() -> void:
	var files := _collect_files("res://")
	var used := _collect_references(files)

	var image_count := 0
	var image_bytes := 0
	var audio_count := 0
	var audio_bytes := 0
	var big_images: Array[String] = []
	var big_audios: Array[String] = []
	var unused: Array[String] = []
	var unused_bytes := 0
	var largest: Array = []

	for path in files:
		var ext := path.get_extension().to_lower()
		var size := _file_size(path)
		largest.append({"path": path, "size": size})

		var is_asset := ext in IMAGE_EXTS or ext in AUDIO_EXTS or ext in FONT_EXTS

		if ext in IMAGE_EXTS:
			image_count += 1
			image_bytes += size
			var dim := _image_size(path)
			var too_big := dim.x > MAX_TEXTURE_SIZE or dim.y > MAX_TEXTURE_SIZE
			var too_heavy := size > MAX_TEXTURE_MB * 1024.0 * 1024.0
			if too_big or too_heavy:
				var tag := ""
				if too_big:
					tag += " 尺寸超标"
				if too_heavy:
					tag += " 体积超标"
				big_images.append("%s  [color=#999999]%s  %s%s[/color]" % [path, _fmt_size(size), _dim_text(dim), tag])
		elif ext in AUDIO_EXTS:
			audio_count += 1
			audio_bytes += size
			if size > MAX_AUDIO_MB * 1024.0 * 1024.0:
				big_audios.append("%s  [color=#999999]%s[/color]" % [path, _fmt_size(size)])

		if is_asset and not path.begins_with("res://addons/") and not used.has(path):
			unused.append("%s  [color=#999999]%s[/color]" % [path, _fmt_size(size)])
			unused_bytes += size

	largest.sort_custom(func(a, b): return a["size"] > b["size"])

	var total := image_bytes + audio_bytes
	var issues := big_images.size() + big_audios.size()

	var lines: Array[String] = []
	lines.append("[font_size=22][b]资源体检报告[/b][/font_size]\n")
	lines.append("扫描文件     [b]%d[/b] 个" % files.size())
	lines.append("贴图         [b]%d[/b] 个  /  %s" % [image_count, _fmt_size(image_bytes)])
	lines.append("音频         [b]%d[/b] 个  /  %s" % [audio_count, _fmt_size(audio_bytes)])
	lines.append("资源总计     [b]%s[/b]" % _fmt_size(total))
	lines.append("未被引用     [b]%d[/b] 个  /  可回收 %s\n" % [unused.size(), _fmt_size(unused_bytes)])

	if issues == 0:
		lines.append("[color=#2e9e4f][b]没有超规格资源。[/b][/color]\n")
	else:
		lines.append("[b]发现 %d 个超规格资源[/b]\n" % issues)

	if big_images.size() > 0:
		lines.append("[b]超规格贴图（建议尺寸 ≤ %d，体积 ≤ %.0f MB）[/b]" % [MAX_TEXTURE_SIZE, MAX_TEXTURE_MB])
		for item in big_images:
			lines.append("  • " + item)
		lines.append("")

	if big_audios.size() > 0:
		lines.append("[b]超规格音频（建议体积 ≤ %.0f MB）[/b]" % MAX_AUDIO_MB)
		for item in big_audios:
			lines.append("  • " + item)
		lines.append("")

	if unused.size() > 0:
		lines.append("[b]未被引用的资源（共 %d 个，可回收 %s）[/b]" % [unused.size(), _fmt_size(unused_bytes)])
		for i in range(mini(MAX_LIST_ITEMS, unused.size())):
			lines.append("  • " + unused[i])
		if unused.size() > MAX_LIST_ITEMS:
			lines.append("  [color=#999999]……另有 %d 个未列出[/color]" % (unused.size() - MAX_LIST_ITEMS))
		lines.append("")

	if largest.size() > 0:
		lines.append("[b]体积最大的 10 个文件[/b]")
		for i in range(mini(10, largest.size())):
			var item = largest[i]
			lines.append("  %2d. %s  [color=#999999]%s[/color]" % [i + 1, item["path"], _fmt_size(item["size"])])
		lines.append("")

	lines.append("[color=#999999][font_size=12]“未被引用”基于项目内文本引用扫描得出，已跳过 addons 目录。"
		+ "\n若资源路径是由代码拼接生成，可能被误报，删除前请先提交一次版本控制。[/font_size][/color]")

	_report.text = "\n".join(lines)
	_dialog.popup_centered(Vector2i(820, 600))


func _collect_files(root: String) -> Array[String]:
	var out: Array[String] = []
	_scan_dir(root, out)
	return out


func _scan_dir(root: String, out: Array[String]) -> void:
	var dir := DirAccess.open(root)
	if dir == null:
		return
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if name.begins_with("."):
			name = dir.get_next()
			continue
		var path := root.path_join(name)
		if dir.current_is_dir():
			_scan_dir(path, out)
		elif not name.ends_with(".import") and not name.ends_with(".uid"):
			out.append(path)
		name = dir.get_next()
	dir.list_dir_end()


func _collect_references(files: Array[String]) -> Dictionary:
	var used := {}
	for path in files:
		var ext := path.get_extension().to_lower()
		if not (ext in TEXT_SCAN_EXTS):
			continue
		var f := FileAccess.open(path, FileAccess.READ)
		if f == null:
			continue
		var text := f.get_as_text()
		f.close()
		for m in _ref_regex.search_all(text):
			var ref := _normalize_ref(m.get_string())
			if ref != "":
				used[ref] = true
	return used


func _normalize_ref(ref: String) -> String:
	ref = ref.strip_edges().rstrip(".")
	if ref.begins_with("uid://"):
		var id := ResourceUID.text_to_id(ref)
		if id != ResourceUID.INVALID_ID and ResourceUID.has_id(id):
			return ResourceUID.get_id_path(id)
		return ""
	return ref


func _file_size(path: String) -> int:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return 0
	var n := f.get_length()
	f.close()
	return n


# 用 ResourceLoader 读取导入后的资源，避免 Image.load("res://...") 触发的
# “this will not work on export” 警告刷满输出面板。
func _image_size(path: String) -> Vector2i:
	var res: Resource = ResourceLoader.load(path)
	if res is Texture2D:
		return Vector2i(res.get_width(), res.get_height())
	if res is Image:
		return res.get_size()
	return Vector2i.ZERO


func _dim_text(dim: Vector2i) -> String:
	if dim == Vector2i.ZERO:
		return "尺寸未知"
	return "%d×%d" % [dim.x, dim.y]


func _fmt_size(bytes: int) -> String:
	if bytes >= 1024 * 1024:
		return "%.2f MB" % (bytes / 1048576.0)
	if bytes >= 1024:
		return "%.1f KB" % (bytes / 1024.0)
	return "%d B" % bytes
