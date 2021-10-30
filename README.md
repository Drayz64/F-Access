# F-Access
A repository containing ahk scripts that remap the function keys and more to enable quick and easy use of wordpad - targeted at the visually impaired 

## Instructions & Information
- If you haven't downloaded [AutoHotKey](https://www.autohotkey.com/) then you can still run F-Access using the .exe scripts inside [compiledScripts](compiledScripts)
<br/>

- Keep all the .ahk (as well as the crosshair png) and .exe files together in the same folder
- Running __*drHotKeys*__ will run all the scripts
- Run __*drClose*__ to close all scripts or alternatively exit __*drHotKeys*__ from the taskbar
- The scripts __*drInput*__, __*drQueue*__ and __*drSpeak*__ are responsible for speaking out loud each word that is typed
- Use <kbd>Win + a</kbd> to toggle antialising for the magnifier
- Use <kbd>Win + f</kbd> to toggle the ability to resize the magnifier
  > If you resize the magnifier bigger then the border will appear strange, to fix just press F7 twice
- The file drMagnifierSettings.txt stores the zoom level, height and width of the magnifier as well as the toggle state of antialise

If you want the scripts to run upon startup then:
  - Open the startup folder using <kbd>Win + r</kbd> and enter `shell:StartUp`
  - Create a shortcut inside this folder to the location of __*drHotKeys*__


## HotKeys
F1 = Open __*new*__ wordpad document\
F2 = Open __*saved*__ wordpad document\
F3 = Toggle windows __*dictation*__ on and off\
F4 = __*Read*__ the contents of the open wordpad document __*out loud*__


F5 = Print (same as ctrl + p)\
F6 = Save (same as ctrl + s)\
F7 = Toggle __*magnifier*__ on and off\
F8 =


F9 =\
F10 =\
F11 =\
F12 = Restart all scripts


NumPad Add = Zoom magnifier in (if running) - otherwise normal zoom in\
NumPad Sub = Zoom magnifier out (if running) - otherwise normal zoom out

## Other
The base of the code for drMagnifier comes from this [script](https://autohotkey.com/board/topic/10660-screenmagnifier/)
