#NoEnv
#SingleInstance, force
SetBatchLines -1 ; Script runs at max speed
SetWinDelay, 0   ; Default delay of 100ms for win__ commands
#NoTrayIcon

;-------------------------------------------------------------------------------
; Auto Execute - Until return, exit, hotkey/string encountered
;-------------------------------------------------------------------------------

; Creates crosshair png inside ./compiledScripts when this file is compiled
SplitPath, A_ScriptName, , , extension
if (extension = "exe") {
    FileInstall, Yellow3CrossHair.png, ./compiledScripts/crossHair.png, 1
}

CoordMode Mouse, Screen

; --- Prevents magnifier from obscurring taskbar ---
SysGet, workArea, MonitorWorkArea
global screenWidth  := workAreaRight
global screenHeight := workAreaBottom

; --- Retrieving saved settings ---
Settings := []
Loop, Read, drMagnifierSettings.txt
{
    Settings.Insert(A_LoopReadLine)
}

global zoom      := Settings[1]
global guiWidth  := Settings[2]
global guiHeight := Settings[3]
global antialize := Settings[4]

checkVariables()

FileDelete, drMagnifierSettings.txt
OnExit("saveSettings")

; --- Setting variables ---
frameWidth  := guiWidth  / zoom
frameHeight := guiHeight / zoom

global counter := 20
global atTopLeft := False
resizingAllowed  := False

; ; --- Magnified image in bottom left or top right ---
; Gui 2:+AlwaysOnTop -Caption +ToolWindow +Border -DPIScale
; Gui 2:Show, % "NoActivate" "w" guiWidth "h" guiHeight "x" screenWidth - guiWidth - 2 "y" screenHeight - guiHeight - 2, Magnifier
; WinGet MagnifierID, id, Magnifier
; WinSet Transparent, 255, Magnifier ; makes the window invisible to magnification
; WinGet PrintSourceID, ID

; --- Magnified image in bottom left or top right with frame ---
BorderThickness := 3, BorderColor:="eb4034"

Gui 2:+AlwaysOnTop -Caption +ToolWindow -DPIScale
Gui 2:Margin, % BorderThickness, % BorderThickness
Gui 2:Color, % BorderColor

width := guiWidth - (BorderThickness*2)
height := guiHeight - (BorderThickness*2)

Gui 2:Add, Text, vMagBorder w%width% h%height% 0x6, ; Draw a white static control
; Gui 2:Show, % "NoActivate" "x" screenWidth - guiWidth "y" screenHeight - guiHeight, Magnifier
Gui 2:Show, % "NoActivate" "w" guiWidth "h" guiHeight "x" screenWidth - guiWidth "y" screenHeight - guiHeight, Magnifier
WinGet MagnifierID, id, Magnifier
WinGet PrintSourceID, ID
WinSet Transparent, 255, Magnifier ; makes the window invisible to magnification
; WinSet, TransColor, FFFFFF, Magnifier ; This makes white areas in the magnified area see through


; --- CrossHair in Magnified Window ---
; Gui 3:-Caption +ToolWindow +AlwaysOnTop +E0x20
Gui 3:-Caption +ToolWindow
Gui 3:margin, 0, 0
GUI 3:Color, ffffff
Gui 3:Add, Picture, AltSubmit BackgroundTrans, Yellow3CrossHair.png
picMid := 13
Gui 3:Show, % "NoActivate", crossHair
WinSet, TransColor, ffffff, crossHair

; --- Frame around the mouse ---
BorderThickness := 3, BorderColor:="d9a518"

Gui +AlwaysOnTop -Caption +ToolWindow -DPIScale +E0x20 ; +0x800000 ; same as +border
Gui, Margin, % BorderThickness, % BorderThickness
Gui, Color, % BorderColor

width := frameWidth - (BorderThickness*2)
height := frameHeight - (BorderThickness*2)

Gui, Add, Text, vframeBorder w%width% h%height% 0x6, ; Draw a white static control
Gui Show, % "NoActivate", Frame
WinSet, TransColor, FFFFFF, Frame ; Use lastfound so this line can be done before showing?


hdcSrc  := DllCall("GetDC", UInt, PrintSourceID)
hdcDest := DllCall("GetDC", UInt, MagnifierID)
DllCall("gdi32.dll\SetStretchBltMode", "uint", hdcDest, "int", 4*antialize)
; https://docs.microsoft.com/en-us/windows/win32/api/wingdi/nf-wingdi-setstretchbltmode

