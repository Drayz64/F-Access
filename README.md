# F-Access
Personalised function keys for better accessibility, specifically for using WordPad


https://user-images.githubusercontent.com/65258846/175720332-499a5718-b280-4a63-84c4-68e4c97c5652.mp4


## Features
1. A docked screen magnifier
    - Includes a frame around the mouse showing what will be magnified
    - Collision detection between the frame and the magnified window
    - <kbd>Win + f</kbd> toggles the ability to resize the magnifier
    - drMagSettings.ini (created by __*drMagnifier*__) contains saved magnifier settings
2. An input reader (reads each word typed out loud)
3. Remapped function keys ([HotKeys](#hotkeys))

## Instructions
- If you haven't downloaded [AutoHotKey](https://www.autohotkey.com/) then you can still run F-Access using the executable scripts inside [releases](https://github.com/Drayz64/F-Access/releases)
<br/>

- Keep all the .ahk scripts together in the same folder (same for the .exe compiled scripts)
- Run __*drHotKeys*__ to start F-Access
- Run __*drClose*__ to close F-Access or alternatively exit __*drHotKeys*__ from the taskbar

If you want the scripts to run upon startup then:
  - Open the startup folder using <kbd>Win + r</kbd> and enter `shell:StartUp`
  - Create a shortcut inside this folder to the location of __*drHotKeys*__

## HotKeys
F1 = Open __*new*__ wordpad document\
F2 = Open __*saved*__ wordpad document\
F3 = Toggle windows __*dictation*__ on and off\
F4 = __*Read*__ the contents of the open wordpad document __*out loud*__


F5 = Print (same as ctrl + p, enter)\
F6 = Save (same as ctrl + s)\
F7 = Toggle __*magnifier*__ visibility\
F8 = Toggle __*input reader*__ running


F9 =\
F10 =\
F11 =\
F12 = Restart all scripts


NumPad Add = Zoom magnifier in (if running) - otherwise normal zoom in\
NumPad Sub = Zoom magnifier out (if running) - otherwise normal zoom out

## Other

When F5 is pressed for printing it checks if the default printer is offline - if this is the case then the print is prevented. This doesn't work for all types of printers, therefore <kbd>Alt + F5</kbd> can be used to disable the offline printer check.
