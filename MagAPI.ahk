#NoEnv
#SingleInstance, force
SetBatchLines -1 ; Script runs at max speed
SetWinDelay, 0   ; Default delay of 100ms for win__ commands

OnExit, Uninitialize

hostWidth  := 600
hostHeight := 250
zoom := 4

srcWidth  := hostWidth  / zoom
srcHeight := hostHeight / zoom

; Removing the taskbar from A_ScreenHeight
SysGet, workArea, MonitorWorkArea
global screenWidth  := workAreaRight
global screenHeight := workAreaBottom

global ctrl_in_BR := True ; ctrl starts in the BR of the screen
resizingAllowed := False

; ---------------------------
;  Creating the host window
; ---------------------------

; Using WS_EX_TRANSPARENT (0x20), allowing for click through, would be useful for a full screen or lens magnifier

; WS_EX_LAYERED (80000), WS_EX_CLIENTEDGE (0x200), WS_EX_DLGMODALFRAME (0x1)
Gui +AlwaysOnTop +ToolWindow -Caption -DPIScale +E0x80201 +HwndhostHandle

; Setting host's initial position to the BR
hostX := screenWidth  - hostWidth  - 10
hostY := screenHeight - hostHeight - 10

Gui Show, % "w" hostWidth "h" hostHeight "x" hostX "y" hostY "NoActivate", MagnifierWindowAHK

WinSet, Transparent, 255, % "ahk_id " hostHandle ; Setting host window to be fully opaque => Using WinSet instead of SetLayeredWindowAttributes()

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
initTLx := 0 ; Ctrl window is a child window of host window, therefore x = TLx of ctrl window relative to the TLx of host window
initTLy := 0
parentHwnd := hostHandle

ctrlHandle := DllCall("CreateWindowEx", "UInt",0, "Str",windowClassName, "Str",windowName, "UInt",winStyle, "Int",initTLx, "Int",initTLy, "Int",hostWidth, "Int",hostHeight, "Ptr",parentHwnd, "Ptr",0, "Ptr",hInstance, "Ptr",0)

; ----------------------------------------------
;  Setting Magnification Factor for ctrlHandle
; ----------------------------------------------

;The transformation matrix is
; (n, 0.0, 0.0)
; (0.0, n, 0.0)
; (0.0, 0.0, 1.0)
;where n is the magnification factor.

VarSetCapacity(MAGTRANSFORM, 36, 0) ; Allows MAGTRANSFORM to store 36 bytes and fills those bytes with 0

; A Float is stored using 4 bytes therefore middle is the 16-19th byte (5th float) and the br is 28-31st byte (9th float) 
NumPut(zoom, MAGTRANSFORM, (1-1)*4, "Float")
NumPut(zoom, MAGTRANSFORM, (5-1)*4, "Float")
NumPut(   1, MAGTRANSFORM, (9-1)*4, "Float")

DllCall("magnification\MagSetWindowTransform", "Ptr",ctrlHandle, "Ptr",&MAGTRANSFORM) ; Sets transformation matrix


; ------------
;  Smoothing
; ------------

DllCall("magnification\MagSetLensUseBitmapSmoothing", "Ptr",ctrlHandle, "Int",1) ; Undocumented smoothing function


; ---------------------------------
;  Frame displaying src rectangle
; ---------------------------------

BorderThickness := 4, BorderColor:="d9a518"

Gui 2: +AlwaysOnTop +ToolWindow -Caption -DPIScale +E0x20 ; WS_EX_TRANSPARENT (0x20) Allows for click through
Gui 2: Margin, % BorderThickness, % BorderThickness
Gui 2: Color, % BorderColor

width  := srcWidth
height := srcHeight + 1 ; Adding to srcHeight extends the transparent section downards

Gui 2: Add, Text, vframe_InternalRect w%width% h%height% 0x6 ; SS_WHITERECT (0x6), Creates a white rectangle the same size as src rect
Gui 2: Show, NoActivate, Frame
WinSet, TransColor, FFFFFF, Frame ; Makes the white rectangle inside frame transparent


; TODO
; - Understand why the + 1 is neccessary -> Not a total solution, yellow still visible with some levels of zoom
; - Zoom increase use += 0.25 and -= 0.25

; - Implement magnifier reading by running magnify.exe then minimizing/hiding it???
; - Can change color of border in Display Settings/Colours 

