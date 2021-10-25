#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir% ; Ensures a consistent starting directory.

#NoTrayIcon
#SingleInstance, force
; Persistent not needed because there is gui code

voice := ComObjCreate("SAPI.SpVoice")
voice.Volume := 100
voice.Rate := 2

;voice.Voice := voice.GetVoices().Item(2)

; For T In voice.GetVoices
;     msgbox % T.GetDescription

filePath := "speechFinished.txt"

gui, add, edit, w50 h20 vword gspeak ; Lines 1 and 2 create a hidden gui with an edit control.
gui, show, hide, speaker
return

speak:
    gui, submit
    voice.Speak(word)
    FileAppend, , %filePath% ; Create a text file to tell input_queue to send the next word
return