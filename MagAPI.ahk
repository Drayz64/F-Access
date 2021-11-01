;Magnification API and AutoHotkey - Ask for Help - AutoHotkey Community
;http://www.autohotkey.com/board/topic/64060-magnification-api-and-autohotkey/

#SingleInstance, force
SetWinDelay, 0   ; Default delay of 100ms for win__ commands

OnExit, Uninitialize

ctrlW := 600, ctrlH := 250
zoom := 4
; zoom *= 1.189207115
vDoWinWithinScreen := 1
vOffset := 0 ;window within screen offset
; vOffset := 50

; ---------------------------
;  Creating the host window
; ---------------------------

; WS_EX_LAYERED (80000), WS_EX_CLIENTEDGE (0x200), WS_EX_WINDOWEDGE (0x100), ***WS_EX_TRANSPARENT (0x20)*** Transparent allows for user to click through, WS_EX_DLGMODALFRAME (0x1)
Gui, +AlwaysOnTop +ToolWindow -Caption +E0x80201 +HwndhostHandle
Gui, Show, % "w" ctrlW "h" ctrlH "x650 y0 NoActivate", MagnifierWindowAHK

WinSet, Transparent, 255, % "ahk_id " hostHandle ; Setting host window to be fully opaque (not transparent) => Using WinSet instead of SetLayeredWindowAttributes()

vSfx := (A_PtrSize=8) ? "Ptr" : ""
hInstance := DllCall("GetWindowLong" vSfx, "Ptr",hostHandle, "Int",-6) ; hInstance := -6 -> A handle to the instance of the module to be associated with the magnifier control window


; ---------------------------------
;  Initialising magnifier library
; ---------------------------------

; Explicitly loading magnification.dll, otherwise it would be automatically unloaded after MagIntialize, meaning the window class(?) would be unregistered
DllCall("LoadLibrary", "Str","magnification.dll")

; Creates and initialises the magnifier run-time objects
DllCall("magnification\MagInitialize")

; GroupAdd, WinGroupMag, % "ahk_id " hostHandle ; Reason for this???


; ----------------------------------------
;  Creating the magnifier control window
; ----------------------------------------

WS_CHILD := 0x40000000
WS_VISIBLE := 0x10000000
MS_SHOWMAGNIFIEDCURSOR := 0x1
winStyle := WS_CHILD | MS_SHOWMAGNIFIEDCURSOR | WS_VISIBLE
windowClassName := "Magnifier" ; = WC_Magnifier
windowName := "MagnifierWindow"
initTLx := 0 ; Inital TL horizontal position of the window
initTLy := 0
parentHwnd := hostHandle

ctrlHandle := DllCall("CreateWindowEx", "UInt",0, "Str",windowClassName, "Str",windowName, "UInt",winStyle, "Int",initTLx, "Int",initTLy, "Int",ctrlW, "Int",ctrlH, "Ptr",parentHwnd, "Ptr",0, "Ptr",hInstance, "Ptr",0)


; ----------------------------------------------
;  Setting Magnification Factor for ctrlHandle
; ----------------------------------------------

;The transformation matrix is
; (n, 0.0, 0.0)
; (0.0, n, 0.0)
; (0.0, 0.0, 1.0)
;where n is the magnification factor.

VarSetCapacity(MAGTRANSFORM, 36, 0) ; Allows MAGTRANSFORM to store 36 bytes and fills those bytes with 0

; NumPut(Number, VarOrAddress [, Offset = 0, Type = "UInt"]) Offset => # of bytes added to VarOrAddress determining the target address.
; A Float is stored using 4 bytes therefore middle is the 16-19th byte (5th float) and the br is 28-31st byte (9th float) 
NumPut(zoom, MAGTRANSFORM, (1-1)*4, "Float")
NumPut(zoom, MAGTRANSFORM, (5-1)*4, "Float")
NumPut(1, MAGTRANSFORM, (9-1)*4, "Float")

DllCall("magnification\MagSetWindowTransform", "Ptr",ctrlHandle, "Ptr",&MAGTRANSFORM) ; Sets transformation matrix -> specifies magnification factor


; ------------
;  Smoothing
; ------------

