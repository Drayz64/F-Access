# F-Access
A repository containing ahk scripts that remap the function keys and more to enable quick and easy use of wordpad - targeted at the visually impaired 

## Instructions & Information
- If you haven't downloaded [AutoHotKey](https://www.autohotkey.com/) then you can still run F-Access using the .exe scripts inside [compiledScripts](compiledScripts)
<br/>

- Keep all the .ahk scripts together in the same folder (same for the .exe compiled scripts)
- Run __*drHotKeys*__ to start F-Access
- Run __*drClose*__ to close F-Access or alternatively exit __*drHotKeys*__ from the taskbar
- __*drInput*__ is responsible for speaking out loud each word that is typed
- Use <kbd>Win + f</kbd> to toggle the ability to resize the magnifier
- The file drMagSettings.ini stores the zoom level and the height & width of the magnifier

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
F7 = Toggle __*magnifier*__ visibility\
F8 = Toggle __*input speaker*__ running


F9 =\
F10 =\
F11 =\
F12 = Restart all scripts


NumPad Add = Zoom magnifier in (if running) - otherwise normal zoom in\
NumPad Sub = Zoom magnifier out (if running) - otherwise normal zoom out

## Other
The base of the code for drMagnifier comes from this [script](https://autohotkey.com/board/topic/10660-screenmagnifier/)
