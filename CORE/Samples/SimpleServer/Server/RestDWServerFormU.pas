unit RestDWServerFormU;

Interface

Uses Winapi.Windows,    Winapi.Messages, System.SysUtils,         System.Variants,
     System.Classes,    Vcl.Graphics,    Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
     winsock,           Winapi.iphlpapi, Winapi.IpTypes, uSock,   System.IniFiles,
     Vcl.AppEvnts,      Vcl.StdCtrls,    Web.HTTPApp,             Vcl.ExtCtrls,
     Vcl.Imaging.jpeg,  Vcl.Imaging.pngimage, Vcl.Mask,           Vcl.Menus,
     uRESTDWBase,       ServerMethodsUnit1, Vcl.ComCtrls, FireDAC.Phys.FBDef,
  FireDAC.UI.Intf, FireDAC.VCLUI.Wait, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Error, FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool,
  FireDAC.Stan.Async, FireDAC.Phys, FireDAC.Phys.FB, Data.DB,
  FireDAC.Comp.Client, FireDAC.Comp.UI, FireDAC.Phys.IBBase,
  FireDAC.Stan.StorageJSON;

type
  TRestDWForm = class(TForm)
    ButtonStart: TButton;
    ButtonStop: TButton;
    Label8: TLabel;
    Bevel3: TBevel;
    lSeguro: TLabel;
    cbPoolerState: TCheckBox;
    PageControl1: TPageControl;
    tsConfigs: TTabSheet;
    tsLogs: TTabSheet;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label7: TLabel;
    Label9: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label13: TLabel;
    Bevel1: TBevel;
    Bevel2: TBevel;
    Label12: TLabel;
    Label14: TLabel;
    Label6: TLabel;
    Image1: TImage;
    Label5: TLabel;
    Bevel4: TBevel;
    Label4: TLabel;
    Label15: TLabel;
    Label16: TLabel;
    Label17: TLabel;
    edPortaDW: TEdit;
    edUserNameDW: TEdit;
    edPasswordDW: TEdit;
    cbAdaptadores: TComboBox;
    edPortaBD: TEdit;
    edUserNameBD: TEdit;
    edPasswordBD: TEdit;
    edPasta: TEdit;
    edBD: TEdit;
    ePrivKeyFile: TEdit;
    eCertFile: TEdit;
    ePrivKeyPass: TMaskEdit;
    ApplicationEvents1: TApplicationEvents;
    ctiPrincipal: TTrayIcon;
    pmMenu: TPopupMenu;
    RestaurarAplicao1: TMenuItem;
    N5: TMenuItem;
    SairdaAplicao1: TMenuItem;
    memoReq: TMemo;
    memoResp: TMemo;
    Label19: TLabel;
    Label18: TLabel;
    FDStanStorageJSONLink1: TFDStanStorageJSONLink;
    FDPhysFBDriverLink1: TFDPhysFBDriverLink;
    FDGUIxWaitCursor1: TFDGUIxWaitCursor;
    Server_FDConnection: TFDConnection;
    cbEncode: TCheckBox;
    RESTServicePooler1: TRESTServicePooler;
    CheckBox1: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure ApplicationEvents1Idle(Sender: TObject; var Done: Boolean);
    procedure ButtonStartClick(Sender: TObject);
    procedure ButtonStopClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure cbAdaptadoresChange(Sender: TObject);
    procedure ctiPrincipalDblClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure SairdaAplicao1Click(Sender: TObject);
    procedure RestaurarAplicao1Click(Sender: TObject);
    procedure RESTServicePooler1LastRequest(Value: string);
    procedure RESTServicePooler1LastResponse(Value: string);
    procedure Server_FDConnectionBeforeConnect(Sender: TObject);
  Private
   {Private declarations}
   vDatabaseName,
   FCfgName,
   vDatabaseIP,
   vUsername,
   vPassword  : String;
   Procedure StartServer;
   Function  GetHandleOnTaskBar : THandle;
   Procedure ChangeStatusWindow;
   Procedure HideApplication;
  Public
   {Public declarations}
   Procedure ShowBalloonTips(IconMessage : Integer = 0; MessageValue : String = '');
   Procedure ShowApplication;
   Property  Username   : String Read vUsername   Write vUsername;
   Property  Password   : String Read vPassword   Write vPassword;
   Property  DatabaseIP : String Read vDatabaseIP Write vDatabaseIP;
  End;

