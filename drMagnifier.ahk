#NoEnv
#SingleInstance, force
#NoTrayIcon
SetBatchLines -1 ; Script runs at max speed
SetWinDelay, 0   ; Default delay of 100ms for win__ commands

OnExit, Uninitialize

; A_ScreenHeight includes the taskbar so using different variable that doesn't have the taskbar
SysGet, workArea, MonitorWorkArea
screenWidth  := workAreaRight
screenHeight := workAreaBottom

; Retrieving saved settings
IniRead, zoom, drMagSettings.ini, MagFactor, Zoom, 4
IniRead, hostWidth , drMagSettings.ini, HostSize,  Width, % screenWidth  / 2.5
IniRead, hostHeight, drMagSettings.ini, HostSize, Height, % screenHeight / 5

srcWidth  := hostWidth  / zoom
srcHeight := hostHeight / zoom

hostInBr := True
resizingAllowed := False

zoomStep := 0.5 ; 50%

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

hInstance := DllCall("GetWindowLongPtr", "Ptr",hostHandle, "Int",-6, "Ptr") ; -6 = GWLP_HINSTANCE (Retrieves a handle to the application instance)

; ---------------------------------
;  Initialising magnifier library
; ---------------------------------

; Explicitly loading magnification.dll, otherwise it would be automatically unloaded after MagIntialize, meaning the window class(?) would be unregistered
DllCall("LoadLibrary", "Str","magnification.dll", "Ptr")

; Creates and initialises the magnifier run-time objects
DllCall("magnification\MagInitialize")


; ----------------------------------------
;  Creating the magnifier control window
; ----------------------------------------

WS_CHILD   := 0x40000000
WS_VISIBLE := 0x10000000
MS_SHOWMAGNIFIEDCURSOR := 0x1
winStyle := WS_CHILD | MS_SHOWMAGNIFIEDCURSOR | WS_VISIBLE
windowClassName := "Magnifier" ; = WC_Magnifier
windowName := "MagnifierWindow"
initTLx := 0 ; Ctrl window is a child window of host window, therefore x = TLx of ctrl window, relative to the TLx of host window
initTLy := 0
parentHwnd := hostHandle
;hInstance -> A handle to the instance of the module to be associated with the magnifier control window

ctrlHandle := DllCall("CreateWindowEx", "UInt",0, "Str",windowClassName, "Str",windowName, "UInt",winStyle, "Int",initTLx, "Int",initTLy, "Int",hostWidth, "Int",hostHeight, "Ptr",parentHwnd, "Ptr",0, "Ptr",hInstance, "Ptr",0, "Ptr")
; Changing the value of hInstance has no effect

; ----------------------------------------------
;  Setting Magnification Factor for ctrlHandle
; ----------------------------------------------

;The transformation matrix is
; (n, 0.0, 0.0)
; (0.0, n, 0.0)
; (0.0, 0.0, 1.0)
;where n is the magnification factor.

VarSetCapacity(matrix, 36, 0) ; Allows matrix to store 36 bytes and fills those bytes with 0

; A Float is stored using 4 bytes therefore middle is the 16-19th byte (5th float) and the br is 28-31st byte (9th float) 
NumPut(zoom, matrix, (1-1)*4, "Float")
NumPut(zoom, matrix, (5-1)*4, "Float")
NumPut(   1, matrix, (9-1)*4, "Float")

DllCall("magnification\MagSetWindowTransform", "Ptr",ctrlHandle, "Ptr",&matrix) ; Sets transformation matrix


; ------------
;  Smoothing
; ------------

DllCall("magnification\MagSetLensUseBitmapSmoothing", "Ptr",ctrlHandle, "Int",1) ; Undocumented smoothing function


; ------------------------------------------------
;  Creating src rectangle frame around the mouse
; ------------------------------------------------

BorderThickness := 4, BorderColor:="d9a518"

Gui 2: +AlwaysOnTop +ToolWindow -Caption -DPIScale +E0x20 ; WS_EX_TRANSPARENT (0x20) Allows for click through
Gui 2: Margin, % BorderThickness, % BorderThickness
Gui 2: Color, % BorderColor

width  := srcWidth  + 1
height := srcHeight + 1 ; Adding to srcHeight extends the transparent section downards

Gui 2: Add, Text, vframe_InternalRect w%width% h%height% 0x6 ; SS_WHITERECT (0x6), Creates a white rectangle the same size as src rect
Gui 2: Show, NoActivate, Frame
WinSet, TransColor, FFFFFF, Frame ; Makes the white rectangle inside frame transparent


; TODO
; - Understand why the + 1 is neccessary for width and height
; - Check setting variables from the ini are sensible???

; - Implement magnifier reading by running magnify.exe then minimizing/hiding it???
; - Can change color of border in Display Settings/Colours

