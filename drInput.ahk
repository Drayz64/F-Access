sentence := ""

speakWord(inputHook) {
    global muteTyped, sentence

    reason := inputHook.EndReason

    if (reason == "EndKey") {
        
        key := inputHook.EndKey ; TODO - Manually convert key to character???

        sentence .= inputHook.Input . " "

        if (sentence != "" and !muteTyped) { ; TODO - !muteTyped not needed now?

            if (VoiceTyped.Status.RunningState == 2) {
                if (!checking) {
                    checkVoiceAvailable()
                    checking := True
                }
            }
            else {
                VoiceTyped.Speak(sentence, 1)
                sentence = ""
            }
        }
    }
    else if (reason == "Stopped") {
        ; muteTyped = True
        Return
    }

    inputHook.Start() ; Capture the next word that is typed
}


checkVoiceAvailable() {
    global sentence

    if (VoiceTyped.Status.RunningState == 2) {
        SetTimer, checkVoiceAvailable, -100
    }
    else {
        SetTimer, checkVoiceAvailable, Off
        VoiceTyped.Speak(sentence, 1)
        sentence = ""
    }
}



; speakWord(inputHook) {
;     global voice, muteTyped

;     reason := inputHook.EndReason

;     if (reason == "EndKey") {

;         word := inputHook.Input

;         if (word != "" and !muteTyped) {
;             voice.Speak(word, 1)
;         }        
;     }
;     else if (reason == "Stopped") {
;         ; muteTyped = True
;         Return
;     }

;     inputHook.Start() ; Capture the next word that is typed
; }