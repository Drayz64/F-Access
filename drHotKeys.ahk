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

global inputFile := "input.txt"
global speechFinishedFile := "speechFinished.txt"
deleteFiles()

global voice := ComObjCreate("SAPI.SpVoice")

; Alternative fix is to loop through files in working dir and populate scriptNames with files starting in "dr"
global scriptNames := ["drMagnifier", "drWordPad", "drInput", "drQueue", "drSpeaker"]

; Append each file name with the file extension of drHotKeys
SplitPath, A_ScriptName, , , extension
for index, fileName in scriptNames {
    scriptNames[index] := fileName "." extension
}
drMagnifier := % scriptNames[1]

startScripts()

;-------------------------------------------------------------------------------
; Auto Execute End
Return
;-------------------------------------------------------------------------------

; (F1 = Open new doc)     (F2 = Open saved doc)     F3 = Dictation     (F4 = Read word doc)   /   F5 = Print     F6 = Save     F7 = Magnifier     F8 =

; Dictation
F3::Send, #h

; Print
F5::
    Send ^p
    Sleep 500
    Send {Enter}
Return

; Save
F6::
    if (WinActive("ahk_exe WORDPAD.EXE")) {
        Send ^s
        sleep 50
        WinWait, Save As ahk_exe wordpad.exe,,0

        if ErrorLevel {
            Gui, Font, s40
            Gui, Color, EEAA99 ; Pink/Orange background
            Gui, Add, Text,, Saved!
            Gui, -Caption +AlwaysOnTop +ToolWindow +Border
            Gui, Show, , saved
            sleep 1000
            Gui, Destroy
        }

        ; if !ErrorLevel {
        ;     Gui, Font, s40
        ;     Gui, Color, EEAA99 ; Pink/Orange background
        ;     Gui, Add, Text,, Save file as:
        ;     Gui, Add, Button, w1 h1 hidden default, Ok ; hidden button
        ;     Gui, Font, s35
        ;     Gui, Add, Edit, vInput
        ;     Gui, -Caption +AlwaysOnTop +ToolWindow +Border
        ;     Gui, Show, % "w" screenWidth "h" screenHeight, saveFileAs
        ; }
        ; else {
        ;     Gui, Font, s40
        ;     Gui, Color, EEAA99 ; Pink/Orange background
        ;     Gui, Add, Text,, Saved!
        ;     Gui, -Caption +AlwaysOnTop +ToolWindow +Border
        ;     Gui, Show, , saved
        ;     sleep 1000
        ;     Gui, Destroy
        ; }
    }
Return

; ButtonOk:
;     Gui, Submit
;     Gui, Destroy

;     clipContent := Clipboard

;     ; Test if file name already exists?
;     Clipboard := Input
;     Send ^v
;     sleep 50
;     Send {Enter}

;     Clipboard := clipContent
; Return

; Start/Stop Magnifier
F7::
    if (WinExist(drMagnifier "ahk_class AutoHotkey")) {
        WinClose
    }
    else {
        Run, %drMagnifier% "ahk_class AutoHotkey"
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


; Restart all scripts
F12::
    ; Kill drWordPad and drSpeaker - the 2 scripts that use sapi speak()
    ; as they won't be restarted using run if speak() is speaking
    WinKill, % scriptNames[2] "ahk_class AutoHotkey"
    WinKill, % scriptNames[5] "ahk_class AutoHotkey"

    voice.Speak("Restarting scripts", 1) ; 1 => Asynchronous speech
    sleep 2000
    startScripts()
Return

startScripts() {
    deleteFiles()

    for index, name in scriptNames {
        Run, % name 
    }

    voice.Speak("Scripts running", 1)
}

deleteFiles() {
    if FileExist(inputFile) {
        FileDelete, % inputFile
    }
    
    if FileExist(speechFinishedFile) {
        FileDelete, % speechFinishedFile
    }
}
Return

closeScripts() {
    for index, name in scriptNames {
        WinKill, % name 
    }

    deleteFiles()
}

;-------------------------------------------------------------------------------
; Reload on Save
;-------------------------------------------------------------------------------
~^s::
    Sleep 200
    WinGetActiveTitle, activeTitle
    activeTitle := StrReplace(activeTitle, " - Visual Studio Code")

    if (activeTitle = A_ScriptName) {
        ToolTip, %A_ScriptName%, 1770, 959
        sleep 800
        ToolTip
        Reload
    }
return