var
  RestDWForm : TRestDWForm;

implementation

{$IFDEF FPC}
{$R *.lfm}
{$ELSE}
{$R *.dfm}
{$ENDIF}

uses
  Winapi.ShellApi, uDmService;

Function TRestDWForm.GetHandleOnTaskBar : THandle;
Begin
 {$IFDEF COMPILER11_UP}
 If Application.MainFormOnTaskBar And Assigned(Application.MainForm) Then
  Result := Application.MainForm.Handle
 Else
 {$ENDIF COMPILER11_UP}
  Result := Application.Handle;
End;

Procedure TRestDWForm.ChangeStatusWindow;
Begin
 if Self.Visible then
  SairdaAplicao1.Caption := 'Minimizar para a bandeja'
 Else
  SairdaAplicao1.Caption := 'Sair da Aplica��o';
 Application.ProcessMessages;
End;

procedure TRestDWForm.ctiPrincipalDblClick(Sender: TObject);
begin
 ShowApplication;
end;

Procedure TRestDWForm.HideApplication;
Begin
 ctiPrincipal.Visible := True;
 Application.ShowMainForm := False;
 If Self <> Nil Then
  Self.Visible := False;
 Application.Minimize;
 ShowWindow(GetHandleOnTaskBar, SW_HIDE);
 ChangeStatusWindow;
End;

procedure TRestDWForm.RestaurarAplicao1Click(Sender: TObject);
begin
 ShowApplication;
end;

procedure TRestDWForm.RESTServicePooler1LastRequest(Value: string);
begin
 memoReq.Lines.Add(Value);
end;

procedure TRestDWForm.RESTServicePooler1LastResponse(Value: string);
begin
 memoResp.Lines.Clear;
 memoResp.Lines.Add(Value);
end;

procedure TRestDWForm.SairdaAplicao1Click(Sender: TObject);
begin
 Close;
end;

procedure TRestDWForm.Server_FDConnectionBeforeConnect(Sender: TObject);
Var
 porta_BD,
 servidor,
 database,
 pasta,
 usuario_BD,
 senha_BD      : String;
Begin
 servidor      := vDatabaseIP;
 database      := edBD.Text;
 pasta         := IncludeTrailingPathDelimiter(edPasta.Text);
 porta_BD      := edPortaBD.Text;
 usuario_BD    := edUserNameBD.Text;
 senha_BD      := edPasswordBD.Text;
 vDatabaseName := pasta + database;
 TFDConnection(Sender).Params.Clear;
 TFDConnection(Sender).Params.Add('DriverID=FB');
 TFDConnection(Sender).Params.Add('Server='    + Servidor);
 TFDConnection(Sender).Params.Add('Port='      + porta_BD);
 TFDConnection(Sender).Params.Add('Database='  + vDatabaseName);
 TFDConnection(Sender).Params.Add('User_Name=' + usuario_BD);
 TFDConnection(Sender).Params.Add('Password='  + senha_BD);
 TFDConnection(Sender).Params.Add('Protocol=TCPIP');
 //Server_FDConnection.Params.Add('CharacterSet=ISO8859_1');
 TFDConnection(Sender).UpdateOptions.CountUpdatedRecords := False;
end;

Procedure TRestDWForm.ShowApplication;
Begin
 ctiPrincipal.Visible := False;
 Application.ShowMainForm    := True;
 If Self <> Nil Then
  Begin
   Self.Visible     := True;
   Self.WindowState := wsNormal;
  End;
 ShowWindow(GetHandleOnTaskBar, SW_SHOW);
 ChangeStatusWindow;
End;

Procedure TRestDWForm.ShowBalloonTips(IconMessage : Integer = 0; MessageValue : String = '');
Begin
 Case IconMessage Of
  0 : ctiPrincipal.BalloonFlags := bfInfo;
  1 : ctiPrincipal.BalloonFlags := bfWarning;
  2 : ctiPrincipal.BalloonFlags := bfError;
  Else
   ctiPrincipal.BalloonFlags := bfInfo;
 End;
 ctiPrincipal.BalloonTitle := RestDWForm.Caption;
 ctiPrincipal.BalloonHint  := MessageValue;
 ctiPrincipal.ShowBalloonHint;
 Application.ProcessMessages;
