TYPE
  PSERVER_INFO_100 = ^TSERVER_INFO_100;
  TSERVER_INFO_100 = PACKED RECORD
    sv100_platform_id: INTEGER;
    sv100_name: PWideChar;
  END;

  NET_API_STATUS = DWORD;

  TNetApiBufferFree = FUNCTION(Buffer: Pointer): NET_API_STATUS; stdcall;
  TNetServerEnum = FUNCTION(servername: PWideChar; level: DWORD; VAR bufptr: pointer; prefmaxlen: DWORD; VAR entriesread, totalentries: integer; servertype: DWORD; domain: PWideChar; VAR resume_handle: integer): NET_API_STATUS; stdcall;
  ATStrings = ARRAY OF STRING;

CONST
  MAX_NAME_STRING = 1024;
  SV_TYPE_NT = $00001000;
  PLATFORM_ID_NT = 500;
  NERR_Success = 0;
  MAX_PREFERRED_LENGTH = DWORD(-1);

  NetApiBufferFree_name = 'NetApiBufferFree';
  NetServerEnum_name = 'NetServerEnum';


VAR
  NIL_HANDLE: Integer=0;
  NetApiBufferFree: TNetApiBufferFree = NIL; //NT31+
  NetServerEnum: TNetServerEnum = NIL; //NT31+

PROCEDURE GetLocalLogons(CONST ServerName: STRING; VAR result: ATStrings);
VAR userName,
  domainName: ARRAY[0..MAX_NAME_STRING] OF Char;
  subKeyName: ARRAY[0..MAX_PATH] OF Char;
  subKeyNameSize: DWORD;
  index: DWORD;
  userNameSize: DWORD;
  domainNameSize: DWORD;
  lastWriteTime: FILETIME;
  usersKey: HKEY;
  sid: PSID;
  sidType: SID_NAME_USE;
  authority: SID_IDENTIFIER_AUTHORITY;
  subAuthorityCount: BYTE;
  authorityVal: DWORD;
  revision: DWORD;
  subAuthorityVal: ARRAY[0..7] OF DWORD;

  FUNCTION getvals(s: STRING): integer;
  VAR i, j, k, l: integer;
    tmp: STRING;
  BEGIN
    delete(s, 1, 2);
    j := pos('-', s);
    tmp := copy(s, 1, j - 1);
    val(tmp, revision, k);
    delete(s, 1, j);
    j := pos('-', s);
    tmp := copy(s, 1, j - 1);
    val('$' + tmp, authorityVal, k);
    delete(s, 1, j);
    i := 2;
    s := s + '-';
    FOR l := 0 TO 7 DO BEGIN
      j := pos('-', s);
      IF j > 0 THEN BEGIN
        tmp := copy(s, 1, j - 1);
        val(tmp, subAuthorityVal[l], k);
        delete(s, 1, j);
        inc(i);
      END ELSE break;
    END;
    result := i;
  END;

BEGIN
  setlength(result, 0);
  revision := 0;
  authorityVal := 0;
  FillChar(subAuthorityVal, SizeOf(subAuthorityVal), #0);
  FillChar(userName, SizeOf(userName), #0);
  FillChar(domainName, SizeOf(domainName), #0);
  FillChar(subKeyName, SizeOf(subKeyName), #0);
  IF ServerName <> '' THEN BEGIN
    usersKey := 0;
    IF (RegConnectRegistry(pchar(ServerName), HKEY_USERS, usersKey) <> 0) THEN
      Exit;
  END ELSE BEGIN
    IF (RegOpenKey(HKEY_USERS, NIL, usersKey) <> ERROR_SUCCESS) THEN
      Exit;
  END;
  index := 0;
  subKeyNameSize := SizeOf(subKeyName);
  WHILE (RegEnumKeyEx(usersKey, index, subKeyName, subKeyNameSize, NIL, NIL, NIL, @lastWriteTime) = ERROR_SUCCESS) DO BEGIN
    IF (lstrcmpi(subKeyName, '.default') <> 0) AND (Pos('Classes', STRING(subKeyName)) = 0) THEN BEGIN
      subAuthorityCount := getvals(subKeyName);
      IF (subAuthorityCount >= 3) THEN BEGIN
        subAuthorityCount := subAuthorityCount - 2;
        IF (subAuthorityCount < 2) THEN subAuthorityCount := 2;
        authority.Value[5] := PByte(@authorityVal)^;
        authority.Value[4] := PByte(DWORD(@authorityVal) + 1)^;
        authority.Value[3] := PByte(DWORD(@authorityVal) + 2)^;
        authority.Value[2] := PByte(DWORD(@authorityVal) + 3)^;
        authority.Value[1] := 0;
        authority.Value[0] := 0;
        sid := NIL;
        userNameSize := MAX_NAME_STRING;
        domainNameSize := MAX_NAME_STRING;
        IF AllocateAndInitializeSid(authority, subAuthorityCount, subAuthorityVal[0], subAuthorityVal[1], subAuthorityVal[2], subAuthorityVal[3], subAuthorityVal[4], subAuthorityVal[5], subAuthorityVal[6], subAuthorityVal[7], sid) THEN BEGIN
          IF LookupAccountSid(Pchar(ServerName), sid, userName, userNameSize, domainName, domainNameSize, sidType) THEN BEGIN
            setlength(result, length(result) + 1);
            result[length(result) - 1] := STRING(domainName) + '\' + STRING(userName);
          END;
        END;
        IF Assigned(sid) THEN FreeSid(sid);
      END;
    END;
    subKeyNameSize := SizeOf(subKeyName);
    Inc(index);
  END;
  RegCloseKey(usersKey);
END;

PROCEDURE GetNTmachines(VAR result: ATStrings);
VAR err, i: cardinal;
  x: pointer;
  p: PSERVER_INFO_100;
  _read, _total: integer;
BEGIN
  setlength(result, 0);

  err := NetServerEnum(NIL, 100, x, MAX_PREFERRED_LENGTH, _read, _total, SV_TYPE_NT, NIL, NIL_HANDLE);
  IF err = NERR_Success THEN
  TRY
    p := PSERVER_INFO_100(x);
    FOR i := 0 TO _Read - 1 DO BEGIN
      setlength(result, length(result) + 1);
      result[length(result) - 1] := STRING(pWIDEchar(p^.sv100_name));
      Inc(p);
    END;
  FINALLY
    NetAPIBufferFree(x);
  END;
END;