; -------------------------------------------------------
;  Updating the source rectangle to the mouses location
; -------------------------------------------------------

;Improving performance by loading the functions address before the loop
; magSetWinSrcAddress := DllCall("GetProcAddress", "Ptr", DllCall("GetModuleHandle", "Str", "magnification", "Ptr"), "AStr", "MagSetWindowSource", "Ptr")

CoordMode, Mouse, Screen
magnify:
	MouseGetPos, mouseX, mouseY

	; Keeping the src rectangle within the screen
	srcTLx := clamp(mouseX - (srcWidth  / 2), 0, A_ScreenWidth  - srcWidth)
	srcTLy := clamp(mouseY - (srcHeight / 2), 0, A_ScreenHeight - srcHeight)

    ; Moving frame with the mouse
    WinMove Frame,, % srcTLx - BorderThickness, % srcTLy - BorderThickness, % srcWidth + (2*BorderThickness) + 1, % srcHeight + (2*BorderThickness) + 1 ; bigger + value for height extends yellow border downwards

	; Setting the soruce rectangle
	VarSetCapacity(Rect, 16, 0) ; Rect contains 4 four-byte integers
	NumPut(srcTLx, Rect, 0, "Int")
	NumPut(srcTLy, Rect, 4, "Int")
	NumPut(hostWidth , Rect,  8, "Int") ; BRx but actually width (removing/changing these two does nothing so not sure what they are used for)
	NumPut(hostHeight, Rect, 12, "Int") ; BRy but actually height
	; DllCall(magSetWinSrcAddress, "Ptr",ctrlHandle, "Ptr",&Rect) ; Specifies what part of the screen to magnify (source rectangle)
	DllCall("magnification\MagSetWindowSource", "Ptr",ctrlHandle, "Ptr",&Rect) ; Specifies what part of the screen to magnify (source rectangle)

	; Preventing intersection handling if resizing allowed
	if (resizingAllowed) {
		; Continue
		Return
	}

	; Handling intersection between the frame (src rectangle) and the host window
	Gosub, checkForIntersect

	SetTimer, magnify, 10
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

checkForIntersect:
	if (hostInBr) {
		srcBRx := srcTLx + srcWidth
		srcBRy := srcTLy + srcHeight

		if (screenWidth - hostWidth - 10 < srcBRx and screenHeight - hostHeight - 10 < srcBRy) {
			WinMove, % "ahk_id" hostHandle,, 0, 0
			hostInBr := False
		}

		return
	}
	
	if (hostWidth + 10 > srcTLx and hostHeight + 10 > srcTLy) {
		WinMove, % "ahk_id" hostHandle,, screenWidth - hostWidth - 10, screenHeight - hostHeight - 10
		hostInBr := True
	}
return

; --- Change zoom ---
!F7::
!F8::
    if (zoom <= 16 - zoomStep and (A_ThisHotKey = "!F7")) { ; 1600%
        zoom += zoomStep
    }        
    
    if (zoom >= 1 + zoomStep and (A_ThisHotKey = "!F8")) { ; 100%
        zoom -= zoomStep
    }

	; Displaying the new zoom value to the user
	ToolTip, % Floor(zoom*100) "%", A_ScreenWidth/2, A_ScreenHeight/2
	SetTimer, removeToolTip, -1000

	srcWidth  := hostWidth  / zoom
	srcHeight := hostHeight / zoom

	GuiControl, 2:Move, frame_InternalRect, % "w" srcWidth + 1 "h" srcHeight + 1 ; Resizes frame_InternalRect to be the same size as src rect

	NumPut(zoom, matrix, (1-1)*4, "Float")
	NumPut(zoom, matrix, (5-1)*4, "Float")

	DllCall("magnification\MagSetWindowTransform", "Ptr",ctrlHandle, "Ptr",&matrix) ; Sets transformation matrix
Return

RemoveToolTip:
	ToolTip
return

; Called when the user resizes the host window
GuiSize:
    hostWidth  := A_GuiWidth
    hostHeight := A_GuiHeight

    srcWidth  := hostWidth  / zoom
    srcHeight := hostHeight / zoom

	GuiControl, 2:Move, frame_InternalRect, % "w" srcWidth + 1 "h" srcHeight + 1 ; Resizes frame_InternalRect to be the same size as src rect

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

Uninitialize:
	Gui, Destroy
	DllCall("magnification\MagUninitialize") ; Destroy the magnifier run-time objects, freeing the associated system resources

	IniWrite, % zoom, drMagSettings.ini, MagFactor, Zoom
	IniWrite, % hostWidth , drMagSettings.ini, HostSize,  Width
	IniWrite, % hostHeight, drMagSettings.ini, HostSize, Height
ExitApp