End;

Procedure TRestDWForm.ApplicationEvents1Idle(Sender: TObject; var Done: Boolean);
Begin
 ButtonStart.Enabled   := Not RESTServicePooler1.Active;
 ButtonStop.Enabled    := RESTServicePooler1.Active;
 edPortaDW.Enabled     := ButtonStart.Enabled;
 edUserNameDW.Enabled  := ButtonStart.Enabled;
 edPasswordDW.Enabled  := ButtonStart.Enabled;
 cbAdaptadores.Enabled := ButtonStart.Enabled;
 edPortaBD.Enabled     := ButtonStart.Enabled;
 edPasta.Enabled       := ButtonStart.Enabled;
 edBD.Enabled          := ButtonStart.Enabled;
 edUserNameBD.Enabled  := ButtonStart.Enabled;
 edPasswordBD.Enabled  := ButtonStart.Enabled;
 ePrivKeyFile.Enabled  := ButtonStart.Enabled;
 ePrivKeyPass.Enabled  := ButtonStart.Enabled;
 eCertFile.Enabled     := ButtonStart.Enabled;
End;

procedure TRestDWForm.ButtonStartClick(Sender: TObject);
Var
 ini       : TIniFile;
Begin
 If FileExists(FCfgName) Then
  DeleteFile(FCfgName);
 ini       := TIniFile.Create(FCfgName);
 ini.WriteString('BancoDados', 'Servidor',  cbAdaptadores.Text);//  '127.0.0.1');
 ini.WriteString('BancoDados', 'BD',        edBD.Text);
 ini.WriteString('BancoDados', 'Pasta',     edPasta.Text);
 ini.WriteString('BancoDados', 'PortaDB',   edPortaBD.Text);
 ini.WriteString('BancoDados', 'PortaDW',   edPortaDW.Text);
 ini.WriteString('BancoDados', 'UsuarioBD', edUserNameBD.Text);
 ini.WriteString('BancoDados', 'SenhaBD',   edPasswordBD.Text);
 ini.WriteString('BancoDados', 'UsuarioDW', edUserNameDW.Text);
 ini.WriteString('BancoDados', 'SenhaDW',   edPasswordDW.Text);
 ini.WriteString('SSL',        'PKF',       ePrivKeyFile.Text);
 ini.WriteString('SSL',        'PKP',       ePrivKeyPass.Text);
 ini.WriteString('SSL',        'CF',        eCertFile.Text);
 ini.Free;
 vUsername := edUserNameDW.Text;
 vPassword := edPasswordDW.Text;
 StartServer;
End;

procedure TRestDWForm.ButtonStopClick(Sender: TObject);
begin
 RESTServicePooler1.Active := False;
 Server_FDConnection.Connected := False;
 PageControl1.ActivePage := tsConfigs;
 ShowApplication;
end;

Procedure TRestDWForm.cbAdaptadoresChange(Sender: TObject);
Begin
 vDatabaseIP := Trim(Copy(cbAdaptadores.Text, Pos('-' , cbAdaptadores.Text ) + 1 , 100));
End;

procedure TRestDWForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
 CanClose := Not RESTServicePooler1.Active;
 If Not CanClose Then
  Begin
   CanClose := Not Self.Visible;
   If CanClose Then
    CanClose := Application.MessageBox('Voc� deseja realmente sair do programa ?',
                                       'Pergunta ?', mb_IconQuestion + mb_YesNo) = mrYes
   Else
    HideApplication;
  End;
end;

Procedure TRestDWForm.FormCreate(Sender: TObject);
Begin
 // define o nome do .ini de acordo c o EXE
 // dessa forma se quiser testar v�rias inst�ncias do servidor em
 // portas diferentes os arquivos n�o ir�o conflitar
 FCfgName := StringReplace(ExtractFileName(ParamStr(0) ), '.exe' , '' , [rfReplaceAll]);
 FCfgName := ExtractFilePath(ParamSTR(0)) + 'Config_' + FCfgName + '.ini' ;
 RESTServicePooler1.ServerMethodClass := TServerMethodDM;
 PageControl1.ActivePage              := tsConfigs;
