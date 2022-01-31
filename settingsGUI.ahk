; TODO:
; - Checkbox for magnifier showing on startup
; - checkbox for words typed being spoken
;
; - Fix issues with F3 and minimise/close/exit
; - Exit script when gui closed? (exit button needed?)
;
; - Handle duplicate hotkeys???
; - Prevent hotkeys being the same as the hotkey to open settings (if I decide to use a hotkey to open settings)
;
; - voice rate, volume and voice in the GUI
;
; - Migrate or include drWordPad - enabling those hotkeys to be customised
;
; - Can it handle new settings being added postlaunch when users have an exisitng settingsFile?


; hotkeyDescr := [ "Open new word pad document"
;                 ,"Open saved word pad document"
;                 ,"Stop/Start Dictation"
;                 ,"Read document outloud"
;                 ,"Print"
;                 ,"Save document"
;                 ,"Show/Hide Magnifier"
;                 ,"Toggle input speaker"                
;                 ,"Restart F-Access"
;                 ,"Enable/Disable printer offline check"]

; hotkeyNames := [ "openDoc"
;                 ,"openSavedDoc"
;                 ,"toggleDictation"
;                 ,"readOutloud"
;                 ,"print"
;                 ,"saveDoc"
;                 ,"toggleMag"
;                 ,"toggleInputSpeaker"
;                 ,"restart"
;                 ,"toggleOfflineCheck"]

; defaultKeys := ["F1", "F2"]

global hotkeyDescr := ["Stop/Start Dictation"
                      ,"Print"
                      ,"Save document"
                      ,"Show/Hide Magnifier"              
                      ,"Restart F-Access"]

global hotkeyNames := [ "toggleDictation"
                       ,"print"
                       ,"saveDoc"
                       ,"toggleMag"
                       ,"restart"]

defaultKeys := ["F4", "F5", "F6", "F7", "F8", "F9"]

global prevHotKey := []

global buttonW := 75
global centered := False

settingsFile := "projectSettings.ini"

; TODO - Place this inside a function as well?

; Retrieving saved settings
IniRead, offlineCheckAllowed, % settingsFile, Printing, OfflineCheck, True
IniRead, mute, % settingsFile, Voice, Mute, False
IniRead, muteTyped, % settingsFile, Voice, MuteTyped, False

; The saved keys are retrieved in the order of the names in hotkeyNames
for i, name in hotkeyNames {
    IniRead, key, % settingsFile, HotKeys, % name, % defaultKeys[i]

    if (key != "") {
        HotKey, % key, % name, on
    }

    prevHotKey[i] := key
}


constructGUI() {
    global

    ; Gui, +ToolWindow

    ; Adding the customisable hotkeys to the GUI
    for i, descr in hotkeyDescr {
        Gui, Add, Text, w200 xm, % descr
        Gui, Add, Hotkey, vCustom%i% gEnableSave x+10, % prevHotKey[i] ; Displays the current key combo (stored in prevHotKey)
    }

    ; Adding checkboxes
    Gui, Add, CheckBox, vofflineCheckAllowed gEnableSave Checked%offlineCheckAllowed% xm, % "Enable printer offline check?"
    Gui, Add, CheckBox, vmute gEnableSave Checked%mute% xm, % "Mute commands being spoken?"
    Gui, Add, CheckBox, vmuteTyped gEnableSave Checked%muteTyped% xm, % "Mute typed words being spoken?"

    ; Adding control buttons
    Gui, Add, Button, xm w%buttonW% vDefaultButton gDefault, % "Default"
    Gui, Add, Button, x+10 w%buttonW% vCancelButton gCancel, Cancel
    Gui, Add, Button, x+10 w%buttonW% vSaveButton gSave, Save
    Gui, Add, Button, x+10 w%buttonW% vExitButton, Exit
    GuiControl, Disable, SaveButton
    GuiControl, Disable, CancelButton
    
    Gui, Show, Hide ; Enabling the buttons to be centered
}


; Used to equally spread the 2 buttons
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

; Updates all HotKeys and saves them to the ini file
Save() {
    global

    Gui, Submit, NoHide

    ; TODO - Save unchanged hotkeys? if prev = custom then continue?

    for i, name in hotkeyNames {
        prev := prevHotKey[i]
        custom := "Custom" . i

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

    IniWrite, % offlineCheckAllowed, % settingsFile, Printing, OfflineCheck
    IniWrite, % mute, % settingsFile, Voice, Mute
    IniWrite, % muteTyped, % settingsFile, Voice, MuteTyped

    GuiControl, Disable, SaveButton ; Providing feedback to the user
    GuiControl, Disable, CancelButton
}

Default() {
    global

    ; TODO - Shouldn't be enabled if checkboxes change, because that doesn' affect default???

    for i, key in defaultKeys {
        ; Using custom just as a ControlID
        custom := "Custom" . i               
        GuiControl, , % custom, % key
    }

    GuiControl, Disable, DefaultButton
    GuiControl, Enable, SaveButton
    GuiControl, Enable, CancelButton
}

Cancel() {
    global

    ; Load *all* saved settings into the GUI

    ; Have a saved array of settings? So don't have to keep reading the .ini
    ; Then only write the array to the .ini file on exit of the GUI?

    ; Sadly can't just use prevHotKey[i]
    for i, name in hotkeyNames {
        IniRead, key, % settingsFile, HotKeys, % name, % defaultKeys[i]

        custom := "Custom" . i               
        GuiControl, , % custom, % key
    }

    GuiControl, , offlineCheckAllowed, % offlineCheckAllowed
    GuiControl, , mute, % mute
    GuiControl, , muteTyped, % muteTyped

    GuiControl, Disable, CancelButton
    GuiControl, Disable, SaveButton
    GuiControl, Enable, DefaultButton
}

EnableSave() {
    GuiControl, Enable, SaveButton
    GuiControl, Enable, DefaultButton
    GuiControl, Enable, CancelButton
}