unit uRestDriverZEOS;

interface

uses System.SysUtils,          System.Classes,
     ZSqlUpdate,               ZAbstractRODataset,      ZAbstractDataset, ZDataset,
     ZAbstractConnection,      Soap.EncdDecd,           ZConnection, System.JSON,
     Data.DB,                  Data.FireDACJSONReflect, Data.DBXJSONReflect,
     uPoolerMethod,            FireDAC.Stan.StorageBin, Data.DBXPlatform,
     FireDAC.Stan.StorageJSON, DbxCompressionFilter,    uRestCompressTools,
     System.ZLib, uRestPoolerDB, FireDAC.Comp.Client,   FireDAC.Stan.Intf,
     FireDAC.DatS;

{$IFDEF MSWINDOWS}
Type
 TRESTDriverZEOS   = Class(TRESTDriver)
 Private
  vZConnectionBack,
  vZConnection                 : TZConnection;
  Procedure SetConnection(Value : TZConnection);
  Function  GetConnection       : TZConnection;
  Procedure CloneData(Source : TZQuery; Var Dest : TFDMemTable);
 Public
  Procedure ApplyChanges(TableName,
                         SQL               : String;
                         Params            : TParams;
                         Var Error         : Boolean;
                         Var MessageError  : String;
                         Const ADeltaList  : TFDJSONDeltas);Overload;Override;
  Procedure ApplyChanges(TableName,
                         SQL               : String;
                         Var Error         : Boolean;
                         Var MessageError  : String;
                         Const ADeltaList  : TFDJSONDeltas);Overload;Override;
  Function ExecuteCommand(SQL        : String;
                          Var Error  : Boolean;
                          Var MessageError : String;
                          Execute    : Boolean = False) : TFDJSONDataSets;Overload;Override;
  Function ExecuteCommand(SQL              : String;
                          Params           : TParams;
                          Var Error        : Boolean;
                          Var MessageError : String;
                          Execute          : Boolean = False) : TFDJSONDataSets;Overload;Override;
  Function InsertMySQLReturnID(SQL              : String;
                               Var Error        : Boolean;
                               Var MessageError : String) : Integer;Overload;Override;
  Function InsertMySQLReturnID(SQL              : String;
                               Params           : TParams;
                               Var Error        : Boolean;
                               Var MessageError : String) : Integer;Overload;Override;
  Procedure Close;Override;
 Published
  Property Connection : TZConnection Read GetConnection Write SetConnection;
End;
{$ENDIF}

Procedure Register;

implementation

{ TRESTDriver }

{$IFDEF MSWINDOWS}
Procedure Register;
Begin
 RegisterComponents('REST Dataware - Drivers', [TRESTDriverZEOS]);
End;
{$ENDIF}

Procedure TRESTDriverZEOS.CloneData(Source : TZQuery; Var Dest : TFDMemTable);
Var
 I : Integer;
 vFieldType : TFieldType;
Begin
 Dest := TfdMemTable.Create(Nil);
 Dest.Close;
 Dest.FieldDefs.Clear;
 For I := 0 to Source.FieldDefs.Count -1 do
  Begin
   vFieldType := Source.FieldDefs[I].DataType;
   if vFieldType = ftWideString then
    vFieldType := ftString;
   if vFieldType = ftDateTime then
    vFieldType := ftTimeStamp;
   Dest.FieldDefs.Add(Source.FieldDefs[I].Name, vFieldType,
                      Source.FieldDefs[I].Size, Source.FieldDefs[I].Required);
  End;
 Dest.Open;
 Source.First;
 While Not Source.Eof Do
  Begin
   Dest.Insert;
   For I := 0 to Source.Fields.Count -1 do
    Dest.Fields[I].Value := Source.Fields[I].Value;
   Dest.Post;
   Source.Next;
  End;
 Source.First;
End;

procedure TRESTDriverZEOS.ApplyChanges(TableName, SQL: String; var Error: Boolean;
  var MessageError: String; const ADeltaList: TFDJSONDeltas);
begin
  Inherited;
  Error        := True;
  MessageError := 'Method not implemented for the ZEOS Driver.';
end;

procedure TRESTDriverZEOS.ApplyChanges(TableName, SQL: String; Params: TParams;
  var Error: Boolean; var MessageError: String;
  const ADeltaList: TFDJSONDeltas);
begin
  Inherited;
  Error        := True;
  MessageError := 'Method not implemented for the ZEOS Driver.';
end;

Procedure TRESTDriverZEOS.Close;
Begin
  Inherited;
 If Connection <> Nil Then
  Connection.Disconnect;
End;

function TRESTDriverZEOS.ExecuteCommand(SQL: String; Params: TParams;
  var Error: Boolean; var MessageError: String;
  Execute: Boolean): TFDJSONDataSets;
