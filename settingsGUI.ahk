; TODO:
; - Handle duplicate hotkeys???
; - Prevent hotkeys being the same as the hotkey to open settings (if I decide to use a hotkey to open settings)
; - Grey voice controls if voice muted???
; - Can it handle new settings being added postlaunch when users have an exisitng settingsFile?
; - The control that is autoselected is a hotkey input so easy to enter something there

hotkeyDescr := [ "Open new word pad document"
                ,"Open saved word pad document"
                ,"Read document outloud"                
                ,"Save document"
                ,"Print"
                ,"Stop/Start Dictation"
                ,"Show/Hide Magnifier"                
                ,"Restart F-Access"]

hotkeyNames := [ "openNewDoc"
                ,"openSavedDoc"
                ,"readDoc"
                ,"saveDoc"
                ,"print"
                ,"toggleDictation"               
                ,"toggleMag"
                ,"restart"]

defaultKeys := ["F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8"]
prevHotKey  := []

settingsFile := "projectSettings.ini"

; The saved keys are retrieved in the order of the names in hotkeyNames
for i, name in hotkeyNames {
    IniRead, key, % settingsFile, HotKeys, % name, % defaultKeys[i]

    if (key != "") {
        HotKey, % key, % name, on
    }

    prevHotKey[i] := key
}

global buttonW  := 75
global centered := False

constructGUI() {
    global 

    ; Adding the customisable hotkeys to the GUI
    for i, descr in hotkeyDescr {
        local custom := "Custom" . i

        Gui, Add, Text  , xm   w200                 , % descr
        Gui, Add, Hotkey, x+10 v%custom% gEnableSave, % prevHotKey[i] ; Displays the current key combo (stored in prevHotKey)
    }

    ; Load General Checkboxes
    IniRead, offlineCheckAllowed, % settingsFile, Printing , OfflineCheck, 1
    IniRead, magStartup         , % settingsFile, Magnifier, Startup     , 1

    ; General CheckBoxes
    Gui, Add, CheckBox, xm vofflineCheckAllowed gEnableSave Checked%offlineCheckAllowed%, % "Enable printer offline check?"   
    Gui, Add, CheckBox, xm vmagStartUp          gEnableSave Checked%magStartup%         , % "Open magnifier on startup of F-Access"

    ; Voices
    voicesList := ""
    for v in VoiceTyped.GetVoices() {
        voiceName  := v.GetAttribute("Name")
        voicesList .= voiceName . "|"
    }
    voicesList := RTrim(voicesList, "|")
    
    if (voicesList == "") {        
        Gui, Font, cRed
        Gui, Add, Link, xm y+20, No installed languages detected - please add a <a href="ms-settings:regionlanguage">language</a>
        Gui, Font, cDefault
    }    

    ; Retrieving saved voice settings and applying them to the voice
    IniRead, CommandVol  , % settingsFile, CommandVoice, Volume, 100
    IniRead, CommandRate , % settingsFile, CommandVoice, Rate  , 0
    IniRead, CommandVoice, % settingsFile, CommandVoice, Voice , 1
    IniRead, CommandMute , % settingsFile, CommandVoice, Mute  , 0
    VoiceCommand.Volume := CommandVol
    VoiceCommand.Rate   := CommandRate   
    VoiceCommand.Voice  := VoiceCommand.GetVoices().Item(CommandVoice-1)

    IniRead, TypedVol  , % settingsFile, TypedVoice, Volume, 100
    IniRead, TypedRate , % settingsFile, TypedVoice, Rate  , 0
    IniRead, TypedVoice, % settingsFile, TypedVoice, Voice , 1
    IniRead, TypedMute , % settingsFile, TypedVoice, Mute  , 0
    VoiceTyped.Volume := TypedVol
    VoiceTyped.Rate   := TypedRate
    VoiceTyped.Voice  := VoiceTyped.GetVoices().Item(TypedVoice-1)

    ; TODO:
    ; - Place in a funtion as only minor differences?
    ; - Local CommandVolText? currently made as a global variable
    ; - Place GroupBoxes side by side? to reduce vertical length of gui

    ; Command Voice
    Gui, Add, GroupBox, xm y+20 w300 r8 Section, Command Voice
    Gui, Add, Text, w50 vCommandVolText , % "Volume:"
    Gui, Add, Text, w50 vCommandRateText, % "Speech`nRate:"
    Gui, Add, Slider,   xs+60 ys+20  w200 vCommandVol   gEnableSave Range0-100  ToolTip TickInterval5 Buddy1CommandVolText , % CommandVol
    Gui, Add, Slider,   xs+60 ys+60  w200 vCommandRate  gEnableSave Range-10-10 ToolTip TickInterval1 Buddy1CommandRateText, % CommandRate
    Gui, Add, Text,     xs+10 ys+110 w50, % "Voice"
    Gui, Add, DDL,      x+5   ys+110 w150 vCommandVoice gEnableSave Choose%CommandVoice% AltSubmit, % voicesList
    Gui, Add, CheckBox, xs+10 ys+140      vCommandMute  gEnableSave Checked%CommandMute%          , % "Mute commands being spoken?"

    ; Typed Word Voice
    Gui, Add, GroupBox, xm y+30 w300 r8 Section, Typed Words Voice
    Gui, Add, Text, w50 vTypedVolText , % "Volume:"
    Gui, Add, Text, w50 vTypedRateText, % "Speech`nRate:"
    Gui, Add, Slider,   xs+60 ys+20  w200 vTypedVol   gEnableSave Range0-100  ToolTip TickInterval5 Buddy1TypedVolText , % TypedVol
    Gui, Add, Slider,   xs+60 ys+60  w200 vTypedRate  gEnableSave Range-10-10 ToolTip TickInterval1 Buddy1TypedRateText, % TypedRate
    Gui, Add, Text,     xs+10 ys+110 w50, % "Voice"
    Gui, Add, DDL,      x+5   ys+110 w150 vTypedVoice gEnableSave Choose%TypedVoice% AltSubmit, % voicesList
    Gui, Add, CheckBox, xs+10 ys+140      vTypedMute  gEnableSave Checked%TypedMute%          , % "Mute typed words being spoken?"

    ; Control buttons
    Gui, Add, Button, xm   w%buttonW% vDefaultButton gDefault, Default
    Gui, Add, Button, x+10 w%buttonW% vCancelButton  gCancel , Cancel
    Gui, Add, Button, x+10 w%buttonW% vSaveButton    gSave   , Save
    GuiControl, Disable, SaveButton
    GuiControl, Disable, CancelButton
    
    Gui, Show, Hide ; Enabling the buttons to be centered
}


