
; TODO - Allow user to change the default dir where saved files are opened from?
EnvGet, homeDir, USERPROFILE
dir := homeDir . "\Documents"

openNewDoc() {
    Run wordpad.exe

    WinWait Document - WordPad ahk_exe WORDPAD.EXE, , 3

    if !ErrorLevel {
        Sleep 100 ; Incase there is already a blank document open
        WinMaximize
        zoom()
    }
}

openSavedDoc() {
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
}

zoom() {
    Click, %A_CaretX%, %A_CaretY%
    Loop, 8 {
        Send, {CtrlDown}{WheelUp}{CtrlUp}
    }
    sleep 50
    MouseMove, A_CaretX+20, A_CaretY+20, 0
}

readDoc() {
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
            VoiceTyped.Speak(lines[A_Index + ignoreLines], 1)
        }            
    }
}

saveDoc() {
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
}

ObjIndexOf(obj, item, case_sensitive := false) {
	for i, val in obj {
		if (case_sensitive ? (val == item) : (val = item))
			return i
	}
}