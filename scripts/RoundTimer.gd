extends TextureProgressBar

# Emitted when the timer ends. timed_out is true if it ran out, false if stopped early.
signal finished(timed_out: bool)

@onready var internal_timer: Timer = $Timer if has_node("Timer") else null

func _ready():
	visible = false
	if not internal_timer:
		internal_timer = Timer.new()
		internal_timer.name = "Timer"
		internal_timer.one_shot = true
		internal_timer.timeout.connect(_on_timer_timeout)
		add_child(internal_timer)
	elif not internal_timer.timeout.is_connected(_on_timer_timeout):
		internal_timer.timeout.connect(_on_timer_timeout)

func start_timer(duration: float) -> void:
	print("Started timer")
	min_value = 0.0
	max_value = duration
	value = duration
	visible = true
	internal_timer.start(duration)

func stop_timer() -> void:
	if internal_timer and not internal_timer.is_stopped():
		internal_timer.stop()
		visible = false
		finished.emit(false) # Stopped early via button press

func _process(_delta: float) -> void:
	if internal_timer and not internal_timer.is_stopped():
		value = internal_timer.time_left

func _on_timer_timeout() -> void:
	visible = false
	finished.emit(true) # Completed normally
