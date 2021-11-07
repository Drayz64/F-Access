#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn ; Enable warnings to assist with detecting common errors.
SendMode Input ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir% ; Ensures a consistent starting directory.

;#NoTrayIcon
DetectHiddenWindows, On
SetTitleMatchMode, 2
#SingleInstance, force

;-------------------------------------------------------------------------------
; Auto Execute - Until return, exit, hotkey/string encountered
;-------------------------------------------------------------------------------
SysGet, workArea, MonitorWorkArea
screenWidth  := workAreaRight
screenHeight := workAreaBottom

OnExit("closeScripts")

voice := ComObjCreate("SAPI.SpVoice")

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
voice.Speak("Successfully started", 1)

;-------------------------------------------------------------------------------
; Auto Execute End
Return
;-------------------------------------------------------------------------------

; (F1 = Open new doc)     (F2 = Open saved doc)     F3 = Dictation     (F4 = Read word doc)   /   F5 = Print     F6 = Save     F7 = Magnifier     F8 = Input speaker

; Dictation
F3::Send, #h

; Print
F5::
    if(printerOffline()) {
        voice.speak("Unable to print, please turn on your printer", 1)
        Return
    }

    Send ^p
    Sleep 500
    Send {Enter}
    voice.speak("Printing", 1)
Return

printerOffline() {
    defaultPrinter := getDefaultPrinter()
    RegRead, printerStatus, HKLM\System\CurrentControlSet\Control\Print\Printers\%defaultPrinter%, Status

    ; PRINTER_STATUS_OFFLINE   = 0x80  -> The printer is offline.
    ; PRINTER_STATUS_IO_ACTIVE = 0x100 -> The printer is in an active input or output state.

    ; 0x180 -> 384

    if (printerStatus = 384) {
        return True ; Printer offline
    }

    return False
}

getDefaultPrinter() {
    if !(DllCall("winspool.drv\GetDefaultPrinter", "ptr", 0, "uint*", size)) {
        size := VarSetCapacity(buf, size << 1, 0)

        if (DllCall("winspool.drv\GetDefaultPrinter", "str", buf, "uint*", size))
            return buf
    }
    return false
}

; Save
F6::
    if (WinActive("ahk_exe WORDPAD.EXE")) {
        Send ^s
        sleep 50
        WinWait, Save As ahk_exe wordpad.exe,,0

        ; Pop Up confirmation message
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

; Toggle Magnifier
F7::
    if WinExist(drMagnifier "ahk_class AutoHotkey") {
        WinClose
        voice.speak("Magnifier Closed", 1)
    }
    else {
        Run, %drMagnifier% "ahk_class AutoHotkey"
        voice.speak("Magnifier Open", 1)
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
        voice.speak("Input speaker closed", 1)
    }
    else {
        Run, %drInput% "ahk_class AutoHotkey"
        voice.speak("Input speaker running", 1)
    }
Return

; Restart all scripts
F12::
    ; Close the 2 scripts that use sapi speak() before restarting
    ; as restarting won't work if speak() is speaking
    WinClose, % drWordPad "ahk_class AutoHotkey"
    WinClose, % drInput   "ahk_class AutoHotkey"

    voice.Speak("Restarting")
    startScripts()
    voice.Speak("Successfully restarted", 1) ; 1 => Asynchronous speech
Return

startScripts() {
    for index, name in scriptNames {
        Run, %name% "ahk_class AutoHotkey"
    }
}

closeScripts() {
    for index, name in scriptNames {
        WinClose, % name "ahk_class AutoHotkey"
    }
}