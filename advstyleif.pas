{***************************************************************************}
{ TAdvStyleIF interface                                                     }
{ for Delphi & C++Builder                                                   }
{                                                                           }
{ written by TMS Software                                                   }
{            copyright � 2006 - 2011                                        }
{            Email : info@tmssoftware.com                                   }
{            Web : http://www.tmssoftware.com                               }
{                                                                           }
{ The source code is given as is. The author is not responsible             }
{ for any possible damage done due to the use of this code.                 }
{ The component can be freely used in any application. The complete         }
{ source code remains property of the author and may not be distributed,    }
{ published, given or sold in any form as such. No parts of the source      }
{ code can be included in any other component or application without        }
{ written authorization of the author.                                      }
{***************************************************************************}

unit AdvStyleIF;

interface

{$I TMSDEFS.INC}

uses
  Classes, Registry, SysUtils, Windows, Messages, Controls, Forms;

const
  WM_OFFICETHEMECHANGED  = WM_USER + 1969;

  {$IFDEF DELPHI2007_LVL}
  {$EXTERNALSYM WM_THEMECHANGED}
  {$ENDIF}

  WM_THEMECHANGED = $031A;

//Need to redeclare the API function - instead of BOOL is uses DWORD.
function RegNotifyChangeKeyValue(hKey: HKEY; bWatchSubtree: DWORD; dwNotifyFilter: DWORD; hEvent: THandle; fAsynchronus: DWORD): Longint; stdcall;
external 'advapi32.dll' name 'RegNotifyChangeKeyValue';

type
  TTMSStyle = (tsOffice2003Blue, tsOffice2003Silver, tsOffice2003Olive, tsOffice2003Classic,
    tsOffice2007Luna, tsOffice2007Obsidian, tsWindowsXP, tsWhidbey, tsCustom, tsOffice2007Silver, tsWindowsVista,
    tsWindows7, tsTerminal, tsOffice2010Blue, tsOffice2010Silver, tsOffice2010Black);


  XPColorScheme = (xpNone, xpBlue, xpGreen, xpGray);

  TOfficeVersion = (ov2003, ov2007, ov2010);

  TOfficeTheme = (ot2003Blue,ot2003Silver,ot2003Olive,ot2003Classic,ot2007Blue,ot2007Silver,ot2007Black,ot2010Blue,ot2010Silver,ot2010Black,otUnknown);

  ITMSStyle = interface
  ['{11AC2DDC-C087-4298-AB6E-EA1B5017511B}']
    procedure SetComponentStyle(AStyle: TTMSStyle);
//    procedure SaveToTheme(FileName: String);
//    procedure LoadFromTheme(FileName: String);
//    function GetThemeID: String;
  end;

  THandleList = class(TList)
  private
    procedure SetInteger(Index: Integer; Value: Integer);
    function GetInteger(Index: Integer):Integer;
  public
    constructor Create;
    procedure DeleteValue(Value: Integer);
    function HasValue(Value: Integer): Boolean;
    {$IFNDEF DELPHI6_LVL}
    procedure Assign(AList: TList);
    {$ENDIF}
    property Items[index: Integer]: Integer read GetInteger write SetInteger; default;
    procedure Add(Value: Integer);
    procedure Insert(Index,Value: Integer);
    procedure Delete(Index: Integer);
  end;


  TRegMonitorThread = class(TThread)
  private
    FReg: TRegistry;
    FEvent: Integer;
    FKey: string;
    FRootKey: HKey;
    FWatchSub: boolean;
    FFilter: integer;
    FWnd: THandle;
    FWinList: THandleList;
    procedure InitThread;
    procedure SetFilter(const Value: integer);
    function GetFilter: integer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Stop;
    property Key: string read FKey write FKey;
    property RootKey: HKey read FRootKey write FRootKey;
    property WatchSub: boolean read FWatchSub write FWatchSub;
    property Filter: integer read GetFilter write SetFilter;
    property Wnd: THandle read FWnd write FWnd;
    property WinList: THandleList read FWinList;
  protected
    procedure Execute; override;
  end;

  TThemeNotifierWindow = class(TWinControl)
  private
    FOnOfficeThemeChange: TNotifyEvent;
  protected
    procedure WndProc(var Msg: TMessage); override;
  published
    property OnOfficeThemeChange: TNotifyEvent read FOnOfficeThemeChange write FOnOfficeThemeChange;
  end;

  TThemeNotifier = class(TComponent)
  private
    RegMonitorThread : TRegMonitorThread;
    FNotifier: TThemeNotifierWindow;
    FOnOfficeThemeChange: TNotifyEvent;
  protected
    procedure OfficeThemeChanged(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure RegisterWindow(Hwnd: THandle);
    procedure UnRegisterWindow(Hwnd: THandle);
  published
    property OnOfficeThemeChange: TNotifyEvent read FOnOfficeThemeChange write FOnOfficeThemeChange;
  end;

function ThemeNotifier(AParent: TWinControl): TThemeNotifier;
function IsVista: boolean;
function GetOfficeVersion: TOfficeVersion;
function GetOfficeTheme: TOfficeTheme;
function IsThemedApp: boolean;

var
  ThemeNotifierInstance: TThemeNotifier;

implementation

uses
  Dialogs;


{$IFNDEF TMSDOTNET}
var
  GetCurrentThemeName: function(pszThemeFileName: PWideChar;
    cchMaxNameChars: Integer;
    pszColorBuff: PWideChar;
    cchMaxColorChars: Integer;
    pszSizeBuff: PWideChar;
    cchMaxSizeChars: Integer): THandle cdecl stdcall;

  IsThemeActive: function: BOOL cdecl stdcall;
{$ENDIF}

//------------------------------------------------------------------------------

{$IFNDEF DELPHI7_LVL}
{$IFNDEF TMSDOTNET}
function GetFileVersion(FileName:string): Integer;
var
  FileHandle:dword;
  l: Integer;
  pvs: PVSFixedFileInfo;
  lptr: uint;
  querybuf: array[0..255] of char;
  buf: PChar;
begin
  Result := -1;

  StrPCopy(querybuf,FileName);
  l := GetFileVersionInfoSize(querybuf,FileHandle);
  if (l>0) then
  begin
    GetMem(buf,l);
    GetFileVersionInfo(querybuf,FileHandle,l,buf);
    if VerQueryValue(buf,'\',Pointer(pvs),lptr) then
    begin
      if (pvs^.dwSignature=$FEEF04BD) then
      begin
        Result := pvs^.dwFileVersionMS;
      end;
    end;
    FreeMem(buf);
  end;
end;
{$ENDIF}
{$ENDIF}

//------------------------------------------------------------------------------

function IsThemedApp: Boolean;
var
  i: Integer;
begin
  // app is linked with COMCTL32 v6 or higher -> xp themes enabled
  i := GetFileVersion('COMCTL32.DLL');
  i := (i shr 16) and $FF;
  Result := (i > 5);
end;

//------------------------------------------------------------------------------

function IsVista: boolean;
var
  hKernel32: HMODULE;
begin
  hKernel32 := GetModuleHandle('kernel32');
  if (hKernel32 > 0) then
  begin
    Result := GetProcAddress(hKernel32, 'GetLocaleInfoEx') <> nil;
  end
  else
    Result := false;
end;

//------------------------------------------------------------------------------

function GetOfficeVersion: TOfficeVersion;
var
  reg: TRegistry;
begin
  Result := ov2003;

  reg := TRegistry.Create;
  reg.RootKey := HKEY_CURRENT_USER;

  if reg.KeyExists('Software\Microsoft\Office\11.0\Common\General') then
    Result := ov2003;

  if reg.KeyExists('Software\Microsoft\Office\12.0\Common\General') then
    Result := ov2007;

  if reg.KeyExists('Software\Microsoft\Office\14.0\Common\General') then
    Result := ov2010;

  reg.Free;
end;

//------------------------------------------------------------------------------

{$IFNDEF TMSDOTNET}
function IsWinXP: Boolean;
var
  VerInfo: TOSVersioninfo;
begin
  VerInfo.dwOSVersionInfoSize := SizeOf(TOSVersionInfo);
  GetVersionEx(verinfo);
  Result := (verinfo.dwMajorVersion > 5) OR
    ((verinfo.dwMajorVersion = 5) AND (verinfo.dwMinorVersion >= 1));
end;

//------------------------------------------------------------------------------

function CurrentXPTheme: XPColorScheme;
var
  FileName, ColorScheme, SizeName: WideString;
  hThemeLib: THandle;
begin
  hThemeLib := 0;

  Result := xpNone;

  if not IsWinXP then
    Exit;

  try
    hThemeLib := LoadLibrary('uxtheme.dll');

    if hThemeLib > 0 then
    begin
      IsThemeActive := GetProcAddress(hThemeLib,'IsThemeActive');

      if Assigned(IsThemeActive) then
        if IsThemeActive and IsThemedApp then
        begin
          GetCurrentThemeName := GetProcAddress(hThemeLib,'GetCurrentThemeName');
          if Assigned(GetCurrentThemeName) then
          begin
            SetLength(FileName, 255);
            SetLength(ColorScheme, 255);
            SetLength(SizeName, 255);

            GetCurrentThemeName(PWideChar(FileName), 255,
              PWideChar(ColorScheme), 255, PWideChar(SizeName), 255);

            {$IFDEF DELPHI_UNICODE}
            if StrPos('NormalColor',PWideChar(ColorScheme)) <> nil then
              Result := xpBlue
            else if StrPos('HomeStead',PWideChar(ColorScheme)) <> nil then
              Result := xpGreen
            else if StrPos('Metallic',PWideChar(ColorScheme)) <> nil then
              Result := xpGray
            else
              Result := xpNone;

            {$ENDIF}
            {$IFNDEF DELPHI_UNICODE}
            if (PWideChar(ColorScheme) = 'NormalColor') then
              Result := xpBlue
            else if (PWideChar(ColorScheme) = 'HomeStead') then
              Result := xpGreen
            else if (PWideChar(ColorScheme) = 'Metallic') then
              Result := xpGray
            else
              Result := xpNone;
            {$ENDIF}
          end;
        end;
    end;
  finally
    if hThemeLib <> 0 then
      FreeLibrary(hThemeLib);
  end;
end;
{$ENDIF}

//------------------------------------------------------------------------------

function GetOfficeThemeValue(reg: TRegistry; key: string): integer;
begin
  Result := -1;

  if reg.KeyExists(key) then
  begin
    reg.OpenKey(key, false);
    if reg.ValueExists('Theme') then
      Result := reg.ReadInteger('Theme');
    reg.CloseKey;
  end;
end;

//------------------------------------------------------------------------------

function GetOfficeTheme: TOfficeTheme;
var
  reg: TRegistry;
  i: integer;

begin
  Result := ot2003Blue;

  {$IFNDEF TMSDOTNET}
  reg := TRegistry.Create;
  reg.RootKey := HKEY_CURRENT_USER;

  // Office 2010?
  i := GetOfficeThemeValue(reg,'Software\Microsoft\Office\14.0\Common');

  if (i <> -1) then
  begin
    case i of
    1: Result := ot2010Blue;
    2: Result := ot2010Silver;
    3: Result := ot2010Black;
    end;
  end
  else
  begin
    // Office 2007?
    i := GetOfficeThemeValue(reg,'Software\Microsoft\Office\12.0\Common');

    if (i <> -1) then
    begin
      case i of
      1: Result := ot2007Blue;
      2: Result := ot2007Silver;
      3: Result := ot2007Black;
      end;
    end
    else
    begin
      // Office 2003?
      case CurrentXPTheme of
      xpNone: Result := ot2003Classic;
      xpBlue: Result := ot2003Blue;
      xpGreen: Result := ot2003Olive;
      xpGray: Result := ot2003Silver;
      end;
    end;
  end;

  reg.Free;
  {$ENDIF}
end;

//------------------------------------------------------------------------------


function ThemeNotifier(AParent: TWinControl): TThemeNotifier;
begin
  if not Assigned(ThemeNotifierInstance) then
  begin
    if Assigned(Application.MainForm) and Application.MainForm.HandleAllocated then
      ThemeNotifierInstance := TThemeNotifier.Create(Application.MainForm)
    else
      ThemeNotifierInstance := TThemeNotifier.Create(AParent);
  end;
  Result := ThemeNotifierInstance;
end;

//------------------------------------------------------------------------------

{ TRegMonitorThread }
constructor TRegMonitorThread.Create;
begin
  // Execute won�t be called until after Resume is called.
  inherited Create(True);
  FReg := TRegistry.Create;
  FWinList := THandleList.Create;
end;

destructor TRegMonitorThread.Destroy;
begin
  FWinList.Free;
  FReg.Free;
  inherited;
end;

procedure TRegMonitorThread.InitThread;
begin
  FReg.RootKey := RootKey;
  if not FReg.OpenKeyReadOnly(Key) then
  begin
    raise Exception.Create('Unable to open registry key ' + Key);
  end;
  FEvent := CreateEvent(nil, True, False, 'RegMonitorChange');
  RegNotifyChangeKeyValue(FReg.CurrentKey, 1, Filter, FEvent, 1);
end;

procedure TRegMonitorThread.Execute;
var
  i: integer;
begin
  InitThread;

  while not Terminated do
  begin
    if WaitForSingleObject(FEvent, INFINITE) = WAIT_OBJECT_0 then
    begin
      if Terminated then
        Exit;

      {$IFNDEF TMSDOTNET}
      // Notify notifier Window
      if Wnd <> 0 then
        SendMessage(Wnd, WM_OFFICETHEMECHANGED, RootKey, LongInt(PChar(Key)));

      for i := 0 to WinList.Count - 1 do
        SendMessage(WinList.Items[i], WM_OFFICETHEMECHANGED, RootKey, LongInt(PChar(Key)));
      {$ENDIF}

      ResetEvent(FEvent);
      RegNotifyChangeKeyValue(FReg.CurrentKey, 1, Filter, FEvent, 1);
    end;
  end;
end;

procedure TRegMonitorThread.SetFilter(const Value: integer);
begin
  if fFilter <> Value then
    fFilter := Value;
end;

procedure TRegMonitorThread.Stop;
begin
  Terminate;
  Windows.SetEvent(FEvent);
end;

function TRegMonitorThread.GetFilter: integer;
begin
  if fFilter = 0 then
  begin
    fFilter := REG_NOTIFY_CHANGE_NAME or
      REG_NOTIFY_CHANGE_ATTRIBUTES or
      REG_NOTIFY_CHANGE_LAST_SET or
      REG_NOTIFY_CHANGE_SECURITY;
  end;
  Result := fFilter;
end;

//------------------------------------------------------------------------------

{ TNotifierWindow }

procedure TThemeNotifierWindow.WndProc(var Msg: TMessage);
begin
  if (Msg.Msg = WM_OFFICETHEMECHANGED) then
  begin
    if Assigned(FOnOfficeThemeChange) then
    begin
      FOnOfficeThemeChange(Self);
    end;
  end;
  inherited;
end;

//------------------------------------------------------------------------------

{ TThemeNotifier }

constructor TThemeNotifier.Create(AOwner: TComponent);
var
  ov: TOfficeVersion;
begin
  inherited;
  RegMonitorThread := nil;

  if not (csDesigning in ComponentState) then
  begin
    ov := GetOfficeVersion;

    if (ov in [ov2007, ov2010]) then
    begin
      FNotifier := TThemeNotifierWindow.Create(Self);
      FNotifier.Parent := (AOwner as TWinControl);
      FNotifier.Visible := false;
      FNotifier.OnOfficeThemeChange := OfficeThemeChanged;

      RegMonitorThread := TRegMonitorThread.Create;

      with RegMonitorThread do
      begin
        FreeOnTerminate := True;
        Wnd := FNotifier.Handle;
        Filter := REG_NOTIFY_CHANGE_LAST_SET;

        if ov = ov2010 then
          Key := 'Software\Microsoft\Office\14.0\Common'
        else
          Key := 'Software\Microsoft\Office\12.0\Common';

        RootKey := HKEY_CURRENT_USER;
        WatchSub := True;
        {$IFDEF DELPHI2010_LVL}
        Start;
        {$ENDIF}
        {$IFNDEF DELPHI2010_LVL}
        Resume;
        {$ENDIF}
      end;
    end;
  end;
end;

destructor TThemeNotifier.Destroy;
begin
  if Assigned(RegMonitorThread) then
    RegMonitorThread.Stop;
  ThemeNotifierInstance := nil;
  inherited;
end;

procedure TThemeNotifier.OfficeThemeChanged(Sender: TObject);
begin
  if Assigned(OnOfficeThemeChange) then
    OnOfficeThemeChange(Self);
end;

procedure TThemeNotifier.RegisterWindow(Hwnd: THandle);
begin
  if Assigned(RegMonitorThread) and not RegMonitorThread.WinList.HasValue(Hwnd) then
    RegMonitorThread.WinList.Add(Hwnd);
end;

procedure TThemeNotifier.UnRegisterWindow(Hwnd: THandle);
begin
  if Assigned(RegMonitorThread) then
    RegMonitorThread.WinList.DeleteValue(Hwnd);
end;

//------------------------------------------------------------------------------

{ THandleList }

constructor THandleList.Create;
begin
  inherited Create;
end;

procedure THandleList.SetInteger(Index:Integer;Value:Integer);
begin
  {$IFDEF TMSDOTNET}
  inherited Items[Index] := TObject(Value);
  {$ENDIF}

  {$IFNDEF TMSDOTNET}
  inherited Items[Index] := Pointer(Value);
  {$ENDIF}
end;

function THandleList.GetInteger(Index: Integer): Integer;
begin
  Result := Integer(inherited Items[Index]);
end;

procedure THandleList.DeleteValue(Value: Integer);
var
  i: integer;
begin
  {$IFNDEF TMSDOTNET}
  i := IndexOf(Pointer(Value));
  {$ENDIF}

  {$IFDEF TMSDOTNET}
  i := IndexOf(TObject(Value));
  {$ENDIF}

  if i <> -1 then
    Delete(i);
end;

{$IFNDEF DELPHI6_LVL}
procedure THandleList.Assign(AList: TList);
var
  j: integer;
begin
  Clear;

  if Assigned(AList) then
  begin
    for J := 0 to AList.Count - 1 do
      Add(integer(AList[J]));
  end;
end;
{$ENDIF}

function THandleList.HasValue(Value: Integer): Boolean;
begin
  {$IFNDEF TMSDOTNET}
  Result := IndexOf(Pointer(Value)) <> -1;
  {$ENDIF}

  {$IFDEF TMSDOTNET}
  Result := IndexOf(TObject(Value)) <> -1;
  {$ENDIF}
end;


procedure THandleList.Add(Value: Integer);
begin
  {$IFDEF TMSDOTNET}
  inherited Add(TObject(Value));
  {$ENDIF}

  {$IFNDEF TMSDOTNET}
  inherited Add(Pointer(Value));
  {$ENDIF}
end;

procedure THandleList.Delete(Index: Integer);
begin
  inherited Delete(Index);
end;


procedure THandleList.Insert(Index, Value: Integer);
begin
  {$IFDEF TMSDOTNET}
  inherited Insert(Index, TObject(Value));
  {$ENDIF}

  {$IFNDEF TMSDOTNET}
  inherited Insert(Index, Pointer(Value));
  {$ENDIF}
end;


initialization
  ThemeNotifierInstance  := nil;

finalization

end.
