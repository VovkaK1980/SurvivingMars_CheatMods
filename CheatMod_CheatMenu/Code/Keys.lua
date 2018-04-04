
ChoGGi.AddAction(nil,
  function()
    ShowConsole(true)
  end,
  "~"
)

ChoGGi.AddAction(nil,
  function()
    ShowConsole(true)
  end,
  "Enter"
)

ChoGGi.AddAction(nil,
  function()
    ShowConsole(true)
    AddConsolePrompt("restart")
  end,
  "Ctrl-Alt-Shift-R"
)
--goes to placement mode with last built object
ChoGGi.AddAction(nil,
  function()
    if ChoGGi.LastPlacedObj.entity then
      ChoGGi.ConstructionModeSet(ChoGGi.LastPlacedObj.encyclopedia_id or ChoGGi.LastPlacedObj.entity)
    end
  end,
  "Ctrl-Space"
)
--goes to placement mode with SelectedObj
ChoGGi.AddAction(nil,
  function()
    ChoGGi.ConstructionModeNameClean(SelectedObj:__toluacode())
  end,
  "Ctrl-Shift-Space"
)

ChoGGi.AddAction(nil,UAMenu.ToggleOpen,"F2")
ChoGGi.AddAction(nil,function() quit("restart") end,"Ctrl-Shift-Alt-Numpad Enter")

if ChoGGi.Testing then
  table.insert(ChoGGi.FilesCount,"Keys")
end