Repaint:
    MouseGetPos x, y

    ; Prevents the frame from going off screen
    frameX := In(x - (frameWidth /2),  0, A_ScreenWidth  - frameWidth ) 
    frameY := In(y - (frameHeight/2), -1, A_ScreenHeight - frameHeight) ; TODO Not sure why -1 is neccessary


    ; Moving frame with the mouse
    GuiControl, Move, frameBorder, % "w" frameWidth - (2*BorderThickness) "h" frameHeight - (2*BorderThickness)
    WinMove Frame,, % frameX, % frameY, % frameWidth, % frameHeight ; Moving the frame with the mouse


    ; Moving the crosshair inside the magnified window
    if (atTopLeft) {
        WinMove crossHair,, % (x - frameX) * zoom - picMid, % (y - frameY) * zoom - picMid ; TODO isn't frameX just 0 here?
    }
    else {
        magnifierX := screenWidth - guiWidth ; TODO turn magnifierX into a global variable?
        magnifierY := screenHeight - guiHeight
        WinMove crossHair,, % magnifierX + ( (x - frameX) * zoom ) - picMid, % magnifierY + ( (y - frameY) * zoom) - picMid
    }


    ; TODO Resizing magnifier to be smaller than starting size changes margins left and right to white

    ; GuiControl, Move, mBorder, % "w" guiWidth - (2*BorderThickness) "h" guiHeight - (2*BorderThickness)


    destTLx := BorderThickness ; So destRect does not include the border
    destTLy := BorderThickness    
    destWidth  := guiWidth  - 2 * BorderThickness
    destHeight := guiHeight - 2 * BorderThickness

    srcTLx := frameX + BorderThickness
    srcTLy := frameY + BorderThickness
    srcWidth  := frameWidth  - 2 * BorderThickness
    srcHeight := frameHeight - 2 * BorderThickness

    rop := 0xCC0020 ; => SRCCOPY => raster operation (list here https://docs.microsoft.com/en-us/windows/win32/gdi/ternary-raster-operations)

    DllCall("gdi32.dll\StretchBlt"
    , UInt, hdcDest, Int, destTLx, Int, destTLy, Int, destWidth, Int, destHeight
    , UInt, hdcSrc,  Int, srcTLx,  Int, srcTLy,  Int, srcWidth,  Int, srcHeight
    , UInt, rop)
    ; https://docs.microsoft.com/en-us/windows/win32/api/wingdi/nf-wingdi-stretchblt

    ; DllCall("gdi32.dll\StretchBlt", UInt,hdcDest, Int,0, Int,0, Int, guiWidth + BorderThickness, Int, guiHeight + BorderThickness
    ; , UInt, hdcSrc, UInt, frameX + BorderThickness, UInt, frameY + BorderThickness, Int, frameWidth - 2*BorderThickness, Int, frameHeight - 2*BorderThickness, UInt,0xCC0020) ; SRCCOPY


    ; TODO Causing highlight click problems

    Gui 3:+AlwaysOnTop ; Keeps the crosshair ontop of the magnifier
    Gui +AlwaysOnTop ; So if there is another ontop gui the mouse frame is always on top

    ; TODO using numbers for frame gui broke the magnifier


    ; Moving the magnifier if the mouse frame is inside it
    if (counter >= 8 and !resizingAllowed) {
        checkForIntersect(frameX, frameY, frameWidth, frameHeight)
    }
    counter++

    SetTimer Repaint, 10
Return

;-------------------------------------------------------------------------------
; Auto Execute End
;-------------------------------------------------------------------------------

checkVariables() 
{
    if (zoom < 1 or zoom > 32) 
    {
        zoom := 4
    }

    if (guiWidth  > screenWidth  or guiWidth  <= 0) 
    {
        guiWidth  := screenWidth  / 3
    }

    if (guiHeight > screenHeight or guiHeight <= 0) 
    {
        guiHeight := screenHeight / 3
    }

    if (antialize != 1 and antialize != 0) 
    {
        antialize := False
    }
}
Return

checkForIntersect(frameX, frameY, frameWidth, frameHeight)
{
    counter := 0

    if (atTopLeft)
    {
        if (guiWidth > frameX and guiHeight > frameY)
        {
            x := screenWidth - guiWidth
            y := screenHeight - guiHeight
            WinMove, Magnifier, , x, y

            atTopLeft := False
        }
        Return
    }

    frameRx := frameX + frameWidth
    frameBy := frameY + frameHeight
    
    if (screenWidth - guiWidth < frameRx and screenHeight - guiHeight < frameBy)
    {
        WinMove, Magnifier, , 0, 0
        atTopLeft := True
    }    
}
Return

2GuiSize:
    guiWidth  := A_GuiWidth
    guiHeight := A_GuiHeight

    frameWidth  := guiWidth  / zoom
    frameHeight := guiHeight / zoom
Return

In(x,a,b) ; closest number to x in [a,b]
{
    ; x = TLx of the frame (and TLy)
    ; a = 0
    ; b = A_screenwidth - frameWidth (and height)

    IfLess x,%a%, Return a ; (if x < a)
    IfLess b,%x%, Return b ; (if b < x)

    Return x ; (x > a and x > b)
}

; --- Change zoom ---
!F7::
!F8::
    if (zoom < 31 and ( A_ThisHotKey = "!F7")) {
        zoom *= 1.189207115 ; sqrt(sqrt(2))
    }        
    
    if (zoom > 1 and ( A_ThisHotKey = "!F8")) {
        zoom /= 1.189207115
    }        

    frameWidth  := guiWidth  / zoom
    frameHeight := guiHeight / zoom
Return

; --- Resize ---
#f::
    resizingAllowed := !resizingAllowed

    if (resizingAllowed) {
        Gui 2:+Resize ; Allows window to be resized
        return
    }

    Gui 2:-Resize ; So the white bar from resizing isn't visible
Return

; --- Antialize ---
#a::
    antialize := !antialize
    DllCall("gdi32.dll\SetStretchBltMode", "uint", hdcDest, "int", 4*antialize) ; Antializing ?
Return 

saveSettings() {
    file := FileOpen("drMagnifierSettings.txt", "w")
    
    file.WriteLine(zoom)
    file.WriteLine(guiWidth)
    file.WriteLine(guiHeight)
    file.WriteLine(antialize)
    file.Close()

    DllCall("gdi32.dll\DeleteDC", UInt, hdcDest )
    DllCall("gdi32.dll\DeleteDC", UInt, hdcSrc )
}
Return

#n::
    saveSettings()
    ExitApp
Return