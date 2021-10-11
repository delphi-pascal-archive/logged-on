(****************************************************************
 ****************************************************************
 ***                                                          ***
 ***        Copyright (c) 2001 by -=Assarbad [GoP]=-          ***
 ***       ____________                 ___________           ***
 ***      /\   ________\               /\   _____  \          ***
 ***     /  \  \       /    __________/  \  \    \  \         ***
 ***     \   \  \   __/___ /\   _____  \  \  \____\  \        ***
 ***      \   \  \ /\___  \  \  \    \  \  \   _______\       ***
 ***       \   \  \ /   \  \  \  \    \  \  \  \      /       ***
 ***        \   \  \_____\  \  \  \____\  \  \  \____/        ***
 ***         \   \___________\  \__________\  \__\            ***
 ***          \  /           /  /          /  /  /            ***
 ***           \/___________/ \/__________/ \/__/             ***
 ***                                                          ***
 ***  May the source be with you, stranger ... :-)            ***
 ***                                                          ***
 ***  Greets from -=Assarbad [GoP]=- ...                      ***
 ***  Special greets go 2 Nico, Casper, SA, Pizza, Navarion...***
 ***[for questions/proposals drop a mail to Assarbad@ePost.de]***
 *****************************************ASCII by Assa [GoP]****
 ****************************************************************)

{$R handcursor.res}
const
  AHyperlink = 'AHyperlinkWndClassEx';
var
  HLcursor: Cardinal = 0;
  inactivefont,
    activefont,
    inactivecolor,
    activecolor: Cardinal;

function HyperlinkWndProc(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall;
var
  prop, DC: DWORD;
  point: TPoint;
  rect: TRect;
  ps: TPaintStruct;
  pc: array[0..$400] of char;

  procedure paint(txtcolor: Cardinal);
  var size: TSize;
  begin
    GetClientRect(hWnd, rect);
    if txtcolor = inactivecolor then selectobject(dc, inactivefont)
    else selectobject(dc, activefont);
    Fillrect(DC, rect, GetSysColorBrush(COLOR_3DFACE));
    SetBkMode(DC, TRANSPARENT);
    Settextcolor(DC, txtcolor);
    SendMessage(hWnd, WM_GETTEXT, $400, LongInt(@pc[0]));
    GetWindowRect(hWnd, rect);
    GetTextExtentPoint32(DC, @pc[0], lstrlen(@pc[0]), size);
//center text in control window
    ExtTextOut(DC, ((rect.right - rect.left) div 2) - (size.cx div 2), 0, 2, @rect, @pc[0], lstrlen(@pc[0]), nil);
  end;

  function varfont(DC: DWORD; size, weight: integer; underline: BOOL): DWORD;
  begin
    result := CreateFont(-MulDiv(size, GetDeviceCaps(DC, LOGPIXELSY), 72), 0, 0, 0, weight, 0, Cardinal(underline), 0, ANSI_CHARSET, OUT_TT_PRECIS, CLIP_DEFAULT_PRECIS, PROOF_QUALITY, VARIABLE_PITCH or FF_ROMAN, 'MS Sans Serif');
  end;

  function fixfont(DC: DWORD; size, weight: integer; underline: BOOL): DWORD;
  begin
    result := CreateFont(-MulDiv(size, GetDeviceCaps(DC, LOGPIXELSY), 72), 0, 0, 0, weight, 0, Cardinal(underline), 0, ANSI_CHARSET, OUT_TT_PRECIS, CLIP_DEFAULT_PRECIS, PROOF_QUALITY, FIXED_PITCH or FF_MODERN, 'Courier New');
  end;

begin
  Result := 0;
  case uMsg of
    WM_CREATE:
      begin
        result := DefWindowProc(hWnd, uMsg, wParam, lParam);
        HLcursor := LoadCursor(hInstance, 'HandCursor');
        DC := GetWindowDC(hWnd);
        inactivefont := fixfont(DC, 8, FW_NORMAL, FALSE);
        activefont := fixfont(DC, 8, FW_BOLD, TRUE);
        ReleaseDC(hWnd, DC);
        inactivecolor := rgb($0, $0, $0);
        activecolor := rgb($0, $0, $FF);
        SendMessage(hWnd, WM_CAPTURECHANGED, 0, 0);
      end;
    WM_RBUTTONUP,
      WM_LBUTTONUP:
      begin
        prop := getprop(hwnd, 'Link');
        if prop <> 0 then shellexecute(0, 'open', pchar(prop), '', '', SW_SHOWNORMAL);
      end;
    WM_CAPTURECHANGED,
      WM_MOUSEMOVE:
      begin
        GetCursorPos(point);
        GetWindowRect(hwnd, rect);
        if PtInRect(rect, point) then begin
          if GetCapture <> hWnd then begin
            SetCapture(hWnd);
            SetCursor(HLcursor);
            SendMessage(hWnd, WM_PAINT, activecolor, -1);
          end;
        end else begin
          ReleaseCapture;
          SendMessage(hWnd, WM_PAINT, inactivecolor, -1);
        end;
      end;
    WM_PAINT:
      begin
        case lParam of
          -1: begin
              DC := GetWindowDC(hWnd);
              paint(wParam);
              ReleaseDC(hWnd, DC);
            end;
        else begin
            DC := BeginPaint(hWnd, ps);
            paint(wParam);
            EndPaint(hWnd, ps);
          end;
        end;
      end;
  else result := DefWindowProc(hWnd, uMsg, wParam, lParam);
  end;
end;

procedure initacomctl;
var
  wc: TWndClassEx;
begin
  wc.style := CS_HREDRAW or CS_VREDRAW or CS_GLOBALCLASS;
  wc.cbSize := sizeof(TWNDCLASSEX);
  wc.lpfnWndProc := @HyperlinkWndProc;
  wc.cbClsExtra := 0;
  wc.cbWndExtra := 0;
  wc.hInstance := hInstance;
  wc.hbrBackground := COLOR_WINDOW;
  wc.lpszMenuName := nil;
  wc.lpszClassName := AHyperlink;
  wc.hIcon := 0;
  wc.hIconSm := 0;
  wc.hCursor := 0;
  RegisterClassEx(wc);
end;
