extends Node2D

const W := 480.0
const H := 854.0
const CARS := ["SILVIA S15", "SKYLINE R34", "SUPRA MK4", "AE86"]
const CAR_COLORS := [Color("#e84b55"), Color("#3d86d9"), Color("#e8b83d"), Color("#eeeeea")]
const MODES := ["FREE DRIFT", "COMPETITION", "CAREER"]

var screen := "menu"
var selected_car := 0
var selected_mode := 0
var speed := 0.0
var steering := 0.0
var drift_angle := 0.0
var road_phase := 0.0
var score := 0
var best_score := 0
var money := 12000
var drift_timer := 0.0
var handbrake := false
var throttle := false
var brake := false
var left_pressed := false
var right_pressed := false
var upgrades := {"engine": 0, "tires": 0, "suspension": 0}
var touch_ids := {}

func _ready() -> void:
    get_viewport().size_changed.connect(queue_redraw)
    set_process(true)

func _process(delta: float) -> void:
    if screen == "game":
        var target := 0.0
        if left_pressed: target -= 1.0
        if right_pressed: target += 1.0
        steering = lerp(steering, target, minf(delta * 5.0, 1.0))
        var accel := 0.0
        if throttle: accel = 1.0
        if brake: accel = -0.7
        speed = clampf(speed + accel * delta * 42.0 - delta * (4.0 + speed * 0.035), 0.0, 190.0)
        if handbrake and speed > 25.0:
            drift_angle = lerpf(drift_angle, steering * 1.0, delta * 3.5)
        else:
            drift_angle = lerpf(drift_angle, steering * minf(speed / 75.0, 0.75), delta * 2.2)
        road_phase = fposmod(road_phase + speed * delta * 0.018, 1.0)
        if absf(drift_angle) > 0.22 and speed > 35.0:
            drift_timer += delta
            score += int((absf(drift_angle) * speed * delta) * 2.0)
        else:
            drift_timer = 0.0
        best_score = maxi(best_score, score)
    queue_redraw()

func _draw() -> void:
    draw_rect(Rect2(0, 0, W, H), Color("#111827"))
    if screen == "menu":
        _draw_menu()
    elif screen == "garage":
        _draw_garage()
    elif screen == "game":
        _draw_game()
    elif screen == "results":
        _draw_results()

func _draw_menu() -> void:
    _draw_background()
    _center_text("PIXEL DRIFT", 150, 46, Color("#f4f4f4"))
    _center_text("TOUGE / STREET / STYLE", 190, 15, Color("#8dd7e8"))
    _draw_car_icon(Vector2(240, 365), 1.0, CAR_COLORS[selected_car])
    _center_text(CARS[selected_car], 485, 25, Color("#ffffff"))
    _button(Rect2(65, 555, 350, 62), "DRIVE", Color("#e84b55"))
    _button(Rect2(65, 635, 350, 58), "GARAGE  /  CARS", Color("#31506a"))
    _center_text("PIXEL DRIFT  •  PROTOTYPE 0.1", 790, 13, Color("#7f8c9b"))

func _draw_garage() -> void:
    _draw_background()
    _center_text("GARAGE", 100, 36, Color.WHITE)
    _draw_car_icon(Vector2(240, 330), 1.15, CAR_COLORS[selected_car])
    _center_text(CARS[selected_car], 455, 25, Color("#ffffff"))
    _center_text("‹     SELECT CAR     ›", 505, 17, Color("#8dd7e8"))
    _button(Rect2(30, 540, 125, 55), "PREV", Color("#31506a"))
    _button(Rect2(325, 540, 125, 55), "NEXT", Color("#31506a"))
    _center_text("UPGRADES  •  CASH $" + str(money), 635, 18, Color("#f0d078"))
    _center_text("ENGINE " + str(upgrades.engine) + "   TIRES " + str(upgrades.tires) + "   SUSP " + str(upgrades.suspension), 670, 14, Color.WHITE)
    _button(Rect2(40, 710, 185, 55), "UPGRADE $3000", Color("#4b7656"))
    _button(Rect2(255, 710, 185, 55), "BACK", Color("#31506a"))

