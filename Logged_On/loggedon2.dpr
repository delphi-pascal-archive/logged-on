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

program loggedon2;
uses windows, messages, shellapi;

{$D 'LoggedOn2 - (C) 2001 by -=Assarbad=-'}//insert the appname here
{$APPTYPE GUI}
{$INCLUDE compilerswitches.PAS}

{$R main.RES}
{$INCLUDE Hyperlink.pas}

const
  SC_TRAY = WM_USER + 666;
  WM_SHELLNOTIFY = WM_USER + 667;
  IDC_BUTTON1 = 1001;
  IDC_LIST1 = 1002;
  IDC_BUTTON2 = 1003;
  IDC_BUTTON_STATUS = 1004;
  IDC_BUTTON_CLOSE = 1005;
  IDC_CUSTOM1 = 1006;
  IDC_CUSTOM2 = 1007;
  IDC_STATIC_ABOUT = 1008;
  IDC_STATIC_ASSA_ICON = 1009;

  UNLEN = 256; // Maximum user name length

  err = 'Error';
  err_noentry = 'Could not find entry point for ';

  ServerBrowseDialogA0_name = 'ServerBrowseDialogA0';

  com_hint = ' for logged on users';
  hint_IDC_BUTTON1 = 'Scan all reachable machines' + com_hint;
  hint_IDC_BUTTON2 = 'Choose a special machine to scan' + com_hint;
  hint_IDC_BUTTON_STATUS = 'About this program';
  mylink = 'http://www.erm.tu-cottbus.de/delphi';
  mymail = 'mailto: Assarbad@ePost.de';
  progname = 'Logged On - (C) 2001 by -=Assarbad=-';

{$INCLUDE LoggedOnFunc.pas}

type
  TServerBrowseDialogA0 = function(hwnd: HWND; pchBuffer: pointer; cchBufSize: DWord): bool; stdcall;

var hImageList, hwndTV, ThreadID, Threadhandle, hDlg, hDlg2: DWORD;
  ffont: Cardinal;
  appIcon: DWORD = 0;
  note: TNotifyIconData;
  ServerBrowseDialogA0: TServerBrowseDialogA0 = nil;
  threadruns: boolean = false;
  Threadbuffer: ATstrings;
  img_USR: DWORD = 0;
  img_WS: DWORD = 0;
  img_WSU: DWORD = 0;

//comctl32

type
  HTREEITEM = ^_TREEITEM;
  _TREEITEM = packed record
  end;

  tagTVITEMA = packed record
    mask: UINT;
    hItem: HTreeItem;
    state: UINT;
    stateMask: UINT;
    pszText: PAnsiChar;
    cchTextMax: Integer;
    iImage: Integer;
    iSelectedImage: Integer;
    cChildren: Integer;
    lParam: LPARAM;
  end;

  tagTVITEMEXA = packed record
    mask: UINT;
    hItem: HTREEITEM;
    state: UINT;
    stateMask: UINT;
    pszText: PAnsiChar;
    cchTextMax: Integer;
    iImage: Integer;
    iSelectedImage: Integer;
    cChildren: Integer;
    lParam: LPARAM;
    iIntegral: Integer;
  end;

  tagTVINSERTSTRUCTA = packed record
    hParent: HTreeItem;
    hInsertAfter: HTreeItem;
    case Integer of
      0: (itemex: tagTVITEMEXA);
      1: (item: tagTVITEMA);
  end;

const
  TV_FIRST = $1100;
  TVI_ROOT = HTreeItem($FFFF0000);
  TVI_LAST = HTreeItem($FFFF0002);
  TVM_INSERTITEMA = TV_FIRST + 0;
  TVM_DELETEITEM = TV_FIRST + 1;
  TVM_EXPAND = TV_FIRST + 2;
  TVM_SETIMAGELIST = TV_FIRST + 9;
  TVM_INSERTITEM = TVM_INSERTITEMA;
  TVIF_TEXT = $0001;
  TVIF_IMAGE = $0002;
  TVIF_SELECTEDIMAGE = $0020;
  TVIF_CHILDREN = $0040;
  ILC_COLOR16 = $0010;
  TVE_EXPAND = $0002;

procedure InitCommonControls; stdcall; external 'comctl32.dll' name 'InitCommonControls';

