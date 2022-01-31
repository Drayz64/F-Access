﻿; TODO:
; - Checkbox for magnifier showing on startup
; - checkbox for words typed being spoken
;
; - Fix issues with F3 and minimise/close/exit
; - Exit script when gui closed? (exit button needed?)
;
; - Handle Duplicate hotkeys
; - Restrict hotkeys 
;       - can't be the same as the hotkey to open settings (if I decide to use a hotkey to open settings)
;
; - Cancel button to revert unsaved changes (loading the saved settings - similar to startup???)
; - Default button (linked with default hotkeys)
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

; Retrieving saved settings
IniRead, offlineCheckAllowed, % settingsFile, Printing, OfflineCheck, True
IniRead, mute, % settingsFile, Voice, Mute, False

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

    ; Adding control buttons
    Gui, Add, Button, x0   w%buttonW% vSaveButton gSave, Save
    Gui, Add, Button, x+10 w%buttonW% vExitButton, Exit
    GuiControl, Disable, SaveButton
    
    Gui, Show, Hide ; Enabling the buttons to be centered
}


; Used to equally spread the 2 buttons
GuiSize(GuiHwnd, EventInfo, Width, Height) {
    if(centered) {
        Return
    }

    addPosX := (Width - buttonW) // 3

    GuiControl, Move, SaveButton, % "x" addPosX
    GuiControl, Move, ExitButton, % "x" addPosX+buttonW+10
    
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

        if (%custom% != "") {
            HotKey, % %custom%, % name, on
        }

        ; Still writes key to the file even if empty key
        IniWrite, % %custom%, % settingsFile, HotKeys, % name

        prevHotKey[i] := %custom%
    }

    IniWrite, % offlineCheckAllowed, % settingsFile, Printing, OfflineCheck
    IniWrite, % mute, % settingsFile, Voice, Mute

    GuiControl, Disable, SaveButton ; Providing feedback to the user
}

EnableSave() {
    GuiControl, Enable, SaveButton
}