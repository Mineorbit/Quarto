extends TextureProgressBar


func _ready():
	visible = false

var target_timer: SceneTreeTimer = null
var total_duration: float = 0.0

func start(timer: SceneTreeTimer, duration: float) -> void:
	target_timer = timer
	total_duration = duration
	
	min_value = 0.0
	max_value = duration
	value = 0.0
	target_timer.timeout.connect(_on_timer_timeout)
	visible = true

func _process(_delta: float) -> void:
	if target_timer and target_timer.time_left > 0:
		value = target_timer.time_left

func _on_timer_timeout() -> void:
	value = max_value
	target_timer = null
	visible = false
