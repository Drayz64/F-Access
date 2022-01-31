inputHook := InputHook("V", "{Space}.{`,}{?}{!}{Enter}")
inputHook.OnEnd := Func("speakWord")
inputHook.Start()

speakWord(inputHook) {
    global voice, muteTyped

    if (inputHook.EndReason == "EndKey") {
        word := inputHook.Input
        
        if (word != "" and !muteTyped) {

            ; TODO - If voie busy speaking instead of sending to voice - concatenate into string and send that???

            voice.Speak(word, 1)
        }        
    }

    inputHook.Start()
}