End;

procedure TRestDWForm.FormShow(Sender: TObject);
Var
 ini               : TIniFile;
 vTag, i           : Integer;
 aNetInterfaceList : tNetworkInterfaceList;
 Function ServerIpIndex(Items : TStrings; ChooseIP : String) : Integer;
 Var
  I : Integer;
 Begin
  Result := -1;
  For I := 0 To Items.Count -1 Do
   Begin
    If Pos(ChooseIP, Items[I]) > 0 Then
     Begin
      Result := I;
      Break;
     End;
   End;
 End;
Begin
 vTag := 0;
 If (GetNetworkInterfaces(aNetInterfaceList)) THen
  Begin
   cbAdaptadores.Items.Clear;
   For i := 0 to High (aNetInterfaceList) do
    Begin
     cbAdaptadores.Items.Add( 'Placa #' + IntToStr( i ) + ' - ' + aNetInterfaceList[i].AddrIP);
     If ( i <= 1 ) or ( Pos( '127.0.0.1' , aNetInterfaceList[i].AddrIP ) > 0 ) then
      Begin
       vDatabaseIP := aNetInterfaceList[i].AddrIP;
       vTag        := 1;
      End;
    End;
   cbAdaptadores.ItemIndex := vTag;
  End;
 ini                     := TIniFile.Create(FCfgName);
 cbAdaptadores.ItemIndex := ServerIpIndex(cbAdaptadores.Items,
                            ini.ReadString('BancoDados', 'Servidor',  '127.0.0.1'));
 edBD.Text               := ini.ReadString('BancoDados', 'BD',        'EMPLOYEE.FDB');
 edPasta.Text            := ini.ReadString('BancoDados', 'Pasta',     ExtractFilePath(ParamSTR(0)) + '..\');
 edPortaBD.Text          := ini.ReadString('BancoDados', 'PortaBD',   '3050');
 edPortaDW.Text          := ini.ReadString('BancoDados', 'PortaDW',   '8082' );
 edUserNameBD.Text       := ini.ReadString('BancoDados', 'UsuarioBD', 'SYSDBA');
 edPasswordBD.Text       := ini.ReadString('BancoDados', 'SenhaBD',   'masterkey');
 edUserNameDW.Text       := ini.ReadString('BancoDados', 'UsuarioDW', 'testserver');
 edPasswordDW.Text       := ini.ReadString('BancoDados', 'SenhaDW',   'testserver');
 ePrivKeyFile.Text       := ini.ReadString('SSL',        'PKF',       '');
 ePrivKeyPass.Text       := ini.ReadString('SSL',        'PKP',       '');
 eCertFile.Text          := ini.ReadString('SSL',        'CF',        '');
 ini.Free;
End;

procedure TRestDWForm.StartServer;
begin
 If Not RESTServicePooler1.Active Then
  Begin
   RESTServicePooler1.ServerParams.UserName := edUserNameDW.Text;
   RESTServicePooler1.ServerParams.Password := edPasswordDW.Text;
   RESTServicePooler1.ServicePort           := StrToInt(edPortaDW.Text);
   RESTServicePooler1.SSLPrivateKeyFile     := ePrivKeyFile.Text;
   RESTServicePooler1.SSLPrivateKeyPassword := ePrivKeyPass.Text;
   RESTServicePooler1.SSLCertFile           := eCertFile.Text;
   RESTServicePooler1.EncodeStrings         := cbEncode.Checked;
   RESTServicePooler1.Active                := True;
   RESTServicePooler1.DataCompression       := CheckBox1.Checked;
   If Not RESTServicePooler1.Active Then
    Exit;
   Server_FDConnection.Connected := True;
   PageControl1.ActivePage := tsLogs;
   HideApplication;
  End;
 If RESTServicePooler1.Secure Then
  Begin
   lSeguro.Font.Color := clBlue;
   lSeguro.Caption    := 'Seguro : Sim';
  End
 Else
  Begin
   lSeguro.Font.Color := clRed;
   lSeguro.Caption    := 'Seguro : N�o';
  End;
end;

end.

