#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir% ; Ensures a consistent starting directory.

#NoTrayIcon
#SingleInstance, force
#Persistent ; Required

; global so they can be used in functions
global speakerBusy := False
global queue := []
global speechFinishedFile := A_ScriptDir . "\speechFinished.txt"
global inputFile := A_ScriptDir . "\input.txt"
global lineNum := 1

detecthiddenwindows, on ; Allows the script to detect hidden windows (so can communicate with drSpeaker)

#Include WatchFolder.ahk

; Actions: 1 (added), 2 (removed), 3 (modified), 4 (renamed)

WatchFolder(A_ScriptDir, "HandleFileChanges", , 1 | 8)
; 1 = Notify about renaming, creating, or deleting a file
; 8 = Notify about any file-size change.

HandleFileChanges(folder, changes) { 
    For index, change in changes {

        if (change.Name = inputFile and change.Action = 3) { ; File modified when word typed
            getTypedWord()
        } 
        else if (change.Name = speechFinishedFile and change.Action = 1) { ; File created because speaker finished speaking
            sendWordsFromQueue()
        }
    }
}

getTypedWord() {
    FileReadLine, typedWord, %inputFile%, lineNum

    if (ErrorLevel = 1) {
        fixLineNum()
        return
    }

    lineNum++

    if (speakerBusy) {
        queue.Push(typedWord) ; Enqueue
        return
    }

    speakWord(typedWord)
}

fixLineNum() {
    Loop, Read, %inputFile%
    {
        totalLines := A_Index
    }

    lineNum := totalLines

    FileReadLine, missedWord, %inputFile%, lineNum
    speakWord(missedWord)
    lineNum++
}

speakWord(word) {
    controlsettext, edit1, %word%, speaker
    speakerBusy := True
}

; Whilst speaking other words may have been entered and then added to the queue
sendWordsFromQueue() {
    ; Creation used to detect speaker has finished so need to delete
    FileDelete, % speechFinishedFile

    head := queue.RemoveAt(1) ; Dequeue

    if (head != "") {
        speakWord(head)
        return
    }

    ; Queue empty, so want next word from input.txt be spoken instead of added to the queue
    speakerBusy := False 
}
