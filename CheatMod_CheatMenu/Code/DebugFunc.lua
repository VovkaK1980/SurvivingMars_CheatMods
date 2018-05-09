
--no sense in building the list more then once?
local ObjectSpawner_ItemList = {}
function ChoGGi.ObjectSpawner()
  --if #ObjectSpawner_ItemList == 0 then
  if not next(ObjectSpawner_ItemList) then
    for Key,_ in pairs(g_Classes) do
      table.insert(ObjectSpawner_ItemList,{
        text = Key,
        value = Key
      })
    end
  end

  local CallBackFunc = function(choice)
    local value = choice[1].value
    if g_Classes[value] then
      PlaceObj(value,{"Pos",GetTerrainCursor()})

      --[[
      --local NewObj = PlaceObj(value,{"Pos",GetTerrainCursor()})
      for _, prop in iXpairs(NewObj:GetProperties()) do
        NewObj:SetProperty(prop.id, NewObj:GetDefaultPropertyValue(prop.id, prop))
      end
      --]]

      ChoGGi.MsgPopup("Spawned: " .. choice[1].text,"Object")
    end
  end

  local hint = "Warning: Objects are unselectable with mouse cursor (hover mouse over and use Delete Selected Object)."
  ChoGGi.FireFuncAfterChoice(CallBackFunc,ObjectSpawner_ItemList,"Object Spawner",hint)
end

function ChoGGi.ShowSelectionEditor()
  --check for any opened windows and kill them
  for i = 1, #terminal.desktop do
    if IsKindOf(terminal.desktop[i],"ObjectsStatsDlg") then
      terminal.desktop[i]:delete()
    end
  end
  --open a new copy
  local dlg = ObjectsStatsDlg:new()
  if not dlg then
    return
  end
  dlg:SetPos(terminal.GetMousePos())

  --OpenDialog("ObjectsStatsDlg",nil,terminal.desktop)
end

function ChoGGi.SetWriteLogs()
  ChoGGi.CheatMenuSettings.WriteLogs = not ChoGGi.CheatMenuSettings.WriteLogs
  ChoGGi.WriteLogs_Toggle(ChoGGi.CheatMenuSettings.WriteLogs)

  ChoGGi.WriteSettings()
  ChoGGi.MsgPopup("Write debug/console logs: " .. tostring(ChoGGi.CheatMenuSettings.WriteLogs),
    "Logging","UI/Icons/Anomaly_Breakthrough.tga"
  )
end

function ChoGGi.ObjExaminer()
  local obj = SelectedObj or SelectionMouseObj()
  --OpenExamine(SelectedObj)
  if obj == nil then
    return ClearShowMe()
  end
  local ex = Examine:new()
  ex:SetPos(terminal.GetMousePos())
  ex:SetObj(obj)
end

function ChoGGi.Editor_Toggle()
  --keep menu opened if visible
  local showmenu
  if dlgUAMenu then
    showmenu = true
  end

  if IsEditorActive() then
    EditorState(0)
    table.restore(hr, "Editor")
    editor.SavedDynRes = false
    XShortcutsSetMode("Game")
  else
    table.change(hr, "Editor", {
      ResolutionPercent = 100,
      SceneWidth = 0,
      SceneHeight = 0,
      DynResTargetFps = 0
    })
    XShortcutsSetMode("Editor", function()
      EditorDeactivate()
    end)
    EditorState(1,1)
    GetEditorInterface():Show(true)

    --GetToolbar():SetVisible(true)
    editor.OldCameraType = {
      GetCamera()
    }
    editor.CameraWasLocked = camera.IsLocked(1)
    camera.Unlock(1)

    GetEditorInterface():SetVisible(true)
    GetEditorInterface():ShowSidebar(true)
    GetEditorInterface().dlgEditorStatusbar:SetVisible(true)
    --GetEditorInterface():SetMinimapVisible(true)
    --CreateEditorPlaceObjectsDlg()
    if showmenu then
      UAMenu.ToggleOpen()
    end
  end
end

function ChoGGi.DeleteObject()
  local obj = SelectedObj or SelectionMouseObj()

  --deleting domes will freeze game if they have anything in them.
  if IsKindOf(obj,"Dome") and obj.air then
    return
  end

  --some stuff will leave holes in the world if they're still working
  if obj.working then
    obj:ToggleWorking()
  end

  --try nicely first
  pcall(function()
    obj.can_demolish = true
    obj.indestructible = false
    DestroyBuildingImmediate(obj)
    obj:Destroy()
  end)

  --clean up
  pcall(function()
    obj:SetDome(false)
  end)
  pcall(function()
    obj:RemoveFromLabels()
  end)
  pcall(function()
    obj:Done()
  end)
  pcall(function()
    obj:Gossip("done")
  end)
  pcall(function()
    obj:StopFX()
    PlayFX("Spawn", "end", obj)
    obj:SetHolder(false)
  end)
  if obj.sphere then
    obj.sphere:delete()
  end
  if obj.decal then
    obj.decal:delete()
  end

  --fuck it, I asked nicely
  if obj then
    pcall(function()
      obj:delete()
    end)
  end

    --so we don't get an error from UseLastOrientation
  ChoGGi.LastPlacedObject = nil
end

function ChoGGi.ConsoleHistory_Toggle()
  ChoGGi.CheatMenuSettings.ConsoleToggleHistory = not ChoGGi.CheatMenuSettings.ConsoleToggleHistory
  ShowConsoleLog(ChoGGi.CheatMenuSettings.ConsoleToggleHistory)

  ChoGGi.WriteSettings()
  ChoGGi.MsgPopup(tostring(ChoGGi.CheatMenuSettings.ConsoleToggleHistory) .. ": Those who cannot remember the past are condemned to repeat it.",
    "Console","UI/Icons/Sections/workshifts.tga"
  )
end

function ChoGGi.ChangeMap()
  CreateRealTimeThread(function()
    local caption = Untranslated("Choose map with settings presets:")
    local maps = ListMaps()
    local items = {}
    for i = 1, #maps do
      if not string.find(string.lower(maps[i]), "^prefab") and not string.find(maps[i], "^__") then
        table.insert(items, {
          text = Untranslated(maps[i]),
          map = maps[i]
        })
      end
    end
    local default_selection = table.find(maps, GetMapName())
    local map_settings = {}
    local class_names = ClassDescendantsList("MapSettings")
    for i = 1, #class_names do
      local class = class_names[i]
      map_settings[class] = mapdata[class]
    end
    local sel_idx
    sel_idx, map_settings = WaitMapSettingsDialog(items, caption, nil, default_selection, map_settings)
    if sel_idx ~= "idCancel" then
      local map = sel_idx and items[sel_idx].map
      if not map or map == "" then
        return
      end
      CloseMenuDialogs()
      StartGame(map, map_settings)
      LocalStorage.last_map = map
      SaveLocalStorage()
    end
  end)
end