function ImageList_Create(CX, CY: Integer; Flags: UINT;
  Initial, Grow: Integer): DWORD; stdcall; external 'comctl32.dll' name 'ImageList_Create';

function TreeView_Expand(hwnd: HWND; hitem: HTreeItem; code: Integer): Bool;
begin
  Result := Bool(SendMessage(hwnd, TVM_EXPAND, code, Longint(hitem)));
end;

function ImageList_Add(ImageList: DWORD; Image, Mask: HBitmap): Integer; stdcall; external 'comctl32.dll' name 'ImageList_Add';

function TreeView_DeleteAllItems(hwnd: HWND): Bool;
begin
  Result := Bool(SendMessage(hwnd, TVM_DELETEITEM, 0, Longint(TVI_ROOT)));
end;

function TreeView_InsertItem(hwnd: HWND; const lpis: tagTVINSERTSTRUCTA): HTreeItem;
begin
  Result := HTreeItem(SendMessage(hwnd, TVM_INSERTITEM, 0, Longint(@lpis)));
end;

function StatusWindowProc(hWnd: HWND; Msg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall;
var
  pc: Pchar;
  dw: DWORD;
  point: TPoint;
  rect: TRect;
begin
  dw := 0;
  case Msg of
//    WM_CAPTURECHANGED,
    WM_MOUSEMOVE:
      begin
        GetCursorPos(point);
        GetWindowRect(hwnd, rect);
        if PtInRect(rect, point) then begin
          if GetCapture <> hWnd then begin
            SetCapture(hWnd);
            pc := Pchar(GetProp(hWnd, 'Status_Hint'));
            sendmessage(hWnd, WM_GETTEXT, 0, dw);
            if Pchar(dw) <> pc then
              if pc <> nil then setdlgitemtext(hDlg, IDC_BUTTON_STATUS, pc);
          end;
        end else begin
          ReleaseCapture;
          setdlgitemtext(hDlg, IDC_BUTTON_STATUS, progname);
        end;
      end;
  end;
  result := CallWindowProc(pointer(GetProp(hWnd, 'Status_OrigWndProc')), hWnd, Msg, wParam, lParam);
end;

procedure sethint(hwnd: HWND; hint: pchar);
begin
  SetProp(hWnd, 'Status_Hint', DWORD(hint));
  SetProp(hWnd, 'Status_OrigWndProc', DWORD(SetWindowLong(hwnd, GWL_WNDPROC, Integer(@StatusWindowProc))));
end;

function dlgfunc_about(hwnd: hwnd; umsg: dword; wparam: wparam; lparam: lparam): bool; stdcall;
begin
  result := true;
  case umsg of
    WM_INITDIALOG:
      begin
        hdlg2 := hwnd;
        sendmessage(hwnd, WM_SETTEXT, 0, Longint(pchar(progname)));
        setprop(Getdlgitem(hwnd, IDC_CUSTOM1), 'Link', Longint(pchar(mylink)));
        setprop(Getdlgitem(hwnd, IDC_CUSTOM2), 'Link', Longint(pchar(mymail)));
      end;
    WM_CLOSE:
      begin
        hdlg2 := 0;
        EndDialog(hWnd, 0);
      end;
    WM_COMMAND:
      if hiword(wparam) = BN_CLICKED then begin
        case loword(wparam) of
          IDC_BUTTON_CLOSE:
            sendmessage(hwnd, WM_CLOSE, 0, 0);
        end;
      end;
  else result := false;
  end;
end;

function Threadfunc(x: POINTER): DWORD; stdcall;
var lpis: tagTVINSERTSTRUCTA;
  L: ATStrings;
  i: integer;

  procedure Addrootitem(s: string);
  var item: HTREEITEM;
    j: integer;
  begin
    GetLocalLogons(s, L);
    lpis.hParent := nil;
    lpis.hInsertAfter := TVI_ROOT;
    lpis.item.mask := TVIF_TEXT or TVIF_SELECTEDIMAGE or TVIF_IMAGE;
    lpis.item.pszText := pchar(s);
    case length(L) > 0 of
      FALSE: begin
          lpis.item.iImage := 0;
          lpis.item.iSelectedImage := lpis.item.iImage;
          TreeView_InsertItem(hwndTV, lpis);
        end;
      TRUE: begin
          lpis.item.iImage := 1;
          lpis.item.iSelectedImage := lpis.item.iImage;
          item := TreeView_InsertItem(hwndTV, lpis);
          if length(L) > 0 then
            for j := 0 to length(L) - 1 do begin
              lpis.hParent := Pointer(item);
              lpis.hInsertAfter := TVI_LAST;
              lpis.item.pszText := pchar(L[j]);
              lpis.item.iImage := 2;
              lpis.item.iSelectedImage := lpis.item.iImage;
              TreeView_InsertItem(hwndTV, lpis);
            end;
          TreeView_Expand(hwndTV, item, TVE_EXPAND);
        end;
    end;
  end;

begin
  threadruns := true;
  TreeView_DeleteAllItems(hwndTV);
  for i := 0 to length(Threadbuffer) - 1 do begin
    AddrootItem(ThreadBuffer[i]);
  end;
  threadruns := false;
  result := 0;
end;

function dlgfunc(hwnd: hwnd; umsg: dword; wparam: wparam; lparam: lparam): bool; stdcall;
var
  buffer: array[0..MAX_PATH - 1] of char;
  DC: DWORD;
begin
  result := true;
  case umsg of
    WM_INITDIALOG:
      begin
        hDlg := hWnd;
        sendmessage(hwnd, WM_SETTEXT, 0, Longint(pchar(progname)));
        setdlgitemtext(hWnd, IDC_BUTTON_STATUS, progname);

        DC := GetWindowDC(hWnd);
        ffont := CreateFont(-MulDiv(8, GetDeviceCaps(DC, LOGPIXELSY), 72), 0, 0, 0, FW_NORMAL, 0, Cardinal(FALSE), 0, ANSI_CHARSET, OUT_TT_PRECIS, CLIP_DEFAULT_PRECIS, PROOF_QUALITY, FIXED_PITCH or FF_MODERN, 'Courier New');
        ReleaseDC(hWnd, DC);

        senddlgitemmessage(hwnd, IDC_LIST1, WM_SETFONT, ffont, ord(TRUE));

        hwndTV := GetDlgItem(hwnd, IDC_LIST1);
        SendMessage(hwndTV, TVM_SETIMAGELIST, 0, hImageList);

        sendmessage(hwnd, WM_SETICON, ICON_BIG, appIcon);

//        sethint(getdlgitem(hwnd, IDC_LIST1), pchar(hint_IDC_LIST1));
        sethint(getdlgitem(hwnd, IDC_BUTTON1), pchar(hint_IDC_BUTTON1));
        sethint(getdlgitem(hwnd, IDC_BUTTON2), pchar(hint_IDC_BUTTON2));
        sethint(getdlgitem(hwnd, IDC_BUTTON_STATUS), pchar(hint_IDC_BUTTON_STATUS));

      end;
    WM_CLOSE:
      EndDialog(hWnd, 0);
    WM_DESTROY:
      Shell_NotifyIcon(NIM_DELETE, @note);
    WM_SIZE:
      if wParam = SIZE_MINIMIZED then begin
        note.cbSize := SizeOf(TNotifyIconData);
        note.Wnd := hWnd;
        note.uID := SC_TRAY;
        note.uFlags := NIF_ICON or NIF_MESSAGE or NIF_TIP;
        note.uCallbackMessage := WM_SHELLNOTIFY;
        note.hIcon := Loadicon(hInstance, MAKEINTRESOURCE(1));
        lstrcpy(note.szTip, pchar(progname));
        ShowWindow(hWnd, SW_HIDE);
        Shell_NotifyIcon(NIM_ADD, @note);
      end;
    WM_SHELLNOTIFY:
      case wParam of
        SC_TRAY:
          case lParam of
            WM_LBUTTONDBLCLK:
              SendMessage(hWnd, WM_COMMAND, SC_RESTORE, 0);
          end;
      end;
    WM_NCLBUTTONDBLCLK:
      begin
        case wParam = HTCAPTION of
          TRUE: Showwindow(hwnd, SW_MINIMIZE);
        end;
      end;
    WM_COMMAND:
      case lParam of
        0: begin
            case LoWord(wParam) of
              SC_RESTORE:
                begin
                  Shell_NotifyIcon(NIM_DELETE, @note);
                  ShowWindow(hWnd, SW_RESTORE);
                  SetFocus(Getdlgitem(hwnd, IDC_BUTTON1));
                end;
              SC_CLOSE:
                begin
                  Shell_NotifyIcon(NIM_DELETE, @note);
                  sendmessage(hwnd, WM_SYSCOMMAND, SC_CLOSE, 0);
                end;
            end;
          end;
      else begin
          if hiword(wparam) = BN_CLICKED then begin
            case loword(wparam) of
              IDC_BUTTON_STATUS:
                begin
                  DialogBox(HInstance, PChar('DIALOG_ABOUT'), hwnd, @DlgFunc_about);
                  SetFocus(Getdlgitem(hwnd, IDC_LIST1));
                end;
              IDC_BUTTON1:
                begin
                  senddlgitemmessage(hwnd, IDC_LIST1, LB_RESETCONTENT, 0, 0);
                  GetNTmachines(Threadbuffer);
                  if length(Threadbuffer) > 0 then begin
                    Threadhandle := CreateThread(nil, 0, @Threadfunc, nil, 0, ThreadID);
                    if threadhandle <> INVALID_HANDLE_VALUE then threadruns := true;
                  end else messagebox(hwnd, 'No such domain', err, 0);
                end;
              IDC_BUTTON2:
                begin
                  ServerBrowseDialogA0(hWnd, @buffer, MAX_PATH);
                  if (buffer[0] = '\') then begin
//eingeloggte user ermitteln
                    setlength(ThreadBuffer, 1);
                    ThreadBuffer[0] := pchar(@buffer[0]);
                    while ThreadBuffer[0][1] = '\' do delete(ThreadBuffer[0], 1, 1);
                    Threadhandle := CreateThread(nil, 0, @Threadfunc, nil, 0, ThreadID);
                    if threadhandle <> INVALID_HANDLE_VALUE then threadruns := true;
                  end;
                end;
            end;
          end;
        end;
      end; //case
  else result := false;
  end;
end;

procedure kick_(message: pchar);
begin
  messagebox(0, message, pchar(err + ' - Quitting'), MB_OK);
  halt($FF);
end;

var
  LANMAN_DLL: DWORD;
begin
  initacomctl;
  initcommoncontrols;
  LANMAN_DLL := GetModuleHandle('NTLANMAN.DLL');
  if LANMAN_DLL = 0 then
    LANMAN_DLL := LoadLibrary('NTLANMAN.DLL');
  if LANMAN_DLL <> 0 then begin
    @ServerBrowseDialogA0 := GetProcAddress(LANMAN_DLL, ServerBrowseDialogA0_name);
    if @ServerBrowseDialogA0 = nil then kick_(err_noentry + ServerBrowseDialogA0_name);
  end;

  LANMAN_DLL := GetModuleHandle('NetAPI32.DLL');
  if LANMAN_DLL = 0 then
    LANMAN_DLL := LoadLibrary('NetAPI32.DLL');
  if LANMAN_DLL <> 0 then begin
    @NetServerEnum := GetProcAddress(LANMAN_DLL, NetServerEnum_name);
    if @NetServerEnum = nil then kick_(err_noentry + NetServerEnum_name);
    @NetApiBufferFree := GetProcAddress(LANMAN_DLL, NetApiBufferFree_name);
    if @NetApiBufferFree = nil then kick_(err_noentry + NetApiBufferFree_name);
  end;

  img_USR := LoadBitmap(hInstance, MAKEINTRESOURCE(300));
  img_WSU := LoadBitmap(hInstance, MAKEINTRESOURCE(301));
  img_WS := LoadBitmap(hInstance, MAKEINTRESOURCE(302));
  hImageList := ImageList_Create(16, 16, ILC_COLOR16, 2, 10);
  ImageList_Add(hImageList, img_WS, 0);
  ImageList_Add(hImageList, img_WSU, 0);
  ImageList_Add(hImageList, img_USR, 0);
  appIcon := LoadIcon(hInstance, MAKEINTRESOURCE(1));
  DialogBox(HInstance, PChar('DIALOG1'), 0, @DlgFunc);
end.

