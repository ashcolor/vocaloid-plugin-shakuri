--shakuri.lua
--
-- プラグインマニフェスト関数.
--
function manifest()
    myManifest = {
        name          = "しゃくり",
        comment       = "子音と母音を分割し,しゃくりをつける.",
        author        = "ashcolor_106",
        pluginID      = "{CF34ED23-9050-4094-876A-BA82FB6B0815}",
        pluginVersion = "1.0.0.0",
        apiVersion    = "3.0.0.1"
    }
    
    return myManifest
end

-- targetMinDuration (table).
targetMinDurationList = {
	{ targetMinDurationStr = "全音符",	targetMinDuration = 1	},	-- 全音符.
	{ targetMinDurationStr = "2分音符",	targetMinDuration = 2	},	-- 2分音符.
	{ targetMinDurationStr = "4分音符",	targetMinDuration = 3	},	-- 4分音符.
	{ targetMinDurationStr = "8分音符",	targetMinDuration = 4	}	-- 8分音符.
}
targetMinDurationIDNum = table.getn(targetMinDurationList)

-- length list (table).
lengthList = {
	{ lengthStr = "3連8分音符",	length = 1	},	-- 3連8分音符.
	{ lengthStr = "16分音符",	length = 2	},	-- 16分音符.
	{ lengthStr = "3連16分音符",	length = 3	},	-- 3連16分音符.
	{ lengthStr = "32分音符",	length = 4	}	-- 32分音符.
}
lengthIDNum = table.getn(lengthList)

-- depth list (table).
depthList = {
	{ depthStr = "半音",	depth = 1	},	-- 半音.
	{ depthStr = "全音",	depth = 2	}	-- 全音.
}
depthIDNum = table.getn(depthList)