DllCall("magnification\MagSetLensUseBitmapSmoothing", "Ptr",ctrlHandle, "Int",1) ; Undocumented smoothing function


; TODO
; - Prevent src rect from moving offscreen (1st understand rect code)
; - Implement ability to resize magnifier window and change zoom level
; - Implement rectangle around mouse, showing area that will be magnified (the src rectangle)
; - Implement border
; - Implement magnifier reading by running magnify.exe then minimizing/hiding it???
; - Can change color of border in Display Settings/Colours 
; - Mouse rectangle intersection with mag window

; -------------------------------------------------------
;  Updating the source rectangle to the mouses location
; -------------------------------------------------------

CoordMode, Mouse, Screen
Loop
{
	MouseGetPos, mouseX, mouseY

	; if !vGuiW {
	; 	msgbox % "Changed"
	; 	WinGetPos,,, vGuiW, vGuiH, % "ahk_id " hostHandle
	; }

	; TODO Use if's here to clamp rectX and rectY
	rectX := mouseX - (ctrlW / (2*zoom))
	rectY := mouseY - (ctrlH / (2*zoom))
	rectY += 10 / zoom ; Account for window title bar

	; vGuiX := mouseX-(vGuiW/2)
	; vGuiY := mouseY-(vGuiH/2)

	VarSetCapacity(Rect, 16, 0) ; Rect contains 4 four-byte integers
	NumPut(rectX, Rect, 0,  "Int") ; TLx
	NumPut(rectY, Rect, 4,  "Int") ; TLy
	NumPut(ctrlW, Rect, 8,  "Int") ; BRx
	NumPut(ctrlH, Rect, 12, "Int") ; BRy
	DllCall("magnification\MagSetWindowSource", "Ptr",ctrlHandle, "Ptr",&Rect) ; Specifies what part of the screen to magnify (source rectangle)

	;keep GUI (ctrlHandle) within screen / certain coordinates
	; if vDoWinWithinScreen
	; {
	; 	; TODO Handle offscreen the same as normal magnifier -> move this sort of code to the source rectangle area

	; 	if (vGuiX < vOffset)
	; 		vGuiX := vOffset
	; 	if (vGuiX+vGuiW > A_ScreenWidth-vOffset)
	; 		vGuiX := A_ScreenWidth-vOffset-vGuiW
	; 	if (vGuiY < vOffset)
	; 		vGuiY := vOffset
	; 	if (vGuiY+vGuiH > A_ScreenHeight-vOffset)
	; 		vGuiY := A_ScreenHeight-vOffset-vGuiH
	; }

	; if (vGuiX2 = vGuiX) && (vGuiY2 = vGuiY)
	; 	Sleep, 700
	; else
	; 	WinMove, % "ahk_id " hostHandle,, % vGuiX, % vGuiY ; Moving the magnifier window around with the mouse
	; Sleep, 300

	; vGuiX2 := vGuiX
	; vGuiY2 := vGuiY
}
return

#n::
Uninitialize:
Gui, Destroy
DllCall("magnification\MagUninitialize") ; Destroy the magnifier run-time objects, freeing the associated system resources
ExitApp
#IfWinActive

;-------------------------------------------------------------------------------
; Reload on Save
;-------------------------------------------------------------------------------
~^s::
    Sleep 200
    WinGetActiveTitle, activeTitle
    activeTitle := StrReplace(activeTitle, " - Visual Studio Code")

    if (activeTitle = A_ScriptName) {
        ToolTip, %A_ScriptName%, 1770, 959
        sleep 800
        ToolTip
        Reload
    }
return

; Even faster performance can be achieved by looking up the function's address beforehand. For example:

; ; In the following example, if the DLL isn't yet loaded, use LoadLibrary in place of GetModuleHandle.
; MulDivProc := DllCall("GetProcAddress", "Ptr", DllCall("GetModuleHandle", "Str", "kernel32", "Ptr"), "AStr", "MulDiv", "Ptr")
; Loop 500
;     DllCall(MulDivProc, "Int", 3, "Int", 4, "Int", 3)

; DllCall("magnification\MagShowSystemCursor", "Int",1) ; Makes cursor invisble (in normal screen)