Var
 vTempQuery  : TZQuery;
 A, I        : Integer;
 vTempWriter : TFDJSONDataSetsWriter;
 vParamName  : String;
 Original     : TStringStream;
 gZIPStream   : TMemoryStream;
 oString      : String;
 Len          : Integer;
 tempDataSets : TFDJSONDataSets;
 vTempMemT,
 MemTable     : TFDMemTable;
 Function GetParamIndex(Params : TParams; ParamName : String) : Integer;
 Var
  I : Integer;
 Begin
  Result := -1;
  For I := 0 To Params.Count -1 Do
   Begin
    If UpperCase(Params[I].Name) = UpperCase(ParamName) Then
     Begin
      Result := I;
      Break;
     End;
   End;
 End;
Begin
 Inherited;
 Result := Nil;
 Error  := False;
 vTempQuery               := TZQuery.Create(Owner);
 Try
  vTempQuery.Connection   := vZConnection;
  vTempQuery.SQL.Clear;
  vTempQuery.SQL.Add(DecodeStrings(SQL, GetEncoding(Encoding)));
  If Params <> Nil Then
   Begin
    Try
     vTempQuery.Prepare;
    Except
    End;
    For I := 0 To Params.Count -1 Do
     Begin
      If vTempQuery.Params.Count > I Then
       Begin
        vParamName := Copy(StringReplace(Params[I].Name, ',', '', []), 1, Length(Params[I].Name));
        A          := GetParamIndex(vTempQuery.Params, vParamName);
        If A > -1 Then//vTempQuery.ParamByName(vParamName) <> Nil Then
         Begin
          If vTempQuery.Params[A].DataType in [ftFixedChar, ftFixedWideChar,
                                               ftString,    ftWideString]    Then
           Begin
            If vTempQuery.Params[A].Size > 0 Then
             vTempQuery.Params[A].Value := Copy(Params[I].AsString, 1, vTempQuery.Params[A].Size)
            Else
             vTempQuery.Params[A].Value := Params[I].AsString;
           End
          Else
           Begin
            If vTempQuery.Params[A].DataType in [ftUnknown] Then
             vTempQuery.Params[A].DataType := Params[I].DataType;
            vTempQuery.Params[A].Value    := Params[I].Value;
           End;
         End;
       End
      Else
       Break;
     End;
   End;
  If Not Execute Then
   Begin
//    vTempQuery.Active := True;
    Result            := TFDJSONDataSets.Create;
    vTempWriter       := TFDJSONDataSetsWriter.Create(Result);
    Try
     If Compression Then
      Begin
       tempDataSets := TFDJSONDataSets.Create;
       MemTable     := TFDMemTable.Create(Nil);
       Original     := TStringStream.Create;
       gZIPStream   := TMemoryStream.Create;
       Try
        vTempQuery.Open;
        CloneData(vTempQuery, vTempMemT);
        vTempMemT.SaveToStream(Original, sfJSON);
        vTempMemT.DisposeOf;
        //make it gzip
        doGZIP(Original, gZIPStream);
        MemTable.FieldDefs.Add('compress', ftBlob);
        MemTable.CreateDataSet;
        MemTable.Insert;
        TBlobField(MemTable.FieldByName('compress')).LoadFromStream(gZIPStream);
        MemTable.Post;
        vTempWriter.ListAdd(Result, MemTable);
       Finally
        Original.DisposeOf;
        gZIPStream.DisposeOf;
       End;
      End
     Else
      Begin
       CloneData(vTempQuery, vTempMemT);
       vTempWriter.ListAdd(Result, vTempMemT);
//       vTempMemT.DisposeOf;
      End;
    Finally
     vTempWriter := Nil;
     vTempWriter.DisposeOf;
    End;
   End
  Else
   Begin
    vTempQuery.ExecSQL;
    vZConnection.Commit;
   End;
 Except
  On E : Exception do
   Begin
    Try
     vZConnection.Rollback;
    Except
    End;
    Error := True;
    MessageError := E.Message;
   End;
 End;
 GetInvocationMetaData.CloseSession := True;
End;

function TRESTDriverZEOS.ExecuteCommand(SQL: String; var Error: Boolean;
  var MessageError: String; Execute: Boolean): TFDJSONDataSets;
Var
 vTempQuery   : TZQuery;
 vTempWriter  : TFDJSONDataSetsWriter;
 Original,
 gZIPStream   : TMemoryStream;
 oString      : String;
 Len          : Integer;
 tempDataSets : TFDJSONDataSets;
 vTempMemT,
 MemTable     : TFDMemTable;
