class_name EvidenceDef
extends Resource

## 可被任务、对话和结局条件引用的调查证据定义。

@export var evidence_id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var chapter: int = 1
@export var category: StringName = &"physical"
@export var source_hint: String = ""
@export var related_testimony_ids: Array[StringName] = []
@export var tags: Array[StringName] = []

