// Procurem os comentarios "Criar para retornar o IP do Cliente"
//para saber os c�digos a acrescentar.
//Gilberto Rocha da Silva

unit WebModuleUnit1;

interface

uses
  System.SysUtils, System.Classes, Web.HTTPApp, Datasnap.DSHTTPCommon,
  Datasnap.DSHTTPWebBroker, Datasnap.DSServer,
  Datasnap.DSAuth, IPPeerServer, Datasnap.DSCommonServer, Datasnap.DSHTTP,
  Datasnap.DSSession, Datasnap.DSProxyJavaScript, Datasnap.DSMetadata,
  Datasnap.DSServerMetadata, Datasnap.DSClientMetadata,
  Datasnap.DSProxyDispatcher;

type
  TWebModule1 = class(TWebModule)
    DSHTTPWebDispatcher1: TDSHTTPWebDispatcher;
    DSServer1: TDSServer;
    DSServerClass1: TDSServerClass;
    DSAuthenticationManager1: TDSAuthenticationManager;
    DSProxyDispatcher1: TDSProxyDispatcher;
    WebFileDispatcher1: TWebFileDispatcher;
    DSProxyGenerator1: TDSProxyGenerator;
    DSServerMetaDataProvider1: TDSServerMetaDataProvider;
    DSRESTWebDispatcher1: TDSRESTWebDispatcher;
    procedure DSServerClass1GetClass(DSServerClass: TDSServerClass;
      var PersistentClass: TPersistentClass);
    procedure WebModule1DefaultHandlerAction(Sender: TObject;
      Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
    procedure WebModuleBeforeDispatch(Sender: TObject; Request: TWebRequest;
      Response: TWebResponse; var Handled: Boolean);
    procedure DSServer1Connect(DSConnectEventObject: TDSConnectEventObject);
    procedure DSServer1Disconnect(DSConnectEventObject: TDSConnectEventObject);
    procedure DSAuthenticationManager1UserAuthenticate(Sender: TObject;
      const Protocol, Context, User, Password: string; var valid: Boolean;
      UserRoles: TStrings);
    procedure WebModuleCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  WebModuleClass: TComponentClass = TWebModule1;
  threadvar remoteIP : AnsiString;   //Criar para retornar o IP do Cliente

implementation

uses ServerMethodsUnit1, Web.WebReq;

{$R *.dfm}

procedure TWebModule1.WebModule1DefaultHandlerAction(Sender: TObject;
  Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
begin
  Response.Content := '<html><heading/><body>DataSnap Server</body></html>';
end;

//Criar para retornar o IP do Cliente
procedure TWebModule1.WebModuleBeforeDispatch(Sender: TObject;
  Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
begin
 remoteIP := Request.RemoteAddr;
end;

procedure TWebModule1.WebModuleCreate(Sender: TObject);
begin
  DSServer1.Start;
  DSServerMetaDataProvider1.Server := DSServer1;
  DSRESTWebDispatcher1.Server := DSServer1;
  if DSServer1.Started then
  begin
    DSRESTWebDispatcher1.DbxContext := DSServer1.DbxContext;
    DSRESTWebDispatcher1.Start;
  end;
  DSRESTWebDispatcher1.AuthenticationManager := DSAuthenticationManager1;
end;

procedure TWebModule1.DSAuthenticationManager1UserAuthenticate(Sender: TObject;
  const Protocol, Context, User, Password: string; var valid: Boolean;
  UserRoles: TStrings);
begin
 //Adicionada Autentica��o de Usu�rio
 valid := (((User = ServerMethodsUnit1.UserName)     And
            (ServerMethodsUnit1.UserName <> ''))     And
           ((Password = ServerMethodsUnit1.Password) And
            (ServerMethodsUnit1.Password <> '')))    Or
          ((ServerMethodsUnit1.UserName = '')        And
           (ServerMethodsUnit1.Password = ''));
end;

//Criar para retornar o IP do Cliente
procedure TWebModule1.DSServer1Connect(
  DSConnectEventObject: TDSConnectEventObject);
begin
 TDSSessionManager.GetThreadSession.PutData('RemoteAddr', String(remoteIP));
end;

//Criar para retornar o IP do Cliente
procedure TWebModule1.DSServer1Disconnect(
  DSConnectEventObject: TDSConnectEventObject);
begin
 remoteIP := '';
end;

procedure TWebModule1.DSServerClass1GetClass(
  DSServerClass: TDSServerClass; var PersistentClass: TPersistentClass);
begin
  PersistentClass := ServerMethodsUnit1.TServerMethods1;
end;

initialization
finalization
  Web.WebReq.FreeWebModules;

end.