Begin
 Inherited;
 Result := Nil;
 Error  := False;
 vTempQuery               := TZQuery.Create(Owner);
 Try
  if not vZConnection.Connected then
  vZConnection.Connected :=true;
  vTempQuery.Connection   := vZConnection;
  vTempQuery.SQL.Clear;
  vTempQuery.SQL.Add(DecodeStrings(SQL, GetEncoding(Encoding)));
  If Not Execute Then
   Begin
    vTempQuery.Open;
    Result            := TFDJSONDataSets.Create;
    vTempWriter       := TFDJSONDataSetsWriter.Create(Result);
    Try
     If Compression Then
      Begin
       tempDataSets := TFDJSONDataSets.Create;
       MemTable     := TFDMemTable.Create(Nil);
       Original     := TStringStream.Create;
       gZIPStream   := TMemoryStream.Create;
       Try
        //make it gzip
        CloneData(vTempQuery, vTempMemT);
        vTempMemT.SaveToStream(Original, sfJSON);
        vTempMemT.DisposeOf;
        doGZIP(Original, gZIPStream);
        MemTable.FieldDefs.Add('compress', ftBlob);
        MemTable.CreateDataSet;
        MemTable.Insert;
        TBlobField(MemTable.FieldByName('compress')).LoadFromStream(gZIPStream);
        MemTable.Post;
        vTempWriter.ListAdd(Result, MemTable);
       Finally
        Original.DisposeOf;
        gZIPStream.DisposeOf;
       End;
      End
     Else
      Begin
       CloneData(vTempQuery, vTempMemT);
       vTempWriter.ListAdd(Result, vTempMemT);
//       vTempMemT.DisposeOf;
      End;
    Finally
     vTempWriter := Nil;
     vTempWriter.DisposeOf;
    End;
   End
  Else
   Begin
    vTempQuery.ExecSQL;
    vZConnection.Commit;
   End;
 Except
  On E : Exception do
   Begin
    Try
     vZConnection.Rollback;
    Except
    End;
    Error := True;
    MessageError := E.Message;
   End;
 End;
End;

Function TRESTDriverZEOS.GetConnection: TZConnection;
Begin
 Result := vZConnectionBack;
End;

Function TRESTDriverZEOS.InsertMySQLReturnID(SQL: String; Params: TParams;
  var Error: Boolean; var MessageError: String): Integer;
Var
 A, I        : Integer;
 vParamName  : String;
 fdCommand   : TZQuery;
 Function GetParamIndex(Params : TParams; ParamName : String) : Integer;
 Var
  I : Integer;
 Begin
  Result := -1;
  For I := 0 To Params.Count -1 Do
   Begin
    If UpperCase(Params[I].Name) = UpperCase(ParamName) Then
     Begin
      Result := I;
      Break;
     End;
   End;
 End;
Begin
  Inherited;
 Result := -1;
 Error  := False;
 fdCommand := TZQuery.Create(Owner);
 Try
  fdCommand.Connection := vZConnection;
  fdCommand.SQL.Clear;
  fdCommand.SQL.Add(DecodeStrings(SQL, GetEncoding(Encoding)) + '; SELECT LAST_INSERT_ID()ID');
  If Params <> Nil Then
   Begin
    For I := 0 To Params.Count -1 Do
     Begin
      If fdCommand.Params.Count > I Then
       Begin
        vParamName := Copy(StringReplace(Params[I].Name, ',', '', []), 1, Length(Params[I].Name));
        A          := GetParamIndex(fdCommand.Params, vParamName);
        If A > -1 Then
         fdCommand.Params[A].Value := Params[I].Value;
       End
      Else
       Break;
     End;
   End;
  fdCommand.Open;
  Result := StrToInt(fdCommand.FindField('ID').AsString);
  vZConnection.Commit;
 Except
  On E : Exception do
   Begin
    vZConnection.Rollback;
    Error        := True;
    MessageError := E.Message;
   End;
 End;
 fdCommand.Close;
 FreeAndNil(fdCommand);
 GetInvocationMetaData.CloseSession := True;
End;

Function TRESTDriverZEOS.InsertMySQLReturnID(SQL: String; var Error: Boolean;
                                         Var MessageError: String): Integer;
Var
 A, I        : Integer;
 fdCommand   : TZQuery;
Begin
  Inherited;
 Result := -1;
 Error  := False;
 fdCommand := TZQuery.Create(Owner);
 Try
  fdCommand.Connection := vZConnection;
  fdCommand.SQL.Clear;
  fdCommand.SQL.Add(DecodeStrings(SQL, GetEncoding(Encoding)) + '; SELECT LAST_INSERT_ID()ID');
  fdCommand.Open;
  Result := StrToInt(fdCommand.FindField('ID').AsString);
  vZConnection.Commit;
 Except
  On E : Exception do
   Begin
    vZConnection.Rollback;
    Error        := True;
    MessageError := E.Message;
   End;
 End;
 fdCommand.Close;
 FreeAndNil(fdCommand);
 GetInvocationMetaData.CloseSession := True;
End;

Procedure TRESTDriverZEOS.SetConnection(Value: TZConnection);
Begin
 vZConnectionBack := Value;
 If Value <> Nil Then
  vZConnection    := vZConnectionBack
 Else
  Begin
   If vZConnection <> Nil Then
    vZConnection.Disconnect;
  End;
End;

end.
