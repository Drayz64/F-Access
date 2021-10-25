#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn ; Enable warnings to assist with detecting common errors.
SendMode Input ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir% ; Ensures a consistent starting directory.

;#NoTrayIcon
DetectHiddenWindows, On
SetTitleMatchMode, 2
#SingleInstance, force

Global voice := ComObjCreate("SAPI.SpVoice")

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

global scriptNames := ["drMagnifier.ahk", "drWordPad.ahk", "drInput.ahk", "drQueue.ahk", "drSpeaker.ahk"]
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
    if (WinExist("drMagnifier.exe ahk_class AutoHotkey")) {
        WinClose
    }
    else {
        Run, drMagnifier.exe ahk_class AutoHotkey
    }
Return

; Zoom in magnifier or zoom in general
NumpadAdd::
    if WinExist("drMagnifier.exe ahk_class AutoHotkey") {
        Send, !{F7}
    }
	else {
		Send, {CTRLDOWN}{WheelUp}{CTRLUP}
	}
Return

; Zoom out magnifier or zoom out general
NumpadSub::
    if WinExist("drMagnifier.exe ahk_class AutoHotkey") {
        Send, !{F8}
    }
	else {
		Send, {CTRLDOWN}{WheelDown}{CTRLUP}
	}
Return


; Restart all scripts
F12::
    WinClose, drMagnifier.ahk ahk_class AutoHotkey ; So the tray tip is visible

    WinKill, drWordPad.ahk ahk_class AutoHotkey ; So the scripts are killed even if sapi speaking
    WinKill, drSpeaker.ahk ahk_class AutoHotkey

    voice.Speak("Restarting scripts")
    sleep 2000
    startScripts()
Return

startScripts() {
    deleteFiles()

    for index, name in scriptNames {
        Run, % name 
    }

    voice.Speak("Scripts running")
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

; notifyUser(text, color:="") {
;     TrayTip, , %text%
;     SetTimer, HideTrayTip, -3000
; }
; Return

; HideTrayTip() {
;     TrayTip  ; Attempt to hide it the normal way.
;     if SubStr(A_OSVersion,1,3) = "10." {
;         Menu Tray, NoIcon
;         Sleep 200  ; It may be necessary to adjust this sleep.
;         Menu Tray, Icon
;     }
; }
; Return

closeScripts() {
    for index, name in scriptNames {
        WinKill, % name 
    }

    deleteFiles()
}