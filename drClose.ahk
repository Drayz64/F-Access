﻿#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
SendMode Input ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir% ; Ensures a consistent starting directory.

#NoTrayIcon
#SingleInstance, force

DetectHiddenWindows, On
SetTitleMatchMode, 2

WinClose drHotKeys.ahk ahk_class AutoHotkey