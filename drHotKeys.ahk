#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
SendMode Input ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir% ; Ensures a consistent starting directory.

DetectHiddenWindows, On
SetTitleMatchMode, 2
#SingleInstance, force

OnExit, closeScripts

global VoiceTyped   := ComObjCreate("SAPI.SpVoice")
global VoiceCommand := ComObjCreate("SAPI.SpVoice")
VoiceCommand.Priority := 1 ; Alert priority

; Alternative fix is to loop through files in working dir and populate scriptNames with files starting in "dr"
global scriptNames := ["drMagnifier", "drWordPad"]

; Append each file name with the file extension of drHotKeys
SplitPath, A_ScriptName, , , extension
for index, fileName in scriptNames {
    scriptNames[index] := fileName "." extension
}
drMagnifier := % scriptNames[1]
drWordPad   := % scriptNames[2]

inputHook := InputHook("V", "{Space}.{`,}{?}{!}{Enter}")
inputHook.OnEnd := Func("speakWord")

#Include, settingsGUI.ahk
#Include, drInput.ahk
#Include, drWordPad.ahk

constructGUI()
startScripts()

if (!TypedMute) {
    inputHook.Start()
}

speak("F-Access Running", 1)

;-------------------------------------------------------------------------------
; Auto Execute End
Return
;-------------------------------------------------------------------------------

F12::
    if WinActive("Project Settings") {
        Gui, Hide
    }
    else {
        Gui, Show, , % "Project Settings"
    }
Return

print() {   
    defaultPrinter := getDefaultPrinter()

    if (defaultPrinter = False) {
        speak("Please set a default printer", 0)
        Return
    }

    printerName := StrSplit(defaultPrinter, A_Space) ; Incase of a long printer name

    if (printerOffline(defaultPrinter)) {
        speak("Unable to print, please turn on your " printerName[1] " printer", 1)
        Return
    }

    Send ^p
    Sleep 500
    Send {Enter}
    speak("Printing", 1)
}

getDefaultPrinter() {
    ; https://docs.microsoft.com/en-us/windows/win32/printdocs/getdefaultprinter

    if !(DllCall("winspool.drv\GetDefaultPrinter", "ptr",0, "uint*",size)) { ; Getting the required size for the buffer to hold the printer's name
        size := VarSetCapacity(printer, size*2, 0)

        if (DllCall("winspool.drv\GetDefaultPrinter", "str",printer, "uint*",size)) {
            Return printer
        }            
    }
    Return False
}

printerOffline(printerName) {
    global offlineCheckAllowed

    if (!offlineCheckAllowed) {
        return False
    }

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
        return True ; Printer offline
    }

    return False
}

toggleDictation() {
    Send, #h
}

toggleMag() {
    global drMagnifier

    if WinExist(drMagnifier "ahk_class AutoHotkey") {
        WinClose
        speak("Magnifier Closed", 3) ; TODO - Only purge if currently saying magnifier open?
    }
    else {
        Run, %drMagnifier% "ahk_class AutoHotkey"
        speak("Magnifier Open", 3)
    }
}

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

restart:
    ; Close scripts that use sapi speak() before restarting
    ; as restarting won't work if speak() is speaking
    WinClose, % drWordPad "ahk_class AutoHotkey"

    speak("Restarting", 3) ; Asynchronous | PurgeBeforeSpeach
    VoiceCommand.WaitUntilDone(-1)
    Reload
Return

speak(sentence, flag := 0) {
    global CommandMute

    if (CommandMute) {
        return
    }

    VoiceCommand.Speak(sentence, flag)
}

startScripts() {
    global magStartup

    for index, name in scriptNames {
        if (index == 1 and !magStartup) {
            continue
        }
        Run, %name% "ahk_class AutoHotkey"
    }
}

closeScripts:
    for index, name in scriptNames {
        WinClose, % name "ahk_class AutoHotkey"
    }
ExitApp