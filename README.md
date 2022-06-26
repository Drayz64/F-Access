# F-Access
Personalised function keys for better accessibility, specifically for using WordPad
    
## Features
1. A docked screen magnifier
    - Includes a frame around the mouse showing what will be magnified
    - Collision detection between the frame and the magnified window
    - <kbd>Win + f</kbd> toggles the ability to resize the magnifier
    - drMagSettings.ini (created by __*drMagnifier*__) contains saved magnifier settings
2. An input reader (reads each word typed out loud)
3. Remapped function keys ([HotKeys](#hotkeys))

https://user-images.githubusercontent.com/65258846/175790532-fd209e84-a9eb-4d5c-9fc9-1481ed07debd.mp4

<details>
    <summary>Screenshot of the settings GUI</summary>
    <p align="center">
        <img src="https://user-images.githubusercontent.com/65258846/175790533-3b41fcd8-16d5-4654-9c5f-b58eafaa6a6e.png" width=30% height=30%>
    </p>
</details>

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
F3 = __*Read*__ the contents of the open wordpad document __*out loud*__
F4 = Save (same as ctrl + s)\


F5 = Print (same as ctrl + p, enter)\
F6 = Toggle windows __*dictation*__ on and off\
F7 = Toggle __*magnifier*__ visibility\
F8 = Restart F-Access


F9 =\
F10 =\
F11 =\
F12 = Open settings GUI


#### Zooming:
NumPad Add = Zoom magnifier in (if running) - otherwise normal zoom in\
NumPad Sub = Zoom magnifier out (if running) - otherwise normal zoom out
> Alternatively use <kbd>Alt + F8</kbd> and <kbd>Alt + F7</kbd>

## Other

When F5 is pressed for printing it checks if the default printer is offline - if this is the case then the print is prevented. This doesn't work for all types of printers, therefore <kbd>Alt + F5</kbd> can be used to disable the offline printer check.
