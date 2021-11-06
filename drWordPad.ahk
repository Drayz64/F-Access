#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

#NoTrayIcon
#SingleInstance, force
DetectHiddenText, Off

DetectHiddenWindows, On
SetTitleMatchMode, 2

voice := ComObjCreate("SAPI.SpVoice")
voice.Volume := 100
voice.Rate := 2

EnvGet, homeDir, USERPROFILE
dir := homeDir . "\Documents"

; Open blank wordpad document
F1::
    Run wordpad.exe

    WinWait Document - WordPad ahk_exe WORDPAD.EXE, , 3

    if !ErrorLevel {
        Sleep 100 ; Incase multiple new documents are opened
        WinMaximize
        zoom()
    }
return

; Open file in wordpad
F2::
    FileSelectFile, path, , % dir, Select Document, All Wordpad Documents (*.rtf; *.docx; *.odt; *.txt)

    if (path = "") {
        return
    }

    try {
        Run wordpad.exe %path%
    }
    catch {
        return
    }

    SplitPath, path, fileName

    WinWait %fileName% - WordPad ahk_exe WORDPAD.EXE, , 3

    if !ErrorLevel {
        WinMaximize
        zoom()
    }
return

zoom() {
    Click, %A_CaretX%, %A_CaretY%
    Loop, 8 {
        Send, {CtrlDown}{WheelUp}{CtrlUp}
    }
    sleep 50
    MouseMove, A_CaretX+20, A_CaretY+20, 0
}
Return

; Reads text in currently open wordpad file
F4::
    If WinActive("ahk_exe WORDPAD.EXE") {
        WinGetText, text

        lines := StrSplit(text, "`n", "`r") ; Because each element in text ends with CR+LF (`r`n)

        if InStr(text, "%`r`n-`r`n`+`r`n") { ; 180% - +
            index := ObjIndexOf(lines, "+")
            ignoreLines := index
        }
        else {
            ignoreLines := 3 ; Skip the first 3 ribbon lines
        }

        Loop % lines.MaxIndex() - ignoreLines {
            voice.Speak(lines[A_Index + ignoreLines], 1)
        }            
    }
Return

ObjIndexOf(obj, item, case_sensitive := false) {
	for i, val in obj {
		if (case_sensitive ? (val == item) : (val = item))
			return i
	}
}
Return