-- See LICENSE for terms

-- menus/buttons added to the Console

function OnMsg.ClassesGenerate()
	local ChoGGi = ChoGGi

	local PopupToggle = ChoGGi.ComFuncs.PopupToggle
	local OpenInExamineDlg = ChoGGi.ComFuncs.OpenInExamineDlg
	local DotNameToObject = ChoGGi.ComFuncs.DotNameToObject
	local RetFilesInFolder = ChoGGi.ComFuncs.RetFilesInFolder
	local S = ChoGGi.Strings
	local blacklist = ChoGGi.blacklist

	local StringFormat = string.format

	local ConsolePopupToggle_list = {
		{
			name = 302535920000040--[[Exec Code--]],
			hint = 302535920001287--[[Instead of a single line, you can enter/execute code in a textbox.--]],
			clicked = function()
				ChoGGi.ComFuncs.OpenInExecCodeDlg()
			end,
		},
		{
			name = 302535920001026--[[Show File Log--]],
			hint = 302535920001091--[[Flushes log to disk and displays in console log.--]],
			clicked = function()
				if blacklist then
					print(S[302535920000242--[[%s is blocked by SM function blacklist; use ECM HelperMod to bypass or tell the devs that ECM is awesome and it should have �ber access.--]]]:format("ShowFileLog"))
					return
				end
				FlushLogFile()
				print(select(2,AsyncFileToString(GetLogFile())))
			end,
		},
		{
			name = 302535920000071--[[Mods Log--]],
			hint = 302535920000870--[[Shows any errors from loading mods in console log.--]],
			clicked = function()
				print(ModMessageLog)
			end,
		},
		{name = " - "},
		{
			name = 302535920000734--[[Clear Log--]],
			hint = 302535920001152--[[Clear out the console log (F9 also works).--]],
			clicked = cls,
		},
		{
			name = 302535920000563--[[Copy Log Text--]],
			hint = 302535920001154--[[Displays the log text in a window you can copy sections from.--]],
			clicked = ChoGGi.ComFuncs.SelectConsoleLogText,
		},
		{
			name = 302535920000473--[[Reload ECM Menu--]],
			hint = 302535920000474--[[Fiddling around in the editor mod can break the menu / shortcuts added by ECM (use this to fix).--]],
			clicked = function()
				Msg("ShortcutsReloaded")
			end,
		},
		{name = " - "},
		{
			name = 302535920001112--[[Console Log--]],
			hint = 302535920001119--[[Toggle showing the console log on screen.--]],
			class = "ChoGGi_CheckButtonMenu",
			value = "dlgConsoleLog",
			clicked = function()
				ChoGGi.UserSettings.ConsoleToggleHistory = not ChoGGi.UserSettings.ConsoleToggleHistory
				ShowConsoleLog(ChoGGi.UserSettings.ConsoleToggleHistory)
				ChoGGi.SettingFuncs.WriteSettings()
			end,
		},
		{
			name = 302535920001120--[[Console Log Window--]],
			hint = 302535920001133--[[Toggle showing the console log window on screen.--]],
			class = "ChoGGi_CheckButtonMenu",
			value = "dlgChoGGi_ConsoleLogWin",
			clicked = function()
				ChoGGi.UserSettings.ConsoleHistoryWin = not ChoGGi.UserSettings.ConsoleHistoryWin
				ChoGGi.SettingFuncs.WriteSettings()
				ChoGGi.ComFuncs.ShowConsoleLogWin(ChoGGi.UserSettings.ConsoleHistoryWin)
			end,
		},
		{
			name = 302535920000483--[[Write Console Log--]],
			hint = S[302535920000484--[[Write console log to %slogs/ConsoleLog.log (writes immediately).--]]]:format(ConvertToOSPath("AppData/")),
			class = "ChoGGi_CheckButtonMenu",
			value = "ChoGGi.UserSettings.WriteLogs",
			clicked = function()
				if ChoGGi.UserSettings.WriteLogs then
					ChoGGi.UserSettings.WriteLogs = false
					ChoGGi.ComFuncs.WriteLogs_Toggle(false)
				else
					ChoGGi.UserSettings.WriteLogs = true
					ChoGGi.ComFuncs.WriteLogs_Toggle(true)
				end
				ChoGGi.SettingFuncs.WriteSettings()
			end,
		},
	}

	local function HistoryPopup(self)
		local dlgConsole = dlgConsole
		local ConsoleHistoryMenuLength = ChoGGi.UserSettings.ConsoleHistoryMenuLength or 50
		local items = {}
		if #dlgConsole.history_queue > 0 then
			local history = dlgConsole.history_queue
			for i = 1, #history do
				local text = tostring(history[i])
				items[i] = {
					-- these can get long so keep 'em short
					name = text:sub(1,ConsoleHistoryMenuLength),
					hint = StringFormat("%s\n\n%s",S[302535920001138--[[Execute this command in the console.--]]],text),
					clicked = function()
						dlgConsole:Exec(text)
					end,
				}
			end
		end
		PopupToggle(self,"idHistoryMenuPopup",items)
	end

	-- created when we create the controls controls the first time
	local ExamineMenuToggle_list = {}
	-- to add each item
	local function BuildExamineItem(name)
		if not name then
			return
		end
		local obj = DotNameToObject(name)
		local func = type(obj) == "function"
		local disp = StringFormat("%s%s",name,func and "()" or "")
		return {
			name = disp,
			hint = StringFormat("%s: %s",S[302535920000491--[[Examine Object--]]],disp),
			clicked = function()
				if func then
					OpenInExamineDlg(obj(),nil,disp)
				else
					OpenInExamineDlg(name,"str",disp)
				end
			end,
		}
	end
	-- build list of objects to examine
	local CmpLower = CmpLower
	local function BuildExamineMenu()
		table.iclear(ExamineMenuToggle_list)

		local list = ChoGGi.UserSettings.ConsoleExamineList or ""

		table.sort(list,function(a,b)
			-- damn eunuchs
			return CmpLower(a,b)
		end)

		for i = 0, #list do
			ExamineMenuToggle_list[i] = BuildExamineItem(list[i])
		end

		-- if Presets then add a submenu with each DefGlobalMap in PresetDefs (hopefully showing people the correct way to access them)
		local submenu = table.find(ExamineMenuToggle_list,"name","Presets")
		if submenu then
			-- remove hint from "submenu" menu
			ExamineMenuToggle_list[submenu].hint = nil
			-- build our list
			local submenu_table = {}
			local c = 0
			for _,value in pairs(PresetDefs) do
				if value.DefGlobalMap ~= "" then
					c = c + 1
					submenu_table[c] = BuildExamineItem(value.DefGlobalMap)
				end
			end
			c = c + 1
			submenu_table[c] = BuildExamineItem("BuildingTemplates")

			table.sort(submenu_table,
				function(a,b)
					-- damn eunuchs
					return CmpLower(a.name,b.name)
				end
			)
			-- add orig to the menu
			table.insert(submenu_table,1,BuildExamineItem("Presets"))
			-- poor guy is just getting crushed by the devs, and look at me not even giving it it's own menu
			table.insert(submenu_table,1,BuildExamineItem("DataInstances"))
			-- and done
			ExamineMenuToggle_list[submenu].submenu = submenu_table
		end
		-- add some stuff to UICity
		submenu = table.find(ExamineMenuToggle_list,"name","UICity")
		if submenu then
			ExamineMenuToggle_list[submenu].hint = nil
			ExamineMenuToggle_list[submenu].submenu = {
				BuildExamineItem("UICity"),
				BuildExamineItem("UICity.labels"),
				BuildExamineItem("UICity.tech_status"),
				BuildExamineItem("g_ApplicantPool"),
			}
		end
		-- merged const Consts g_Consts
		submenu = table.find(ExamineMenuToggle_list,"name","Consts")
		if submenu then
			ExamineMenuToggle_list[submenu].hint = nil
			ExamineMenuToggle_list[submenu].submenu = {
				BuildExamineItem("Consts"),
				BuildExamineItem("g_Consts"),
				BuildExamineItem("const"),
			}
		end

		-- threads
		submenu = table.find(ExamineMenuToggle_list,"name","ThreadsRegister")
		if submenu then
			ExamineMenuToggle_list[submenu].hint = nil
			ExamineMenuToggle_list[submenu].submenu = {
				BuildExamineItem("ThreadsRegister"),
				BuildExamineItem("ThreadsMessageToThreads"),
				BuildExamineItem("ThreadsThreadToMessage"),
				BuildExamineItem("s_SeqListPlayers"),
			}
		end

		-- Dialogs
		submenu = table.find(ExamineMenuToggle_list,"name","Dialogs")
		if submenu then
			ExamineMenuToggle_list[submenu].hint = nil
			ExamineMenuToggle_list[submenu].submenu = {
				BuildExamineItem("Dialogs"),
				BuildExamineItem("terminal.desktop"),
				BuildExamineItem("GetInGameInterface"),
			}
		end

		-- g_Classes
		submenu = table.find(ExamineMenuToggle_list,"name","g_Classes")
		if submenu then
			ExamineMenuToggle_list[submenu].hint = nil
			ExamineMenuToggle_list[submenu].submenu = {
				BuildExamineItem("g_Classes"),
				BuildExamineItem("ClassTemplates"),
				BuildExamineItem("EntityData"),
			}
		end

		-- bonus addition at bottom
		ExamineMenuToggle_list[#ExamineMenuToggle_list+1] = {
			name = 302535920001378--[[XWindow Inspector--]],
			hint = 302535920001379--[[Opens up the window inspector with terminal.desktop.--]],
			clicked = function()
				ChoGGi.ComFuncs.OpenGedApp("XWindowInspector")
			end,
		}
		-- bonus addition at the top
		table.insert(ExamineMenuToggle_list,1,{
			name = 302535920001376--[[Auto Update List--]],
			hint = 302535920001377--[[Update this list when ECM updates it.--]],
			class = "ChoGGi_CheckButtonMenu",
			value = "ChoGGi.UserSettings.ConsoleExamineListUpdate",
			clicked = function()
				ChoGGi.UserSettings.ConsoleExamineListUpdate = not ChoGGi.UserSettings.ConsoleExamineListUpdate
				ChoGGi.SettingFuncs.WriteSettings()
			end,
		})
	end

	-- rebuild list of objects to examine when user changes settings
	function OnMsg.ChoGGi_SettingsUpdated()
		BuildExamineMenu()
	end

	function ChoGGi.ConsoleFuncs.ConsoleControls(dlgConsole)
		local g_Classes = g_Classes

		-- make some space for the close button
		dlgConsole.idEdit:SetMargins(box(10, 0, 30, 5))
		if dlgConsoleLog then
			-- move log text above the buttons i added and make sure log text stays below the cheat menu
			dlgConsoleLog.idText:SetMargins(box(10, 80, 10, 65))
		end

		-- add close button
		g_Classes.ChoGGi_CloseButton:new({
			Id = "idClose",
			RolloverAnchor = "smart",
			OnPress = function()
				dlgConsole:Show()
			end,
			Margins = box(0, 0, 0, -26),
			Dock = "bottom",
			VAlign = "bottom",
			HAlign = "right",
		}, dlgConsole)

		-- stick everything in
		dlgConsole.idContainer = g_Classes.XWindow:new({
			Id = "idContainer",
			Margins = box(10, 0, 0, 0),
			HAlign = "left",
			Dock = "bottom",
			LayoutMethod = "HList",
			Image = "CommonAssets/UI/round-frame-20.tga",
		}, dlgConsole)

	--------------------------------Console popup
		dlgConsole.idConsoleMenu = g_Classes.ChoGGi_ConsoleButton:new({
			Id = "idConsoleMenu",
			RolloverText = S[302535920001089--[[Settings & Commands for the console.--]]],
			Text = S[302535920001308--[[Settings--]]],
			OnPress = function()
				PopupToggle(dlgConsole.idConsoleMenu,"idConsoleMenuPopup",ConsolePopupToggle_list)
			end,
		}, dlgConsole.idContainer)

		dlgConsole.idExamineMenu = g_Classes.ChoGGi_ConsoleButton:new({
			Id = "idExamineMenu",
			RolloverText = S[302535920000491--[[Examine Object--]]],
			Text = S[302535920000069--[[Examine--]]],
			OnPress = function()
				PopupToggle(dlgConsole.idExamineMenu,"idExamineMenuPopup",ExamineMenuToggle_list)
			end,
		}, dlgConsole.idContainer)

		dlgConsole.idHistoryMenu = g_Classes.ChoGGi_ConsoleButton:new({
			Id = "idHistoryMenu",
			RolloverText = S[302535920001080--[[Console history items (mouse-over to see code).--]]],
			Text = S[302535920000793--[[History--]]],
			OnPress = HistoryPopup,
		}, dlgConsole.idContainer)

		if not blacklist then
			dlgConsole.idScripts = g_Classes.XWindow:new({
				Id = "idScripts",
				LayoutMethod = "HList",
			}, dlgConsole.idContainer)
		end

		-- changed examine list to a saved one instead of one made of .lua files
		BuildExamineMenu()
	end

	local function BuildSciptButton(dlg,folder)
		g_Classes.ChoGGi_ConsoleButton:new({
			RolloverText = folder.RolloverText,
			Text = folder.Text,
			OnPress = function(self)
				-- build list of scripts to show
				local items = {}
				local files = RetFilesInFolder(folder.script_path,".lua")
				if files then
					for i = 1, #files do
						local _, script = AsyncFileToString(files[i].path)
						items[i] = {
							name = files[i].name,
							hint = StringFormat("%s\n\n%s",S[302535920001138--[[Execute this command in the console.--]]],script),
							clicked = function()
								dlg:Exec(script)
							end,
						}
					end
					PopupToggle(self,folder.id,items)
				else
					print(S[591853191640--[[Empty list--]]])
				end
			end,
		}, dlg.idScripts)
	end

	-- only check for ECM Scripts once per load
	local script_files_added
	-- rebuild menu toolbar buttons
	function ChoGGi.ConsoleFuncs.RebuildConsoleToolbar(dlg)
		if blacklist then
			return
		end

		dlg = dlg or dlgConsole
		local ChoGGi = ChoGGi

		if not dlg.idScripts then
			-- we're in the select new map stuff screen
			return
		end

		-- add example script files if folder is missing
		if not script_files_added then
			ChoGGi.ConsoleFuncs.BuildScriptFiles()
			script_files_added = true
		end

		-- clear out old buttons first
		for i = #dlg.idScripts, 1, -1 do
			dlg.idScripts[i]:delete()
			table.remove(dlg.idScripts,i)
		end

		-- build Scripts button
		if RetFilesInFolder(ChoGGi.scripts,".lua") then
			BuildSciptButton(dlg,{
				Text = S[302535920000353--[[Scripts--]]],
				RolloverText = S[302535920000881--[["Place .lua files in %s to have them show up in the ""Scripts"" list, you can then use the list to execute them (you can also create folders for sorting)."--]]]:format(ChoGGi.scripts),
				id = "idScriptsMenuPopup",
				script_path = ChoGGi.scripts,
			})
		end

		-- check for any folders with lua files in ECM Scripts
		local folders = ChoGGi.ComFuncs.RetFoldersInFolder(ChoGGi.scripts)
		if folders then
			local hint_str = S[302535920001159--[[Any .lua files in %s.--]]]
			for i = 1, #folders do
				if RetFilesInFolder(folders[i].path,".lua") then
					BuildSciptButton(dlg,{
						Text = folders[i].name,
						RolloverText = hint_str:format(folders[i].path),
						id = StringFormat("id%sMenuPopup",folders[i].name),
						script_path = folders[i].path,
					})
				end
			end
		end
	end

	function ChoGGi.ConsoleFuncs.BuildScriptFiles()
		local script_path = ChoGGi.scripts
		-- create folder and some example scripts if folder doesn't exist
		if not ChoGGi.ComFuncs.FileExists(script_path) then
			AsyncCreatePath(StringFormat("%s/Functions",script_path))
			-- print some info
			print(S[302535920000881--[["Place .lua files in %s to have them show up in the ""Scripts"" list, you can then use the list to execute them (you can also create folders for sorting)."--]]]:format(ConvertToOSPath(script_path)))
			-- add some example files and a readme
			AsyncStringToFile(StringFormat("%s/readme.txt",script_path),S[302535920000888--[[Any .lua files in here will be part of a list that you can execute in-game from the console menu.--]]])
			AsyncStringToFile(StringFormat("%s/Read Me.lua",script_path),[[ChoGGi.ComFuncs.MsgWait(ChoGGi.Strings[302535920000881]:format(ChoGGi.scripts))]])
			AsyncStringToFile(StringFormat("%s/Functions/Amount of colonists.lua",script_path),[[#(UICity.labels.Colonist or "")]])
			AsyncStringToFile(StringFormat("%s/Functions/Toggle Working SelectedObj.lua",script_path),[[SelectedObj:ToggleWorking()]])
		end
	end

end
