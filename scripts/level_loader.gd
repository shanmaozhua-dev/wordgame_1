extends RefCounted

static func build_test_level() -> Dictionary:
	return {
		"rows": [
			"墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙",
			"墙我 手表  石 墙          天 气很好        墙",
			"墙    删  戏  又 戈                  墙",
			"墙                                  墙",
			"墙                                  墙",
			"墙                                  墙",
			"墙                                  墙",
			"墙                                  墙",
			"墙                                  墙",
			"墙                                  墙",
			"墙                                  墙",
			"墙                                  墙",
			"墙                                  墙",
			"墙                                  墙",
			"墙                                  墙",
			"墙                                  墙",
			"墙                                  墙",
			"墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙墙"
		],
		"player_start": Vector2i(1, 1),
		"screen_size": Vector2i(32, 18),
		"entities": {
			"手表": {"interact_text": "手表可以查看人类世界的时间", "solid": true},
			"石": {"pushable": true, "solid": true},
			"删": {"deletable": true, "solid": true},
			"戏": {"splittable": true, "pushable": true, "solid": true},
			"又": {"pushable": true, "solid": true},
			"戈": {"pushable": true, "solid": true},
			"天": {"pushable": true, "solid": true},
			"气": {"solid": true},
			"很": {"solid": true},
			"好": {"solid": true}
		},
		"split_rules": {"戏": ["又", "戈"]},
		"merge_rules": {"又+戈": "戏", "戈+又": "戏"},
		"sentence_rules": {"天气": {"message": "已识别"}}
	}

static func build_hero_trial_fist_level() -> Dictionary:
	return {
		"player_start": Vector2i(21, 16),
		"cell_size": 24,
		"screen_size": Vector2i(32, 18),
		"map_text_lines": [
			{"pos": Vector2i(1, 2), "text": " 得聖劍，拜見指內勇者。"},
			{"pos": Vector2i(1, 3), "text": "巨掌緊握， 會輕易放開。"},
			{"pos": Vector2i(1, 5), "text": " 勇者站在旁邊大力 揚。"},
			{"pos": Vector2i(14, 1), "text": "掌掌掌  掌掌掌  掌掌掌"},
			{"pos": Vector2i(14, 2), "text": "掌   掌  掌   掌  掌"},
			{"pos": Vector2i(14, 3), "text": "掌   掌  掌   掌  掌掌掌"},
			{"pos": Vector2i(14, 4), "text": "掌   掌  掌   掌  掌   "},
			{"pos": Vector2i(14, 5), "text": "掌   掌  掌   掌  掌   "},
			{"pos": Vector2i(14, 6), "text": "掌掌掌  掌掌掌  掌掌掌"},
			{"pos": Vector2i(1, 8), "text": "勇：別被一條線給困住了！"},
			{"pos": Vector2i(13, 8), "text": "掌掌掌掌掌掌掌掌"},
			{"pos": Vector2i(13, 9), "text": "掌     掌"},
			{"pos": Vector2i(14, 10), "text": "掌   掌掌掌"},
			{"pos": Vector2i(15, 11), "text": "掌掌掌 掌"},
			{"pos": Vector2i(16, 12), "text": "掌   掌"},
			{"pos": Vector2i(12, 13), "text": "逼退 手的生命線"},
			{"pos": Vector2i(1, 16), "text": "勇：上啊！"},
			{"pos": Vector2i(15, 17), "text": "俯瞰這 個巨大手掌，是 的手勢"}
		],
		"entity_spawns": [
			{"text": "贏", "pos": Vector2i(1, 2)},
			{"text": "不", "pos": Vector2i(6, 3)},
			{"text": "二", "pos": Vector2i(1, 5)},
			{"text": "讚", "pos": Vector2i(10, 5)},
			{"text": "一", "pos": Vector2i(18, 17)},
			{"text": "零", "pos": Vector2i(26, 17)},
			{"text": "好", "pos": Vector2i(14, 13)},
			{"text": "劍", "pos": Vector2i(16, 7)},
			{"text": "勇", "pos": Vector2i(24, 4)}
		],
		"entities": {
			"贏": {"pushable": true, "solid": true},
			"不": {"pushable": true, "deletable": true, "solid": true},
			"二": {"pushable": true, "solid": true},
			"讚": {"pushable": true, "solid": true},
			"一": {"pushable": true, "solid": true},
			"零": {"pushable": true, "solid": true},
			"好": {"pushable": true, "solid": true},
			"劍": {"solid": true},
			"勇": {"solid": true}
		},
		"sentence_rules": {
			"巨大手掌，是好的手勢": {
				"message": "已識別：好的手勢",
				"switch": "ch3_好的手勢成立",
				"state": {"current_gesture": "好"},
				"caption_pos": Vector2i(18, 15),
				"spawn_entities": [
					{"text": "好手勢", "pos": Vector2i(24, 8), "config": {"solid": true}}
				]
			},
			"巨大手掌，是二的手勢": {
				"message": "已識別：二的手勢",
				"switch": "ch3_二的手勢成立",
				"state": {"current_gesture": "二"},
				"caption_pos": Vector2i(18, 15)
			},
			"巨大手掌，是讚的手勢": {
				"message": "已識別：讚的手勢",
				"switch": "ch3_讚的手勢成立",
				"state": {"current_gesture": "讚"},
				"caption_pos": Vector2i(18, 15)
			},
			"巨大手掌，是贏的手勢": {
				"message": "已識別：贏的手勢",
				"switch": "ch3_贏的手勢成立",
				"state": {"current_gesture": "贏"},
				"caption_pos": Vector2i(18, 15)
			},
			"會輕易放開": {
				"message": "尾聲：巨掌鬆開，勇者試煉完成",
				"switch": "ch3_會輕易放開成立",
				"switches": {"hero_trial_complete": true},
				"caption_pos": Vector2i(5, 15)
			},
			"不會輕易放開": {
				"message": "巨掌仍然緊握",
				"switch": "ch3_不會輕易放開成立",
				"caption_pos": Vector2i(5, 15)
			}
		}
	}
