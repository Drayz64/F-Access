#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn ; Enable warnings to assist with detecting common errors.
SendMode Input ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir% ; Ensures a consistent starting directory.

#SingleInstance, Force
;#NoTrayIcon
;#Persistent ; Use to keep script active if there are no hotkeys/strings, OnMessage() or GUI

;-------------------------------------------------------------------------------
; *** Delete Reload on Save before deployment ***
;-------------------------------------------------------------------------------
; Auto Execute - Until return, exit, hotkey/string encountered
;-------------------------------------------------------------------------------

; TODO:
; - How to set up default hotkeys??? (F!, F2...)
; - Handle Duplicate hotkeys
; - Restrict hotkeys
; - Only save and update changed hotkeys?
;
; - Cancel button to revert unsaved changes (loading the saved settings - similar to startup???)
;
; - Add checkbox settings (in different tab?)
; - Exit script when gui closed? (exit button needed?)


hotkeyDescr := [ "Open new word pad document"
                ,"Open saved word pad document"
                ,"Stop/Start Dictation"
                ,"Read document outloud"
                ,"Print"
                ,"Save document"
                ,"Show/Hide Magnifier"
                ,"Toggle input speaker"                
                ,"Restart F-Access"
                ,"Enable/Disable printer offline check"]

hotkeyNames := [ "openDoc"
                ,"openSavedDoc"
                ,"toggleDictation"
                ,"readOutloud"
                ,"print"
                ,"saveDoc"
                ,"toggleMag"
                ,"toggleInputSpeaker"
                ,"restart"
                ,"toggleOfflineCheck"]
                

prevHotKey   := []
savedHotKeys := []

buttonW := 75
centered := False

; Retrieving the saved keys and creating hotkeys from them
for i, name in hotkeyNames {
    IniRead, key, projectSettings.ini, HotKeys, % name

    if (key != "ERROR") {
        HotKey, % key, % name, on
        prevHotKey[i] := key
    }

    ; Store the key
    savedHotKeys[i] := key
}

; Adding the descriptions for the hotkeys to the GUI
first := True
for each, descr in hotkeyDescr {
    if (first) {
        Gui, Add, Text, Section, % descr
        first := False
        continue
    }

    Gui, Add, Text, , % descr
}

; Adding the hotkey controls, populated with the current key combo
; Can't loop over savedHotKeys because it may not have the correct length
first := True
for i, name in hotkeyNames {
    if (first) {
        Gui, Add, Hotkey, vCustom%i% gEnableSaveButton ys, % savedHotKeys[i]
        first := False
        continue
    }

    Gui, Add, Hotkey, vCustom%i% gEnableSaveButton, % savedHotKeys[i]
}
    

; Buttons
Gui, Add, Button, x0 w%buttonW% vSaveButton, Save
Gui, Add, Button, x+10 w%buttonW% vExitButton, Exit

Gui, Show, Hide

;-------------------------------------------------------------------------------
; Auto Execute End
;-------------------------------------------------------------------------------

; Used to equally spread the 2 buttons
GuiSize:
    if (!centered) {
        addPosX := (A_GuiWidth - buttonW) // 3

        GuiControl, Move, SaveButton, % "x" addPosX
        GuiControl, Move, ExitButton, % "x" addPosX+buttonW+10
        ; Gui, Show, , % "Project Settings"
        centered := True
    }    
Return

; Updates all HotKeys and saves them to the ini file
ButtonSave:
    Gui, Submit, NoHide

    for i, name in hotkeyNames {
        prev := prevHotKey[i]
        custom := "Custom" . i

        ; Removing old hotkey
        if (prev != "") {
            HotKey, % prev, % name, off
        }
        
        ; Creating new hotkey & saving it
        if (%custom% != "") {
            HotKey, % %custom%, % name, on
            IniWrite, % %custom%, projectSettings.ini, HotKeys, % name
        }
        ; Delete hotkey
        else {
            IniDelete, projectSettings.ini, HotKeys, % name
        }

        prevHotKey[i] := %custom%
    }

    GuiControl, Disable, SaveButton ; Providing feedback to the user
Return

EnableSaveButton() {
    GuiControl, Enable, SaveButton
}