; -------------------------------------------------------
;  Updating the source rectangle to the mouses location
; -------------------------------------------------------

CoordMode, Mouse, Screen
Loop
{
	MouseGetPos, mouseX, mouseY

	; Keeping the src rectangle within the screen
	srcTLx := clamp(mouseX - (srcWidth  / 2), 0, A_ScreenWidth  - srcWidth)
	srcTLy := clamp(mouseY - (srcHeight / 2), 0, A_ScreenHeight - srcHeight)

    ; Moving frame with the mouse
    WinMove Frame,, % srcTLx - BorderThickness, % srcTLy - BorderThickness, % srcWidth + (2*BorderThickness), % srcHeight + (2*BorderThickness) + 1 ; bigger + value for height extends yellow border downwards

	; Setting the soruce rectangle
	VarSetCapacity(Rect, 16, 0) ; Rect contains 4 four-byte integers
	NumPut(srcTLx, Rect, 0, "Int")
	NumPut(srcTLy, Rect, 4, "Int")
	NumPut(hostWidth , Rect,  8, "Int") ; BRx but actually width (removing/changing these two does nothing so not sure what they are used for)
	NumPut(hostHeight, Rect, 12, "Int") ; BRy but actually height
	DllCall("magnification\MagSetWindowSource", "Ptr",ctrlHandle, "Ptr",&Rect) ; Specifies what part of the screen to magnify (source rectangle)

	; Prevnting intersection handling if resizing allowed
	if (resizingAllowed) {
		Continue
	}

	; Handling intersection between the frame (src rectnagle) and the ctrl window
	if (ctrl_in_BR) {
		srcBRx := srcTLx + srcWidth
		srcBRy := srcTLy + srcHeight

		if (screenWidth - hostWidth - 10 < srcBRx and screenHeight - hostHeight - 10 < srcBRy) {
			WinMove, % "ahk_id" hostHandle,, 0, 0
			ctrl_in_BR := False
		}
	}
	else if (hostWidth + 10 > srcTLx and hostHeight + 10 > srcTLy) {
		WinMove, % "ahk_id" hostHandle,, screenWidth - hostWidth - 10, screenHeight - hostHeight - 10
		ctrl_in_BR := True
	}
}
return

clamp(val, min, max) {
	if (val < min) {
		return min
	}

	if (val > max) {
		return max
	}

	return val
}

; --- Change zoom ---
!F7::
!F8::
    if (zoom < 31 and (A_ThisHotKey = "!F7")) {
        zoom *= 1.189207115 ; sqrt(sqrt(2))
    }        
    
    if (zoom > 1 and (A_ThisHotKey = "!F8")) {
        zoom /= 1.189207115
    }        

	srcWidth  := hostWidth  / zoom
	srcHeight := hostHeight / zoom

	NumPut(zoom, MAGTRANSFORM, (1-1)*4, "Float")
	NumPut(zoom, MAGTRANSFORM, (5-1)*4, "Float")

	DllCall("magnification\MagSetWindowTransform", "Ptr",ctrlHandle, "Ptr",&MAGTRANSFORM) ; Sets transformation matrix

	GuiControl, 2:Move, frame_InternalRect, % "w" srcWidth "h" srcHeight + 1 ; Resizes frame_InternalRect to be the same size as src rect
Return

; Called when the user resizes the host window
GuiSize:
    hostWidth  := A_GuiWidth
    hostHeight := A_GuiHeight

    srcWidth  := hostWidth  / zoom
    srcHeight := hostHeight / zoom

	GuiControl, 2:Move, frame_InternalRect, % "w" srcWidth "h" srcHeight + 1 ; Resizes frame_InternalRect to be the same size as src rect

	WinMove, % "ahk_id" ctrlHandle, , 0, 0, hostWidth, hostHeight ; Resizes ctrl window so that it fills the inside of host window ( filling it with the magnified src rect)
Return

; Toggles the ability to resize the host window
#f::
    resizingAllowed := !resizingAllowed

    if (resizingAllowed) {
        Gui +Resize ; Allows window to be resized
        return
    }

    Gui -Resize ; So the white bar from resizing isn't visible
Return

#n::
Uninitialize:
Gui, Destroy
DllCall("magnification\MagUninitialize") ; Destroy the magnifier run-time objects, freeing the associated system resources
ExitApp

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