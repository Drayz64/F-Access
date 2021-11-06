#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir% ; Ensures a consistent starting directory.

#NoTrayIcon
#SingleInstance, force
; Persistent not required because infinite loop

voice := ComObjCreate("SAPI.SpVoice")
; voice.Volume := 100
voice.Rate := 1
lngHandle := voice.SpeakCompleteEvent()

Loop {
	Input, word, V, {Space}.{`,}{?}{!}{Enter}, ; V = visible (user input not blocked), word finished with space, fullstop, comma etc.

    if (InStr(ErrorLevel, "EndKey:")) {

        if (word = "") {
            continue
        }

        voice.Speak(word, 1) ; 1 = Asynchronous -> If word still being spoken then adds word to TTS's input queue
    }
}