; Used to equally spread the control buttons
GuiSize(GuiHwnd, EventInfo, Width, Height) {
    if(centered) {
        Return
    }

    addPosX := (Width - buttonW) // 5

    ; GuiControl, Move, SaveButton, % "x" addPosX
    ; GuiControl, Move, SaveButton, % "x" addPosX+buttonW+10
    ; GuiControl, Move, SaveButton, % "x" addPosX+buttonW+10+buttonW+10
    ; GuiControl, Move, ExitButton, % "x" addPosX+buttonW+10+buttonW+10+buttonW+10
    
    centered := True
}

Save() {
    global

    local prevTypedMute := TypedMute
    Gui, Submit, NoHide

    for i, name in hotkeyNames {
        local prev   := prevHotKey[i]
        local custom := "Custom" . i

        if (prev == %custom%) {
            continue
        }

        ; Removing old hotkey
        if (prev != "") {
            HotKey, % prev, % name, off
        }

        ; Treating the string inside custom as a variable (which contains the key combo for the GUI hotkey control)
        if (%custom% != "") {
            HotKey, % %custom%, % name, on
        }

        ; Still writes key to the file even if empty key
        IniWrite, % %custom%, % settingsFile, HotKeys, % name

        prevHotKey[i] := %custom%
    }
    
    IniWrite, % offlineCheckAllowed, % settingsFile, Printing , OfflineCheck
    IniWrite, % magStartup         , % settingsFile, Magnifier, Startup

    VoiceCommand.Volume := CommandVol
    VoiceCommand.Rate   := CommandRate
    VoiceCommand.Voice  := voiceCommand.GetVoices().Item(CommandVoice-1)
    IniWrite, % CommandVol  , % settingsFile, CommandVoice, Volume
    IniWrite, % CommandRate , % settingsFile, CommandVoice, Rate
    IniWrite, % CommandVoice, % settingsFile, CommandVoice, Voice
    IniWrite, % CommandMute , % settingsFile, CommandVoice, Mute
    
    VoiceTyped.Volume := TypedVol
    VoiceTyped.Rate   := TypedRate
    VoiceTyped.Voice  := VoiceTyped.GetVoices().Item(TypedVoice-1)
    IniWrite, % TypedVol  , % settingsFile, TypedVoice, Volume
    IniWrite, % TypedRate , % settingsFile, TypedVoice, Rate
    IniWrite, % TypedVoice, % settingsFile, TypedVoice, Voice
    IniWrite, % TypedMute , % settingsFile, TypedVoice, Mute

    ; Starting/Stopping the input logger for the typed voice
    local mute   := !prevTypedMute and  TypedMute
    local unmute :=  prevTypedMute and !TypedMute

    if (mute) {
        inputHook.Stop()
    }
    else if (unmute){
        inputHook.Start()
    }

    GuiControl, Disable, SaveButton
    GuiControl, Disable, CancelButton
}

Default() {
    global

    for i, key in defaultKeys {
        ; Using custom just as a ControlID
        custom := "Custom" . i               
        GuiControl, , % custom, % key
    }

    GuiControl, Disable, DefaultButton
    GuiControl, Enable , SaveButton
    GuiControl, Enable , CancelButton
}

Cancel() {
    global

    ; Load *all* saved settings into the GUI

    ; Have a saved array of settings? So don't have to keep reading the .ini
    ; Then only write the array to the .ini file on exit of the GUI?

    ; Sadly can't just use prevHotKey[i]
    for i, name in hotkeyNames {
        IniRead, key, % settingsFile, HotKeys, % name, % defaultKeys[i]

        ; key := prevHotKey[i] ; Does seem to work

        custom := "Custom" . i               
        GuiControl, , % custom, % key
    }

    GuiControl, , offlineCheckAllowed, % offlineCheckAllowed

    GuiControl, Disable, CancelButton
    GuiControl, Disable, SaveButton
    GuiControl, Enable, DefaultButton
}

EnableSave() {
    global

    GuiControl, Enable, SaveButton
    GuiControl, Enable, DefaultButton
    GuiControl, Enable, CancelButton
}