func _draw_game() -> void:
    # Night-time pixel-art road and cockpit perspective
    draw_rect(Rect2(0, 0, W, 430), Color("#18283d"))
    draw_rect(Rect2(0, 430, W, 424), Color("#263d32"))
    for i in range(9):
        var x := float(i) * 64.0 - 25.0
        draw_rect(Rect2(x, 245, 18, 90), Color("#253d4d"))
        draw_rect(Rect2(x + 7, 260, 5, 12), Color("#f4d78a"))
    var shift := drift_angle * 90.0
    var horizon := 320.0
    var bottom_left := 20.0 + shift
    var bottom_right := 460.0 + shift
    var top_left := 205.0 + shift * 0.18
    var top_right := 275.0 + shift * 0.18
    var road := PackedVector2Array([Vector2(top_left,horizon), Vector2(top_right,horizon), Vector2(bottom_right,690), Vector2(bottom_left,690)])
    draw_colored_polygon(road, Color("#343943"))
    for i in range(13):
        var t := fposmod(float(i) / 13.0 + road_phase, 1.0)
        var y := lerpf(horizon + 15.0, 690.0, t * t)
        var half := lerpf(10.0, 210.0, t)
        var cx := 240.0 + shift * t
        var dash_h := lerpf(3.0, 18.0, t)
        draw_rect(Rect2(cx - 4.0, y, 8.0, dash_h), Color("#e9e6d7"))
        draw_rect(Rect2(cx - half - 5.0, y, 5.0, dash_h), Color("#c94e52"))
        draw_rect(Rect2(cx + half, y, 5.0, dash_h), Color("#c94e52"))
    # Dashboard / cockpit frame
    draw_colored_polygon(PackedVector2Array([Vector2(0,0),Vector2(34,0),Vector2(65,440),Vector2(0,520)]), Color("#10151c"))
    draw_colored_polygon(PackedVector2Array([Vector2(446,0),Vector2(480,0),Vector2(480,520),Vector2(415,440)]), Color("#10151c"))
    draw_rect(Rect2(0, 680, W, 174), Color("#111820"))
    draw_rect(Rect2(0, 680, W, 12), Color("#46515a"))
    # Steering wheel
    draw_arc(Vector2(240, 760), 75, 0, TAU, 48, Color("#080b0e"), 18)
    draw_line(Vector2(240, 760), Vector2(240 + steering * 36, 810), Color("#89939b"), 9)
    draw_line(Vector2(240, 760), Vector2(185, 785), Color("#89939b"), 8)
    draw_line(Vector2(240, 760), Vector2(295, 785), Color("#89939b"), 8)
    _text("KM/H  " + str(int(speed)), Vector2(24, 45), 20, Color("#9df0c0"))
    _text("SCORE  " + str(score), Vector2(24, 78), 18, Color("#f4d078"))
    if absf(drift_angle) > 0.22 and speed > 35:
        _center_text("DRIFT!", 145, 25, Color("#f4d078"))
    # Touch controls
    _button(Rect2(20, 555, 90, 75), "◀", Color("#38566b"))
    _button(Rect2(120, 555, 90, 75), "▶", Color("#38566b"))
    _button(Rect2(350, 555, 110, 75), "GAS", Color("#477b54"))
    _button(Rect2(350, 640, 110, 65), "BRAKE", Color("#8c4a4a"))
    _button(Rect2(20, 640, 120, 65), "HANDBRAKE", Color("#8b6b39"))
    _button(Rect2(175, 20, 130, 42), "PAUSE / EXIT", Color("#4a4f5a"))

func _draw_results() -> void:
    _draw_background()
    _center_text("SESSION COMPLETE", 220, 32, Color.WHITE)
    _center_text("DRIFT SCORE  " + str(score), 330, 25, Color("#f4d078"))
    _center_text("BEST  " + str(best_score), 380, 19, Color("#8dd7e8"))
    _button(Rect2(65, 500, 350, 62), "TRY AGAIN", Color("#e84b55"))
    _button(Rect2(65, 580, 350, 58), "MAIN MENU", Color("#31506a"))

func _draw_background() -> void:
    draw_rect(Rect2(0,0,W,H), Color("#172538"))
    for i in range(16):
        var x := float((i * 73) % 480)
        var y := float(80 + (i * 97) % 660)
        draw_rect(Rect2(x,y,3,3), Color("#8dd7e8"))