--
-- スクリプトのエントリポイント関数.
--
function main(processParam, envParam)
	-- 実行時に渡されたパラメータを取得する.
	local beginPosTick = processParam.beginPosTick	-- 選択範囲の始点時刻（ローカルTick）.
	local endPosTick   = processParam.endPosTick	-- 選択範囲の終点時刻（ローカルTick）.
	local songPosTick  = processParam.songPosTick	-- カレントソングポジション時刻（ローカルTick）.

	-- 実行時に渡された実行環境パラメータを取得する.
	local scriptDir  = envParam.scriptDir	-- Luaスクリプトが配置されているディレクトリパス（末尾にデリミタ "\" を含む）.
	local scriptName = envParam.scriptName	-- Luaスクリプトのファイル名.
	local tempDir    = envParam.tempDir		-- Luaプラグインが利用可能なテンポラリディレクトリパス（末尾にデリミタ "\" を含む）.

	-- 終了コード.
	local endStatus = 0

	-- パラメータ入力ダイアログのウィンドウタイトルを設定する.
	VSDlgSetDialogTitle("しゃくり")

	-- ダイアログにフィールドを追加する.
	local field = {}

	-- ダイアログにフィールドを追加する.
	-- Set start position tick.
	field.name       = "startTick"
	field.caption    = "Start Time (Tick)"
	field.initialVal = beginPosTick
	field.type       = 0
	dlgStatus        = VSDlgAddField(field)

	-- Set end position tick.
	field.name       = "endTick"
	field.caption    = "End Time (Tick)"
	field.initialVal = endPosTick;
	field.type       = 0
	dlgStatus        = VSDlgAddField(field)

	-- targetMinDurationドロップダウンリスト.
	field.name       = "targetMinDurationStr"
	field.caption    = "Min Duration of Target"
	field.initialVal =
		"全音符" ..
		",2分音符" ..
		",4分音符" ..
		",8分音符"
	field.type = 4
	dlgStatus  = VSDlgAddField(field)

	-- lengthドロップダウンリスト.
	field.name       = "lengthStr"
	field.caption    = "Length"
	field.initialVal =
		"3連8分音符" ..
		",16分音符" ..
		",3連16分音符" ..
		",32分音符"
	field.type = 4
	dlgStatus  = VSDlgAddField(field)

	-- depthドロップダウンリスト.
	field.name       = "depthStr"
	field.caption    = "Depth"
	field.initialVal =
		"半音" ..
		",全音"
	field.type = 4
	dlgStatus  = VSDlgAddField(field)

	-- ダイアログから入力値を取得する.
	dlgStatus = VSDlgDoModal()
	if (dlgStatus == 2) then
		-- When it was cancelled.
		return 0
	end
	if ((dlgStatus ~= 1) and (dlgStatus ~= 2)) then
		-- When it returned an error.
		return 1
	end

	-- ダイアログから入力値を取得する.
	dlgStatus, startTick  = VSDlgGetIntValue("startTick")
	dlgStatus, endTick = VSDlgGetIntValue("endTick")
	dlgStatus, targetMinDurationStr = VSDlgGetStringValue("targetMinDurationStr")
	dlgStatus, lengthStr = VSDlgGetStringValue("lengthStr")
	dlgStatus, depthStr = VSDlgGetStringValue("depthStr")

	-- targetMinDurationStrをIDに変換する.
	local index = 1
	local targetMinDuration = 0
	for index, str in ipairs(targetMinDurationList) do
		if (targetMinDurationStr == str.targetMinDurationStr) then
			targetMinDuration = str.targetMinDuration
		end
	end

	-- lengthをIDに変換する.
	local index = 1
	local length = 0
	for index, str in ipairs(lengthList) do
		if (lengthStr == str.lengthStr) then
			length = str.length
		end
	end

	-- depthをIDに変換する.
	local index = 1
	local depth = 0
	for index, str in ipairs(depthList) do
		if (depthStr == str.depthStr) then
			depth = str.depth
		end
	end

	-- ノートリストの先頭に位置づける.
	VSSeekToBeginNote()

	-- 先頭ノートを取得する.
	local retCode, note = VSGetNextNoteEx()


	-- targetMinDurationから,minDurationを設定する.
	local minDuration = 0

	if (targetMinDuration == targetMinDurationList[1].targetMinDuration) then
		-- 全音符.
		minDuration = 1920

	elseif (targetMinDuration == targetMinDurationList[2].targetMinDuration) then
		-- 2分音符.
		minDuration = 960

	elseif (targetMinDuration == targetMinDurationList[3].targetMinDuration) then
		-- 4分音符.
		minDuration = 480

	elseif (targetMinDuration == targetMinDurationList[4].targetMinDuration) then
		-- 8分音符.
		minDuration = 240

	end

	-- lengthから,lengthを設定する.
	local duration = 0

	if (length == lengthList[1].length) then
		-- 3連8分音符.
		duration = 160

	elseif (length == lengthList[2].length) then
		-- 16分音符.
		duration = 120

	elseif (length == lengthList[3].length) then
		-- 3連16分音符.
		duration = 80

	elseif (length == lengthList[4].length) then
		-- 32分音符.
		duration = 60

	end

	-- depthから,depthを設定する.
	local dep = 0

	if (depth == depthList[1].depth) then
		-- 半音符.
		dep = 1

	elseif (depth == depthList[2].depth) then
		-- 全音符.
		dep = 2

	end

	-- ノートを更新する.
	while (retCode == 1) do

		-- 適応範囲内かどうか判定する.
		if ((startTick <= note.posTick) and (note.posTick < endTick)) then

			-- 設定されたDurationより長いかを判定する.
			if (note.durTick >= minDuration) then

				-- 母音Noteの追加.
				local	note1 = {}                      -- ノートテーブルデータの生成.
				note1.posTick  = note.posTick + duration
				note1.durTick  = note.durTick - duration
				note1.velocity = 64             -- ベロシティーの設定.

				note1.noteNum  = note.noteNum       -- 音程の設定.
				note1.lyric    = "-"       -- 歌詞の設定.
				note1.phonemes = "-"     -- 発音記号の設定.

				retCode = VSInsertNote(note1)
				if (retCode ~= 1) then
					VSMessageBox("追加エラー発生!!", 0)
					return 1
				end

				-- DurationとnoteNumを変更する.		
				note.durTick = duration
				note.noteNum = note.noteNum - dep
			

				retCode = VSUpdateNoteEx(note)
				if (retCode == 0) then
					-- 更新エラー.
					endStatus = 1
					break
				end

				-- 次のノートを取得する.
				retCode, note = VSGetNextNoteEx()
			end
		end


			-- 次のノートを取得する.
			retCode, note = VSGetNextNoteEx()
	end
	
	return endStatus
end
