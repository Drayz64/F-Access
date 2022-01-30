#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
SendMode Input ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir% ; Ensures a consistent starting directory.

DetectHiddenWindows, On
SetTitleMatchMode, 2
#SingleInstance, force

;-------------------------------------------------------------------------------
; Auto Execute - Until return, exit, hotkey/string encountered
;-------------------------------------------------------------------------------

OnExit, closeScripts

global voice := ComObjCreate("SAPI.SpVoice")
global mute  := True

; Alternative fix is to loop through files in working dir and populate scriptNames with files starting in "dr"
global scriptNames := ["drMagnifier", "drWordPad", "drInput"]

; Append each file name with the file extension of drHotKeys
SplitPath, A_ScriptName, , , extension
for index, fileName in scriptNames {
    scriptNames[index] := fileName "." extension
}
drMagnifier := % scriptNames[1]
drWordPad   := % scriptNames[2]
drInput     := % scriptNames[3]

startScripts()
speak("F-Access Running", 1)

visible := False

;TODO - handle .exe and .ahk
#Include, settingsGUI.ahk 

;-------------------------------------------------------------------------------
; Auto Execute End
Return
;-------------------------------------------------------------------------------

F3::
    if (visible) {
        Gui, Hide
    }
    else {
        Gui, Show, , % "Project Settings"
    }

    visible := !visible
Return

; (F1 = Open new doc)     (F2 = Open saved doc)     F3 = Dictation     (F4 = Read word doc)   /   F5 = Print     F6 = Save     F7 = Magnifier     F8 = Input speaker

toggleDictation:
    Send, #h
Return

print:
    defaultPrinter := getDefaultPrinter()

    if (defaultPrinter = False) {
        speak("Unable to find your default printer", 0)
        Return
    }

    printerName := StrSplit(defaultPrinter, A_Space) ; Incase of a long printer name

    if (offlineCheckAllowed and printerOffline(defaultPrinter)) {
        speak("Unable to print, please turn on your " printerName[1] " printer", 1)
        Return
    }

    Send ^p
    Sleep 500
    Send {Enter}
    speak("Printing", 1)
Return

getDefaultPrinter() {
    if !(DllCall("winspool.drv\GetDefaultPrinter", "ptr", 0, "uint*", size)) { ; Getting the required size for the buffer to hold the printer's name
        size := VarSetCapacity(printer, size*2, 0)

        if (DllCall("winspool.drv\GetDefaultPrinter", "str", printer, "uint*", size))
            Return printer
    }
    Return False
}

printerOffline(printerName) {
    RegRead, printerAttributes, HKLM\System\CurrentControlSet\Control\Print\Printers\%printerName%, Attributes

    ; *Status flags method*
    ; PRINTER_STATUS_OFFLINE   = 0x80  -> The printer is offline.
    ; PRINTER_STATUS_IO_ACTIVE = 0x100 -> The printer is in an active input or output state.
    ;                          = 0x180 (384 decimal)

    ; *PrintUI dll method*
    ; rundll32.exe printui.dll PrintUIEntry /Xg /n "EPSON91D7A1 (ET-2600 Series)" /f "printerSettings.txt" /q

    ; *Attributes flags method*
    ; PRINTER_ATTRIBUTE_DO_COMPLETE_FIRST = 0x200
    ; PRINTER_ATTRIBUTE_ENABLE_BIDI       = 0x800
    ; PRINTER_ATTRIBUTE_WORK_OFFLINE      = 0x400
    ;                                     = 0xe00 (3584 decimal)

    ; msgbox % Format("0x{:X}", printerAttributes)

    if (printerAttributes = 3584) {
        Return True ; Printer offline
    }

    return False
}

; toggleOfflineCheck:
;     offlineCheckAllowed := !offlineCheckAllowed

;     str := "Disabled"
;     if (offlineCheckAllowed)
;         str := "Enabled"
    
;     speak(str " offline printer check", 1)
; Return


saveDoc:
    if (WinActive("ahk_exe WORDPAD.EXE")) {
        Send ^s
        sleep 50
        WinWait, Save As ahk_exe wordpad.exe,,0

        ; Pop Up confirmation message for a regular save
        if ErrorLevel {
            Gui, Font, s40
            Gui, Color, EEAA99 ; Pink/Orange background
            Gui, Add, Text,, Saved!
            Gui, -Caption +AlwaysOnTop +ToolWindow +Border
            Gui, Show, , saved
            sleep 1000
            Gui, Destroy
        }
    }
Return


toggleMag:
    if WinExist(drMagnifier "ahk_class AutoHotkey") {
        WinClose
        speak("Magnifier Closed", 1)
    }
    else {
        Run, %drMagnifier% "ahk_class AutoHotkey"
        speak("Magnifier Open", 1)
    }
Return

; Zoom in magnifier or zoom in general
NumpadAdd::
    if WinExist(drMagnifier "ahk_class AutoHotkey") {
        Send, !{F7}
    }
	else {
		Send, {CTRLDOWN}{WheelUp}{CTRLUP}
	}
Return

; Zoom out magnifier or zoom out general
NumpadSub::
    if WinExist(drMagnifier "ahk_class AutoHotkey") {
        Send, !{F8}
    }
	else {
		Send, {CTRLDOWN}{WheelDown}{CTRLUP}
	}
Return

; Toggle input speaker
F8::
    if WinExist(drInput "ahk_class AutoHotkey") {
        WinKill
        speak("Input speaker closed", 1)
    }
    else {
        Run, %drInput% "ahk_class AutoHotkey"
        speak("Input speaker running", 1)
    }
Return


restart:
    ; Close the 2 scripts that use sapi speak() before restarting
    ; as restarting won't work if speak() is speaking
    WinClose, % drWordPad "ahk_class AutoHotkey"
    WinClose, % drInput   "ahk_class AutoHotkey"

    speak("Restarting", 3) ; Asynchronous | PurgeBeforeSpeach
    voice.WaitUntilDone(-1)
    Reload
Return

speak(sentence, flag := 0) {
    if (mute) {
        return
    }

    voice.Speak(sentence, flag)
}

startScripts() {
    for index, name in scriptNames {
        Run, %name% "ahk_class AutoHotkey"
    }
}

closeScripts:
    for index, name in scriptNames {
        WinClose, % name "ahk_class AutoHotkey"
    }

    IniWrite, % offlineCheckAllowed, % settingsFile, Printing, OfflineCheck
ExitApp