func _draw_car_icon(center: Vector2, scale: float, color: Color) -> void:
    draw_rect(Rect2(center.x - 85*scale, center.y - 30*scale, 170*scale, 60*scale), color)
    draw_colored_polygon(PackedVector2Array([
        center + Vector2(-55,-30)*scale, center + Vector2(-30,-62)*scale,
        center + Vector2(35,-62)*scale, center + Vector2(62,-30)*scale
    ]), color.lightened(0.15))
    draw_rect(Rect2(center.x - 45*scale, center.y - 55*scale, 85*scale, 24*scale), Color("#8bc5d8"))
    draw_rect(Rect2(center.x - 70*scale, center.y + 20*scale, 38*scale, 20*scale), Color("#080b0e"))
    draw_rect(Rect2(center.x + 32*scale, center.y + 20*scale, 38*scale, 20*scale), Color("#080b0e"))
    draw_rect(Rect2(center.x - 84*scale, center.y - 12*scale, 15*scale, 13*scale), Color("#fff1b0"))
    draw_rect(Rect2(center.x + 69*scale, center.y - 12*scale, 15*scale, 13*scale), Color("#fff1b0"))

func _button(rect: Rect2, label: String, color: Color) -> void:
    draw_rect(rect, color)
    draw_rect(rect, color.lightened(0.25), false, 3)
    var font := ThemeDB.fallback_font
    var fs := 18
    draw_string(font, rect.position + Vector2(12, rect.size.y * 0.62), label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 24, fs, Color.WHITE)

func _center_text(value: String, y: float, size: int, color: Color) -> void:
    draw_string(ThemeDB.fallback_font, Vector2(0, y), value, HORIZONTAL_ALIGNMENT_CENTER, W, size, color)

func _text(value: String, pos: Vector2, size: int, color: Color) -> void:
    draw_string(ThemeDB.fallback_font, pos, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _gui_button_at(p: Vector2) -> String:
    if screen == "menu":
        if Rect2(65,555,350,62).has_point(p): return "drive"
        if Rect2(65,635,350,58).has_point(p): return "garage"
    elif screen == "garage":
        if Rect2(30,540,125,55).has_point(p): return "prev"
        if Rect2(325,540,125,55).has_point(p): return "next"
        if Rect2(40,710,185,55).has_point(p): return "upgrade"
        if Rect2(255,710,185,55).has_point(p): return "back"
    elif screen == "game":
        if Rect2(175,20,130,42).has_point(p): return "exit"
        if Rect2(20,555,90,75).has_point(p): return "left"
        if Rect2(120,555,90,75).has_point(p): return "right"
        if Rect2(350,555,110,75).has_point(p): return "gas"
        if Rect2(350,640,110,65).has_point(p): return "brake"
        if Rect2(20,640,120,65).has_point(p): return "handbrake"
    elif screen == "results":
        if Rect2(65,500,350,62).has_point(p): return "again"
        if Rect2(65,580,350,58).has_point(p): return "home"
    return ""

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed:
            var action := _gui_button_at(event.position)
            touch_ids[event.index] = action
            _handle_press(action, true)
        else:
            var action: String = touch_ids.get(event.index, "")
            _handle_press(action, false)
            touch_ids.erase(event.index)
    elif event is InputEventMouseButton:
        if event.pressed:
            _handle_press(_gui_button_at(event.position), true)
        else:
            _handle_press(_gui_button_at(event.position), false)
    elif event is InputEventKey and event.pressed:
        if event.keycode == KEY_ESCAPE:
            if screen == "game": screen = "results"
            else: screen = "menu"
        if screen == "game":
            if event.keycode == KEY_LEFT: left_pressed = true
            if event.keycode == KEY_RIGHT: right_pressed = true
            if event.keycode == KEY_UP: throttle = true
            if event.keycode == KEY_DOWN: brake = true
            if event.keycode == KEY_SPACE: handbrake = true

func _handle_press(action: String, pressed: bool) -> void:
    if action == "left": left_pressed = pressed
    elif action == "right": right_pressed = pressed
    elif action == "gas": throttle = pressed
    elif action == "brake": brake = pressed
    elif action == "handbrake": handbrake = pressed
    elif not pressed:
        return
    elif action == "drive":
        screen = "game"
        score = 0
        speed = 0
        drift_angle = 0
    elif action == "garage":
        screen = "garage"
    elif action == "prev":
        selected_car = (selected_car + 3) % 4
    elif action == "next":
        selected_car = (selected_car + 1) % 4
    elif action == "upgrade":
        if money >= 3000:
            money -= 3000
            upgrades.engine += 1
    elif action == "back":
        screen = "menu"
    elif action == "exit":
        screen = "results"
    elif action == "again":
        screen = "game"
        score = 0
        speed = 0
    elif action == "home":
        screen = "menu"
