{
 Esse pacote de Componentes foi desenhado com o Objetivo de ajudar as pessoas a desenvolverem
com WebServices REST o mais pr�ximo poss�vel do desenvolvimento local DB, com componentes de
f�cil configura��o para que todos tenham acesso as maravilhas dos WebServices REST/JSON DataSnap.

Desenvolvedor Principal : Gilberto Rocha da Silva (XyberX)
Empresa : XyberPower Desenvolvimento
}

unit uRESTDWPoolerDB;

interface

uses SysUtils,  Classes,      uDWJSONObject,
     DB,        uRESTDWBase,  uDWPoolerMethod,
     uRESTDWMasterDetailData, uDWConsts, uDWConstsData, SyncObjs,
     JvMemoryDataset;

Type
 TOnEventDB               = Procedure (DataSet : TDataSet)         of Object;
 TOnAfterScroll           = Procedure (DataSet : TDataSet)         of Object;
 TOnAfterOpen             = Procedure (DataSet : TDataSet)         of Object;
 TOnAfterClose            = Procedure (DataSet : TDataSet)         of Object;
 TOnAfterInsert           = Procedure (DataSet : TDataSet)         of Object;
 TOnBeforeDelete          = Procedure (DataSet : TDataSet)         of Object;
 TOnBeforePost            = Procedure (DataSet : TDataSet)         of Object;
 TOnAfterPost             = Procedure (DataSet : TDataSet)         of Object;
 TOnEventConnection       = Procedure (Sucess  : Boolean;
                                       Const Error : String)       of Object;
 TOnEventBeforeConnection = Procedure (Sender  : TComponent)       of Object;
 TOnEventTimer            = Procedure of Object;
 TBeforeGetRecords        = Procedure (Sender  : TObject;
                                       Var OwnerData : OleVariant) of Object;

Type
 TTimerData = Class(TThread)
 Private
  FValue : Integer;          //Milisegundos para execu��o
  FLock  : TCriticalSection; //Se��o cr�tica
  vEvent : TOnEventTimer;    //Evento a ser executado
 Public
  Property OnEventTimer : TOnEventTimer Read vEvent Write vEvent; //Evento a ser executado
 Protected
  Constructor Create(AValue: Integer; ALock: TCriticalSection);   //Construtor do Evento
  Procedure   Execute; Override;                                  //Procedure de Execu��o autom�tica
End;

Type
 TAutoCheckData = Class(TPersistent)
 Private
  vAutoCheck : Boolean;                            //Se tem Autochecagem
  vInTime    : Integer;                            //Em milisegundos o timer
  Timer      : TTimerData;                         //Thread do temporizador
  vEvent     : TOnEventTimer;                      //Evento a executar
  FLock      : TCriticalSection;                   //CriticalSection para execu��o segura
  Procedure  SetState(Value : Boolean);            //Ativa ou desativa a classe
  Procedure  SetInTime(Value : Integer);           //Diz o Timeout
  Procedure  SetEventTimer(Value : TOnEventTimer); //Seta o Evento a ser executado
 Public
  Constructor Create; //Cria o Componente
  Destructor  Destroy;Override;//Destroy a Classe
  Procedure   Assign(Source : TPersistent); Override;
 Published
  Property AutoCheck    : Boolean       Read vAutoCheck Write SetState;      //Se tem Autochecagem
  Property InTime       : Integer       Read vInTime    Write SetInTime;     //Em milisegundos o timer
  Property OnEventTimer : TOnEventTimer Read vEvent     Write SetEventTimer; //Evento a executar
End;


 TProxyOptions = Class(TPersistent)
 Private
  vServer,              //Servidor Proxy na Rede
  vLogin,               //Login do Servidor Proxy
  vPassword : String;   //Senha do Servidor Proxy
  vPort     : Integer;  //Porta do Servidor Proxy
 Public
  Constructor Create;
  Procedure   Assign(Source : TPersistent); Override;
 Published
  Property Server   : String  Read vServer   Write vServer;   //Servidor Proxy na Rede
  Property Port     : Integer Read vPort     Write vPort;     //Porta do Servidor Proxy
  Property Login    : String  Read vLogin    Write vLogin;    //Login do Servidor Proxy
  Property Password : String  Read vPassword Write vPassword; //Senha do Servidor Proxy
End;

Type
 TRESTDWDataBase = Class(TComponent)
 Private
  vLogin,                                            //Login do Usu�rio caso haja autentica��o
  vPassword,                                         //Senha do Usu�rio caso haja autentica��o
  vRestWebService,                                   //Rest WebService para consultas
  vRestURL,                                          //URL do WebService REST
  vRestModule,                                       //Classe Principal do Servidor a ser utilizada
  vMyIP,                                             //Meu IP vindo do Servidor
  vRestPooler          : String;                     //Qual o Pooler de Conex�o do DataSet
  vPoolerPort          : Integer;                    //A Porta do Pooler
  vProxy               : Boolean;                    //Diz se tem servidor Proxy
  vProxyOptions        : TProxyOptions;              //Se tem Proxy diz quais as op��es
  vCompression,                                      //Se Vai haver compress�o de Dados
  vConnected           : Boolean;                    //Diz o Estado da Conex�o
  vOnEventConnection   : TOnEventConnection;         //Evento de Estado da Conex�o
  vOnBeforeConnection  : TOnEventBeforeConnection;   //Evento antes de Connectar o Database
  vAutoCheckData       : TAutoCheckData;             //Autocheck de Conex�o
  vTimeOut             : Integer;
  VEncondig            : TEncodeSelect;              //Enconding se usar CORS usar UTF8 - Alexandre Abade
  vContentex           : String;                    //RestContexto - Alexandre Abade
  vStrsTrim,
  vStrsEmpty2Null,
  vStrsTrim2Len        : Boolean;
  Procedure SetConnection(Value : Boolean);          //Seta o Estado da Conex�o
  Procedure SetRestPooler(Value : String);           //Seta o Restpooler a ser utilizado
  Procedure SetPoolerPort(Value : Integer);          //Seta a Porta do Pooler a ser usada
  Procedure CheckConnection;                         //Checa o Estado automatico da Conex�o
  Function  TryConnect : Boolean;                    //Tenta Conectar o Servidor para saber se posso executar comandos
  Procedure SetConnectionOptions(Var Value : TRESTClientPooler); //Seta as Op��es de Conex�o
  Function  ExecuteCommand  (Var SQL    : TStringList;
                             Var Params : TParams;
                             Var Error  : Boolean;
                             Var MessageError : String;
                             Execute    : Boolean = False) : TJSONValue;
  Procedure ExecuteProcedure(ProcName         : String;
                             Params           : TParams;
                             Var Error        : Boolean;
                             Var MessageError : String);
  Procedure ApplyUpdates(Var SQL          : TStringList;
                         Var Params       : TParams;
                         ADeltaList       : TJSONValue;
                         TableName        : String;
                         Var Error        : Boolean;
                         Var MessageError : String);
  Function InsertMySQLReturnID(Var SQL          : TStringList;
                               Var Params       : TParams;
                               Var Error        : Boolean;
                               Var MessageError : String) : Integer;
  Function  GetStateDB : Boolean;
  Procedure SetMyIp(Value : String);
 Public
  Function    GetRestPoolers : TStringList;          //Retorna a Lista de DataSet Sources do Pooler
  Constructor Create(AOwner  : TComponent);Override; //Cria o Componente
  Destructor  Destroy;Override;                      //Destroy a Classe
  Procedure   Close;
  Procedure   Open;
  Property    Connected       : Boolean                  Read GetStateDB          Write SetConnection;
 Published
  Property OnConnection       : TOnEventConnection       Read vOnEventConnection  Write vOnEventConnection; //Evento relativo a tudo que acontece quando tenta conectar ao Servidor
  Property OnBeforeConnect    : TOnEventBeforeConnection Read vOnBeforeConnection Write vOnBeforeConnection; //Evento antes de Connectar o Database
  Property Active             : Boolean                  Read vConnected          Write SetConnection;      //Seta o Estado da Conex�o
  Property Compression        : Boolean                  Read vCompression        Write vCompression;       //Compress�o de Dados
  Property MyIP               : String                   Read vMyIP               Write SetMyIp;
  Property Login              : String                   Read vLogin              Write vLogin;             //Login do Usu�rio caso haja autentica��o
  Property Password           : String                   Read vPassword           Write vPassword;          //Senha do Usu�rio caso haja autentica��o
  Property Proxy              : Boolean                  Read vProxy              Write vProxy;             //Diz se tem servidor Proxy
  Property ProxyOptions       : TProxyOptions            Read vProxyOptions       Write vProxyOptions;      //Se tem Proxy diz quais as op��es
  Property PoolerService      : String                   Read vRestWebService     Write vRestWebService;    //Host do WebService REST
  Property PoolerURL          : String                   Read vRestURL            Write vRestURL;           //URL do WebService REST
  Property PoolerPort         : Integer                  Read vPoolerPort         Write SetPoolerPort;      //A Porta do Pooler do DataSet
  Property PoolerName         : String                   Read vRestPooler         Write SetRestPooler;      //Qual o Pooler de Conex�o ligado ao componente
  Property RestModule         : String                   Read vRestModule         Write vRestModule;        //Classe do Servidor REST Principal
  Property StateConnection    : TAutoCheckData           Read vAutoCheckData      Write vAutoCheckData;     //Autocheck da Conex�o
  Property RequestTimeOut     : Integer                  Read vTimeOut            Write vTimeOut;           //Timeout da Requisi��o
  Property Encoding           : TEncodeSelect            Read VEncondig           Write VEncondig;          //Encoding da string
  Property Context            : string                   Read vContentex          Write vContentex;         //Contexto
  Property StrsTrim           : Boolean                  Read vStrsTrim           Write vStrsTrim;
  Property StrsEmpty2Null     : Boolean                  Read vStrsEmpty2Null     Write vStrsEmpty2Null;
  Property StrsTrim2Len       : Boolean                  Read vStrsTrim2Len       Write vStrsTrim2Len;
End;

Type
 TRESTDWClientSQL   = Class(TJvMemoryData)                    //Classe com as funcionalidades de um DBQuery
 Private
  vOldStatus           : TDatasetState;
  vDataSource          : TDataSource;
  vOnAfterScroll       : TOnAfterScroll;
  vOnAfterOpen         : TOnAfterOpen;
  vOnAfterClose        : TOnAfterClose;
  vOnAfterInsert       : TOnAfterInsert;
  vOnBeforeDelete      : TOnBeforeDelete;
  vOnBeforePost        : TOnBeforePost;
  vOnAfterPost         : TOnAfterPost;
  OldData              : TMemoryStream;
  vActualRec           : Integer;
  vMasterFields,
  vUpdateTableName     : String;                          //Tabela que ser� feito Update no Servidor se for usada Reflex�o de Dados
  vInactive,
  vCacheUpdateRecords,
  vReadData,
  vCascadeDelete,
  vBeforeClone,
  vDataCache,                                             //Se usa cache local
  vConnectedOnce,                                         //Verifica se foi conectado ao Servidor
  vCommitUpdates,
  vCreateDS,
  vErrorBefore,
  vActive              : Boolean;                         //Estado do Dataset
  vSQL                 : TStringList;                     //SQL a ser utilizado na conex�o
  vParams              : TParams;                         //Parametros de Dataset
  vCacheDataDB         : TDataset;                        //O Cache de Dados Salvo para utiliza��o r�pida
  vOnGetDataError      : TOnEventConnection;              //Se deu erro na hora de receber os dados ou n�o
  vRESTDataBase        : TRESTDWDataBase;                   //RESTDataBase do Dataset
  vOnAfterDelete       : TDataSetNotifyEvent;
  FieldDefsUPD         : TFieldDefs;
  vMasterDataSet       : TRESTDWClientSQL;
  vMasterDetailList    : TMasterDetailList;               //DataSet MasterDetail Function
  Procedure CloneDefinitions(Source : TJvMemoryData;
                             aSelf  : TJvMemoryData);     //Fields em Defini��es
  Procedure OnChangingSQL(Sender: TObject);               //Quando Altera o SQL da Lista
  Procedure SetActiveDB(Value : Boolean);                 //Seta o Estado do Dataset
  Procedure SetSQL(Value : TStringList);                  //Seta o SQL a ser usado
  Procedure CreateParams;                                 //Cria os Parametros na lista de Dataset
  Procedure SetDataBase(Value : TRESTDWDataBase);           //Diz o REST Database
  Function  GetData : Boolean;                            //Recebe os Dados da Internet vindo do Servidor REST
  Procedure SetUpdateTableName(Value : String);           //Diz qual a tabela que ser� feito Update no Banco
  Procedure OldAfterPost(DataSet: TDataSet);              //Eventos do Dataset para realizar o AfterPost
  Procedure OldAfterDelete(DataSet: TDataSet);            //Eventos do Dataset para realizar o AfterDelete
  Procedure SetMasterDataSet(Value : TRESTDWClientSQL);
  Procedure PrepareDetails(ActiveMode : Boolean);
  Procedure SetCacheUpdateRecords(Value : Boolean);
  Procedure PrepareDetailsNew;
  Function  FirstWord       (Value   : String) : String;
  Procedure ProcAfterScroll (DataSet : TDataSet);
  Procedure ProcAfterOpen   (DataSet : TDataSet);
  Procedure ProcAfterClose  (DataSet : TDataSet);
  Procedure ProcAfterInsert (DataSet : TDataSet);
  Procedure ProcBeforeDelete(DataSet : TDataSet);
  Procedure ProcBeforePost  (DataSet : TDataSet);
  Procedure ProcAfterPost   (DataSet : TDataSet);
  Procedure CommitData;
 Protected
 Public
  //M�todos
  Procedure   FieldDefsToFields;
  Function    FieldDefExist(Value : String) : TFieldDef;
  Procedure   Open;Overload; Virtual;                     //M�todo Open que ser� utilizado no Componente
  Procedure   Open(SQL: String);Overload; Virtual;        //M�todo Open que ser� utilizado no Componente
  Procedure   ExecOrOpen;                                 //M�todo Open que ser� utilizado no Componente
  Procedure   Close;Virtual;                              //M�todo Close que ser� utilizado no Componente
  Procedure   CreateDataSet; virtual;
  Function    ExecSQL(Var Error : String) : Boolean;      //M�todo ExecSQL que ser� utilizado no Componente
  Function    InsertMySQLReturnID : Integer;              //M�todo de ExecSQL com retorno de Incremento
  Function    ParamByName(Value : String) : TParam;       //Retorna o Parametro de Acordo com seu nome
  Function    ApplyUpdates(var Error : String) : Boolean; //Aplica Altera��es no Banco de Dados
  Constructor Create(AOwner : TComponent);Override;       //Cria o Componente
  Destructor  Destroy;Override;                           //Destroy a Classe
  Procedure   Loaded; Override;
  procedure   OpenCursor(InfoQuery: Boolean); Override;   //Subscrevendo o OpenCursor para n�o ter erros de ADD Fields em Tempo de Design
  Procedure   GotoRec(Const aRecNo : Integer);
  Function    ParamCount : Integer;
  Procedure   DynamicFilter(Field, Value : String; InText : Boolean = False);
  Procedure   Refresh;
  Procedure   SaveToStream(Var Stream : TMemoryStream);
 Published
  Property MasterDataSet       : TRESTDWClientSQL    Read vMasterDataSet            Write SetMasterDataSet;
  Property MasterCascadeDelete : Boolean             Read vCascadeDelete            Write vCascadeDelete;
  Property Inactive            : Boolean             Read vInactive                 Write vInactive;
  Property AfterDelete         : TDataSetNotifyEvent Read vOnAfterDelete            Write vOnAfterDelete;
  Property OnGetDataError      : TOnEventConnection  Read vOnGetDataError           Write vOnGetDataError;         //Recebe os Erros de ExecSQL ou de GetData
  Property AfterScroll         : TOnAfterScroll      Read vOnAfterScroll            Write vOnAfterScroll;
  Property AfterOpen           : TOnAfterOpen        Read vOnAfterOpen              Write vOnAfterOpen;
  Property AfterClose          : TOnAfterClose       Read vOnAfterClose             Write vOnAfterClose;
  Property AfterInsert         : TOnAfterInsert      Read vOnAfterInsert            Write vOnAfterInsert;
  Property BeforeDelete        : TOnBeforeDelete     Read vOnBeforeDelete           Write vOnBeforeDelete;
  Property BeforePost          : TOnBeforePost       Read vOnBeforePost             Write vOnBeforePost;
  Property AfterPost           : TOnAfterPost        Read vOnAfterPost              Write vOnAfterPost;
  Property Active              : Boolean             Read vActive                   Write SetActiveDB;             //Estado do Dataset
  Property DataCache           : Boolean             Read vDataCache                Write vDataCache;              //Diz se ser� salvo o �ltimo Stream do Dataset
  Property Params              : TParams             Read vParams                   Write vParams;                 //Parametros de Dataset
  Property DataBase            : TRESTDWDataBase     Read vRESTDataBase             Write SetDataBase;             //Database REST do Dataset
  Property SQL                 : TStringList         Read vSQL                      Write SetSQL;                  //SQL a ser Executado
  Property UpdateTableName     : String              Read vUpdateTableName          Write SetUpdateTableName;      //Tabela que ser� usada para Reflex�o de Dados
  Property CacheUpdateRecords  : Boolean             Read vCacheUpdateRecords       Write SetCacheUpdateRecords;
  Property MasterFields        : String              Read vMasterFields             Write vMasterFields;
End;

Type
 TRESTDWStoredProc = Class(TComponent)
 Private
  vParams       : TParams;
  vProcName     : String;
  vRESTDataBase : TRESTDWDataBase;
  procedure SetDataBase(Const Value : TRESTDWDataBase);
 Public
  Constructor Create   (AOwner      : TComponent);Override; //Cria o Componente
  Function    ExecProc (Var Error   : String) : Boolean;
  Destructor  Destroy;Override;                             //Destroy a Classe
  Function    ParamByName(Value : String) : TParam;
 Published
  Property DataBase            : TRESTDWDataBase     Read vRESTDataBase Write SetDataBase;             //Database REST do Dataset
  Property Params              : TParams             Read vParams       Write vParams;                 //Parametros de Dataset
  Property ProcName            : String              Read vProcName     Write vProcName;               //Procedure a ser Executada
End;

Type
 TRESTDWPoolerList = Class(TComponent)
 Private
  vPoolerPrefix,                                     //Prefixo do WS
  vLogin,                                            //Login do Usu�rio caso haja autentica��o
  vPassword,                                         //Senha do Usu�rio caso haja autentica��o
  vRestWebService,                                   //Rest WebService para consultas
  vRestURL             : String;                     //Qual o Pooler de Conex�o do DataSet
  vPoolerPort          : Integer;                    //A Porta do Pooler
  vConnected,
  vProxy               : Boolean;                    //Diz se tem servidor Proxy
  vProxyOptions        : TProxyOptions;              //Se tem Proxy diz quais as op��es
  vPoolerList          : TStringList;
  Procedure SetConnection(Value : Boolean);          //Seta o Estado da Conex�o
  Procedure SetPoolerPort(Value : Integer);          //Seta a Porta do Pooler a ser usada
  Function  TryConnect : Boolean;                    //Tenta Conectar o Servidor para saber se posso executar comandos
  Procedure SetConnectionOptions(Var Value : TRESTClientPooler); //Seta as Op��es de Conex�o
 Public
  Constructor Create(AOwner  : TComponent);Override; //Cria o Componente
  Destructor  Destroy;Override;                      //Destroy a Classe
 Published
  Property Active             : Boolean                  Read vConnected          Write SetConnection;      //Seta o Estado da Conex�o
  Property Login              : String                   Read vLogin              Write vLogin;             //Login do Usu�rio caso haja autentica��o
  Property Password           : String                   Read vPassword           Write vPassword;          //Senha do Usu�rio caso haja autentica��o
  Property Proxy              : Boolean                  Read vProxy              Write vProxy;             //Diz se tem servidor Proxy
  Property ProxyOptions       : TProxyOptions            Read vProxyOptions       Write vProxyOptions;      //Se tem Proxy diz quais as op��es
  Property PoolerService      : String                   Read vRestWebService     Write vRestWebService;    //Host do WebService REST
  Property PoolerURL          : String                   Read vRestURL            Write vRestURL;           //URL do WebService REST
  Property PoolerPort         : Integer                  Read vPoolerPort         Write SetPoolerPort;      //A Porta do Pooler do DataSet
  Property PoolerPrefix       : String                   Read vPoolerPrefix       Write vPoolerPrefix;      //Prefixo do WebService REST
  Property Poolers            : TStringList              Read vPoolerList;
End;

Type
 TRESTDWDriver    = Class(TComponent)
 Private
  vStrsTrim,
  vStrsEmpty2Null,
  vStrsTrim2Len,
  vCompression       : Boolean;
  vEncoding          : TEncodeSelect;
 Public
  Procedure ApplyChanges        (TableName,
                                 SQL               : String;
                                 Params            : TDWParams;
                                 Var Error         : Boolean;
                                 Var MessageError  : String;
                                 Const ADeltaList  : TJSONValue);Overload;Virtual; abstract;
  Procedure ApplyChanges        (TableName,
                                 SQL               : String;
                                 Var Error         : Boolean;
                                 Var MessageError  : String;
                                 Const ADeltaList  : TJSONValue);Overload;Virtual; abstract;
  Function ExecuteCommand       (SQL        : String;
                                 Var Error  : Boolean;
                                 Var MessageError : String;
                                 Execute    : Boolean = False) : TJSONValue;Overload;Virtual;abstract;
  Function ExecuteCommand       (SQL              : String;
                                 Params           : TDWParams;
                                 Var Error        : Boolean;
                                 Var MessageError : String;
                                 Execute          : Boolean = False) : TJSONValue;Overload;Virtual;abstract;
  Function InsertMySQLReturnID  (SQL              : String;
                                 Var Error        : Boolean;
                                 Var MessageError : String) : Integer;Overload;Virtual;abstract;
  Function InsertMySQLReturnID  (SQL              : String;
                                 Params           : TDWParams;
                                 Var Error        : Boolean;
                                 Var MessageError : String) : Integer;Overload;Virtual;abstract;
  Procedure ExecuteProcedure    (ProcName         : String;
                                 Params           : TDWParams;
                                 Var Error        : Boolean;
                                 Var MessageError : String);Virtual;abstract;
  Procedure ExecuteProcedurePure(ProcName         : String;
                                 Var Error        : Boolean;
                                 Var MessageError : String);Virtual;abstract;
  Procedure Close;Virtual;abstract;
 Public
  Property StrsTrim       : Boolean       Read vStrsTrim       Write vStrsTrim;
  Property StrsEmpty2Null : Boolean       Read vStrsEmpty2Null Write vStrsEmpty2Null;
  Property StrsTrim2Len   : Boolean       Read vStrsTrim2Len   Write vStrsTrim2Len;
  Property Compression    : Boolean       Read vCompression    Write vCompression;
  Property Encoding       : TEncodeSelect Read vEncoding       Write vEncoding;
End;

//PoolerDB Control
Type
 TRESTDWPoolerDBP = ^TComponent;
 TRESTDWPoolerDB  = Class(TComponent)
 Private
  FLock          : TCriticalSection;
  vRESTDriverBack,
  vRESTDriver    : TRESTDWDriver;
  vActive,
  vStrsTrim,
  vStrsEmpty2Null,
  vStrsTrim2Len,
  vCompression   : Boolean;
  vEncoding      : TEncodeSelect;
  vMessagePoolerOff : String;
  Procedure SetConnection(Value : TRESTDWDriver);
  Function  GetConnection  : TRESTDWDriver;
 Public
  Procedure ApplyChanges(TableName,
                         SQL               : String;
                         Params            : TDWParams;
                         Var Error         : Boolean;
                         Var MessageError  : String;
                         Const ADeltaList  : TJSONValue);Overload;
  Procedure ApplyChanges(TableName,
                         SQL               : String;
                         Var Error         : Boolean;
                         Var MessageError  : String;
                         Const ADeltaList  : TJSONValue);Overload;
  Function ExecuteCommand(SQL        : String;
                          Var Error  : Boolean;
                          Var MessageError : String;
                          Execute    : Boolean = False) : TJSONValue;Overload;
  Function ExecuteCommand(SQL              : String;
                          Params           : TDWParams;
                          Var Error        : Boolean;
                          Var MessageError : String;
                          Execute          : Boolean = False) : TJSONValue;Overload;
  Function InsertMySQLReturnID(SQL              : String;
                               Var Error        : Boolean;
                               Var MessageError : String) : Integer;Overload;
  Function InsertMySQLReturnID(SQL              : String;
                               Params           : TDWParams;
                               Var Error        : Boolean;
                               Var MessageError : String) : Integer;Overload;
  Procedure ExecuteProcedure  (ProcName         : String;
                               Params           : TDWParams;
                               Var Error        : Boolean;
                               Var MessageError : String);
  Procedure ExecuteProcedurePure(ProcName         : String;
                                 Var Error        : Boolean;
                                 Var MessageError : String);
  Constructor Create(AOwner : TComponent);Override; //Cria o Componente
  Destructor  Destroy;Override;                     //Destroy a Classe
 Published
  Property    RESTDriver       : TRESTDWDriver   Read GetConnection     Write SetConnection;
  Property    Compression      : Boolean       Read vCompression      Write vCompression;
  Property    Encoding         : TEncodeSelect Read vEncoding         Write vEncoding;
  Property    StrsTrim         : Boolean       Read vStrsTrim         Write vStrsTrim;
  Property    StrsEmpty2Null   : Boolean       Read vStrsEmpty2Null   Write vStrsEmpty2Null;
  Property    StrsTrim2Len     : Boolean       Read vStrsTrim2Len     Write vStrsTrim2Len;
  Property    Active           : Boolean       Read vActive           Write vActive;
  Property    PoolerOffMessage : String        Read vMessagePoolerOff Write vMessagePoolerOff;
End;

{$IFNDEF FPC}
 {$if CompilerVersion > 21}
  Function GetDWParams(Params : TParams; Encondig : TEncodeSelect) : TDWParams;
 {$ELSE}
  Function GetDWParams(Params : TParams) : TDWParams;
 {$IFEND}
{$ELSE}
 Function GetDWParams(Params : TParams) : TDWParams;
{$ENDIF}

implementation

{$IFNDEF FPC}
 {$if CompilerVersion > 21}
  Function GetDWParams(Params : TParams; Encondig : TEncodeSelect) : TDWParams;
 {$ELSE}
  Function GetDWParams(Params : TParams) : TDWParams;
 {$IFEND}
{$ELSE}
 Function GetDWParams(Params : TParams) : TDWParams;
{$ENDIF}
Var
 I         : Integer;
 JSONParam : TJSONParam;
Begin
 Result := Nil;
 If Params <> Nil Then
  Begin
   If Params.Count > 0 Then
    Begin
     Result := TDWParams.Create;
     {$IFNDEF FPC}
      {$if CompilerVersion > 21}
       Result.Encoding := GetEncoding(Encondig);
      {$IFEND}
     {$ENDIF}
     For I := 0 To Params.Count -1 Do
      Begin
       {$IFNDEF FPC}
        {$if CompilerVersion > 21}
         JSONParam         := TJSONParam.Create(Result.Encoding);
        {$ELSE}
         JSONParam         := TJSONParam.Create;
        {$IFEND}
       {$ELSE}
        JSONParam         := TJSONParam.Create;
       {$ENDIF}
       JSONParam.ParamName := Params[I].Name;
       JSONParam.LoadFromParam(Params[I]);
       Result.Add(JSONParam);
      End;
    End;
  End;
End;

Procedure TAutoCheckData.Assign(Source: TPersistent);
Var
 Src : TAutoCheckData;
Begin
 If Source is TAutoCheckData Then
  Begin
   Src        := TAutoCheckData(Source);
   vAutoCheck := Src.AutoCheck;
   vInTime    := Src.InTime;
//   vEvent     := Src.OnEventTimer;
  End
 Else
  Inherited;
End;

Procedure TProxyOptions.Assign(Source: TPersistent);
Var
 Src : TProxyOptions;
Begin
 If Source is TProxyOptions Then
  Begin
   Src := TProxyOptions(Source);
   vServer := Src.Server;
   vLogin  := Src.Login;
   vPassword := Src.Password;
   vPort     := Src.Port;
  End
 Else
  Inherited;
End;

{$IFDEF MSWINDOWS}
Function  TRESTDWPoolerDB.GetConnection : TRESTDWDriver;
Begin
 Result := vRESTDriverBack;
End;

Procedure TRESTDWPoolerDB.SetConnection(Value : TRESTDWDriver);
Begin
 vRESTDriverBack := Value;
 If Value <> Nil Then
  vRESTDriver     := vRESTDriverBack
 Else
  Begin
   If vRESTDriver <> Nil Then
    vRESTDriver.Close;
  End;
End;

Function TRESTDWPoolerDB.InsertMySQLReturnID(SQL              : String;
                                           Var Error        : Boolean;
                                           Var MessageError : String) : Integer;
Begin
 Result := -1;
 If vRESTDriver <> Nil Then
  Begin
   vRESTDriver.vStrsTrim          := vStrsTrim;
   vRESTDriver.vStrsEmpty2Null    := vStrsEmpty2Null;
   vRESTDriver.vStrsTrim2Len      := vStrsTrim2Len;
   vRESTDriver.vCompression       := vCompression;
   vRESTDriver.vEncoding          := vEncoding;
   Result := vRESTDriver.InsertMySQLReturnID(SQL, Error, MessageError);
  End
 Else
  Begin
   Error        := True;
   MessageError := 'Selected Pooler Does Not Have a Driver Set';
  End;
End;

Function TRESTDWPoolerDB.InsertMySQLReturnID(SQL              : String;
                                           Params           : TDWParams;
                                           Var Error        : Boolean;
                                           Var MessageError : String) : Integer;
Begin
 Result := -1;
 If vRESTDriver <> Nil Then
  Begin
   vRESTDriver.vStrsTrim          := vStrsTrim;
   vRESTDriver.vStrsEmpty2Null    := vStrsEmpty2Null;
   vRESTDriver.vStrsTrim2Len      := vStrsTrim2Len;
   vRESTDriver.vCompression       := vCompression;
   vRESTDriver.vEncoding          := vEncoding;
   Result := vRESTDriver.InsertMySQLReturnID(SQL, Params, Error, MessageError);
  End
 Else
  Begin
   Error        := True;
   MessageError := 'Selected Pooler Does Not Have a Driver Set';
  End;
End;

Function TRESTDWPoolerDB.ExecuteCommand(SQL        : String;
                                      Var Error  : Boolean;
                                      Var MessageError : String;
                                      Execute    : Boolean = False) : TJSONValue;
Begin
  Result := nil;
 If vRESTDriver <> Nil Then
  Begin
   vRESTDriver.vStrsTrim          := vStrsTrim;
   vRESTDriver.vStrsEmpty2Null    := vStrsEmpty2Null;
   vRESTDriver.vStrsTrim2Len      := vStrsTrim2Len;
   vRESTDriver.vCompression       := vCompression;
   vRESTDriver.vEncoding          := vEncoding;
   Result := vRESTDriver.ExecuteCommand(SQL, Error, MessageError, Execute);
  End
 Else
  Begin
   Error        := True;
   MessageError := 'Selected Pooler Does Not Have a Driver Set';
  End;
End;

Function TRESTDWPoolerDB.ExecuteCommand(SQL              : String;
                                        Params           : TDWParams;
                                        Var Error        : Boolean;
                                        Var MessageError : String;
                                        Execute          : Boolean = False) : TJSONValue;
Begin
 Result := Nil;
 If vRESTDriver <> Nil Then
  Begin
   vRESTDriver.vStrsTrim          := vStrsTrim;
   vRESTDriver.vStrsEmpty2Null    := vStrsEmpty2Null;
   vRESTDriver.vStrsTrim2Len      := vStrsTrim2Len;
   vRESTDriver.vCompression       := vCompression;
   vRESTDriver.vEncoding          := vEncoding;
   Result := vRESTDriver.ExecuteCommand(SQL, Params, Error, MessageError, Execute);
  End
 Else
  Begin
   Error        := True;
   MessageError := 'Selected Pooler Does Not Have a Driver Set';
  End;
End;

Procedure TRESTDWPoolerDB.ExecuteProcedure(ProcName         : String;
                                         Params           : TDWParams;
                                         Var Error        : Boolean;
                                         Var MessageError : String);
Begin
 If vRESTDriver <> Nil Then
  Begin
   vRESTDriver.vStrsTrim          := vStrsTrim;
   vRESTDriver.vStrsEmpty2Null    := vStrsEmpty2Null;
   vRESTDriver.vStrsTrim2Len      := vStrsTrim2Len;
   vRESTDriver.vCompression       := vCompression;
   vRESTDriver.vEncoding          := vEncoding;
   vRESTDriver.ExecuteProcedure(ProcName, Params, Error, MessageError);
  End
 Else
  Begin
   Error        := True;
   MessageError := 'Selected Pooler Does Not Have a Driver Set';
  End;
End;

Procedure TRESTDWPoolerDB.ExecuteProcedurePure(ProcName         : String;
                                             Var Error        : Boolean;
                                             Var MessageError : String);
Begin
 If vRESTDriver <> Nil Then
  Begin
   vRESTDriver.vStrsTrim          := vStrsTrim;
   vRESTDriver.vStrsEmpty2Null    := vStrsEmpty2Null;
   vRESTDriver.vStrsTrim2Len      := vStrsTrim2Len;
   vRESTDriver.vCompression       := vCompression;
   vRESTDriver.vEncoding          := vEncoding;
   vRESTDriver.ExecuteProcedurePure(ProcName, Error, MessageError);
  End
 Else
  Begin
   Error        := True;
   MessageError := 'Selected Pooler Does Not Have a Driver Set';
  End;
End;

Procedure TRESTDWPoolerDB.ApplyChanges(TableName,
                                     SQL               : String;
                                     Var Error         : Boolean;
                                     Var MessageError  : String;
                                     Const ADeltaList  : TJSONValue);
begin
 If vRESTDriver <> Nil Then
  Begin
   vRESTDriver.vStrsTrim          := vStrsTrim;
   vRESTDriver.vStrsEmpty2Null    := vStrsEmpty2Null;
   vRESTDriver.vStrsTrim2Len      := vStrsTrim2Len;
   vRESTDriver.vCompression       := vCompression;
   vRESTDriver.vEncoding          := vEncoding;
   vRESTDriver.ApplyChanges(TableName, SQL, Error, MessageError, ADeltaList);
  End
 Else
  Begin
   Error        := True;
   MessageError := 'Selected Pooler Does Not Have a Driver Set';
  End;
end;

Procedure TRESTDWPoolerDB.ApplyChanges(TableName,
                                     SQL               : String;
                                     Params            : TDWParams;
                                     Var Error         : Boolean;
                                     Var MessageError  : String;
                                     Const ADeltaList  : TJSONValue);
begin
 If vRESTDriver <> Nil Then
  Begin
   vRESTDriver.vStrsTrim          := vStrsTrim;
   vRESTDriver.vStrsEmpty2Null    := vStrsEmpty2Null;
   vRESTDriver.vStrsTrim2Len      := vStrsTrim2Len;
   vRESTDriver.vCompression       := vCompression;
   vRESTDriver.vEncoding          := vEncoding;
   vRESTDriver.ApplyChanges(TableName, SQL, Params, Error, MessageError, ADeltaList);
  End
 Else
  Begin
   Error        := True;
   MessageError := 'Selected Pooler Does Not Have a Driver Set';
  End;
end;

Constructor TRESTDWPoolerDB.Create(AOwner : TComponent);
Begin
 Inherited;
 FLock             := TCriticalSection.Create;
 vCompression      := True;
 vStrsTrim         := False;
 vStrsEmpty2Null   := False;
 vStrsTrim2Len     := True;
 vActive           := True;
 vEncoding         := esUtf8;
 vMessagePoolerOff := 'RESTPooler not active.';
End;

Destructor  TRESTDWPoolerDB.Destroy;
Begin
 FLock.Release;
 FLock.Free;
 Inherited;
End;
{$ENDIF}

Constructor TAutoCheckData.Create;
Begin
 Inherited;
 vAutoCheck := False;
 vInTime    := 1000;
 vEvent     := Nil;
 Timer      := Nil;
 FLock      := TCriticalSection.Create;
End;

Destructor  TAutoCheckData.Destroy;
Begin
 SetState(False);
 FLock.Release;
 FLock.Free;
 Inherited;
End;

Procedure  TAutoCheckData.SetState(Value : Boolean);
Begin
 vAutoCheck := Value;
 If vAutoCheck Then
  Begin
   If Timer <> Nil Then
    Begin
     Timer.Terminate;
     Timer := Nil;
    End;
   Timer              := TTimerData.Create(vInTime, FLock);
   Timer.OnEventTimer := vEvent;
  End
 Else
  Begin
   If Timer <> Nil Then
    Begin
     Timer.Terminate;
     Timer := Nil;
    End;
  End;
End;

Procedure  TAutoCheckData.SetInTime(Value : Integer);
Begin
 vInTime    := Value;
 SetState(vAutoCheck);
End;

Procedure  TAutoCheckData.SetEventTimer(Value : TOnEventTimer);
Begin
 vEvent := Value;
 SetState(vAutoCheck);
End;

Constructor TTimerData.Create(AValue: Integer; ALock: TCriticalSection);
Begin
 FValue := AValue;
 FLock := ALock;
 Inherited Create(False);
End;

Procedure TTimerData.Execute;
Begin
 While Not Terminated do
  Begin
   Sleep(FValue);
   FLock.Acquire;
   if Assigned(vEvent) then
    vEvent;
   FLock.Release;
  End;
End;

Constructor TProxyOptions.Create;
Begin
 Inherited;
 vServer   := '';
 vLogin    := vServer;
 vPassword := vLogin;
 vPort     := 8888;
End;

Procedure TRESTDWPoolerList.SetConnectionOptions(Var Value : TRESTClientPooler);
Begin
 Value                   := TRESTClientPooler.Create(Nil);
 Value.TypeRequest       := trHttp;
 Value.Host              := vRestWebService;
 Value.Port              := vPoolerPort;
 Value.UrlPath           := vRestURL;
 Value.UserName          := vLogin;
 Value.Password          := vPassword;
 if vProxy then
  Begin
   Value.ProxyOptions.ProxyServer   := vProxyOptions.vServer;
   Value.ProxyOptions.ProxyPort     := vProxyOptions.vPort;
   Value.ProxyOptions.ProxyUsername := vProxyOptions.vLogin;
   Value.ProxyOptions.ProxyPassword := vProxyOptions.vPassword;
  End
 Else
  Begin
   Value.ProxyOptions.ProxyServer   := '';
   Value.ProxyOptions.ProxyPort     := 0;
   Value.ProxyOptions.ProxyUsername := '';
   Value.ProxyOptions.ProxyPassword := '';
  End;
End;

Procedure TRESTDWDataBase.SetConnectionOptions(Var Value : TRESTClientPooler);
Begin
 Value                     := TRESTClientPooler.Create(Nil);
 Value.TypeRequest         := trHttp;
 Value.Host                := vRestWebService;
 Value.Port                := vPoolerPort;
 Value.UrlPath             := vRestURL;
 Value.UserName            := vLogin;
 Value.Password            := vPassword;
 Value.RequestTimeOut      := vTimeOut;
 Value.UrlPath             := vContentex;
 If vProxy Then
  Begin
   Value.ProxyOptions.ProxyServer    := vProxyOptions.vServer;
   Value.ProxyOptions.ProxyPort      := vProxyOptions.vPort;
   Value.ProxyOptions.ProxyUsername  := vProxyOptions.vLogin;
   Value.ProxyOptions.ProxyPassword  := vProxyOptions.vPassword;
  End
 Else
  Begin
   Value.ProxyOptions.ProxyServer   := '';
   Value.ProxyOptions.ProxyPort     := 0;
   Value.ProxyOptions.ProxyUsername := '';
   Value.ProxyOptions.ProxyPassword := '';
  End;
End;

Procedure TRESTDWDataBase.ApplyUpdates(Var SQL          : TStringList;
                                       Var Params       : TParams;
                                       ADeltaList       : TJSONValue;
                                       TableName        : String;
                                       Var Error        : Boolean;
                                       Var MessageError : String);
{
Var
 vDSRConnection    : TRESTClientPooler;
 vRESTConnectionDB : TSMPoolerMethodClient;
 Function GetLineSQL(Value : TStringList) : String;
 Var
  I : Integer;
 Begin
  Result := '';
  If Value <> Nil Then
   For I := 0 To Value.Count -1 do
    Begin
     If I = 0 then
      Result := Value[I]
     Else
      Result := Result + ' ' + Value[I];
    End;
 End;
}
Begin
{
 if vRestPooler = '' then
  Exit;
 SetConnectionOptions(vDSRConnection);
 vRESTConnectionDB := TSMPoolerMethodClient.Create(vDSRConnection, True);
 vRESTConnectionDB.Compression := vCompression;
 vRESTConnectionDB.Encoding    := GetEncoding(VEncondig);
 Try
  If Params.Count > 0 Then
   vRESTConnectionDB.ApplyChanges(vRestPooler,
                                  vRestModule,
                                  TableName,
                                  GetLineSQL(SQL),
                                  Params,
                                  ADeltaList,
                                  Error,
                                  MessageError, '',
                                  vTimeOut, vLogin, vPassword)
  Else
   vRESTConnectionDB.ApplyChangesPure(vRestPooler,
                                      vRestModule,
                                      TableName,
                                      GetLineSQL(SQL),
                                      ADeltaList,
                                      Error,
                                      MessageError, '',
                                      vTimeOut, vLogin, vPassword);
  If Assigned(vOnEventConnection) Then
   vOnEventConnection(True, 'ApplyUpdates Ok')
 Except
  On E : Exception do
   Begin
    vDSRConnection.SessionID := '';
    if Assigned(vOnEventConnection) then
     vOnEventConnection(False, E.Message);
   End;
 End;
 vDSRConnection.Free;
 vRESTConnectionDB.Free;
}
End;

Function TRESTDWDataBase.InsertMySQLReturnID(Var SQL          : TStringList;
                                             Var Params       : TParams;
                                             Var Error        : Boolean;
                                             Var MessageError : String) : Integer;
{
Var
 vDSRConnection    : TRESTClientPooler;
 vRESTConnectionDB : TSMPoolerMethodClient;
 oJsonObject       : Integer;
 Function GetLineSQL(Value : TStringList) : String;
 Var
  I : Integer;
 Begin
  Result := '';
  If Value <> Nil Then
   For I := 0 To Value.Count -1 do
    Begin
     If I = 0 then
      Result := Value[I]
     Else
      Result := Result + ' ' + Value[I];
    End;
 End;
}
Begin
{
 Result := -1;
 Error  := False;
 if vRestPooler = '' then
  Exit;
 SetConnectionOptions(vDSRConnection);
 vRESTConnectionDB := TSMPoolerMethodClient.Create(vDSRConnection, True);
 vRESTConnectionDB.Compression := vCompression;
 vRESTConnectionDB.Encoding    := GetEncoding(VEncondig);
 Try
  If Params.Count > 0 Then
   oJsonObject := vRESTConnectionDB.InsertValue(vRestPooler,
                                                vRestModule,
                                                GetLineSQL(SQL),
                                                Params,
                                                Error, MessageError, '',
                                                vTimeOut, vLogin, vPassword)
  Else
   oJsonObject := vRESTConnectionDB.InsertValuePure(vRestPooler,
                                                    vRestModule,
                                                    GetLineSQL(SQL),
                                                    Error, MessageError, '',
                                                    vTimeOut, vLogin, vPassword);
  Result := oJsonObject;
  If Assigned(vOnEventConnection) Then
   vOnEventConnection(True, 'ExecuteCommand Ok');
 Except
  On E : Exception do
   Begin
    vDSRConnection.SessionID := '';
    Error                    := True;
    MessageError             := E.Message;
    if Assigned(vOnEventConnection) then
     vOnEventConnection(False, E.Message);
   End;
 End;
 vDSRConnection.Free;
 vRESTConnectionDB.Free;
}
End;

Procedure TRESTDWDataBase.Open;
Begin
 SetConnection(True);
End;

Function TRESTDWDataBase.ExecuteCommand(Var SQL          : TStringList;
                                        Var Params       : TParams;
                                        Var Error        : Boolean;
                                        Var MessageError : String;
                                        Execute          : Boolean = False) : TJSONValue;
Var
 vRESTConnectionDB : TDWPoolerMethodClient;
 LDataSetList      : TJSONValue;
 Function GetLineSQL(Value : TStringList) : String;
 Var
  I : Integer;
 Begin
  Result := '';
  If Value <> Nil Then
   For I := 0 To Value.Count -1 do
    Begin
     If I = 0 then
      Result := Value[I]
     Else
      Result := Result + ' ' + Value[I];
    End;
 End;
 Procedure ParseParams;
 Var
  I : Integer;
 Begin
  If Params <> Nil Then
   For I := 0 To Params.Count -1 Do
    Begin
     If Params[I].DataType = ftUnknown then
      Params[I].DataType := ftString;
    End;
 End;
Begin
 Result := Nil;
 if vRestPooler = '' then
  Exit;
 ParseParams;
 vRESTConnectionDB             := TDWPoolerMethodClient.Create(Nil);
 vRESTConnectionDB.Host        := vRestWebService;
 vRESTConnectionDB.Port        := vPoolerPort;
 vRESTConnectionDB.Compression := vCompression;
 {$IFNDEF FPC}
  {$if CompilerVersion > 21}
  vRESTConnectionDB.Encoding    := VEncondig;
  {$IFEND}
 {$ENDIF}
 Try
  If Params.Count > 0 Then
   LDataSetList := vRESTConnectionDB.ExecuteCommandJSON(vRestPooler,
                                                        vRestModule, GetLineSQL(SQL),
                                                        GetDWParams(Params{$IFNDEF FPC}
                                                                    {$if CompilerVersion > 21}
                                                                     , vEncondig
                                                                    {$IFEND}
                                                                    {$ENDIF}), Error,
                                                        MessageError, Execute, vTimeOut, vLogin, vPassword)
  Else
   LDataSetList := vRESTConnectionDB.ExecuteCommandPureJSON(vRestPooler,
                                                            vRestModule,
                                                            GetLineSQL(SQL), Error,
                                                            MessageError, Execute, vTimeOut, vLogin, vPassword);
  If (LDataSetList <> Nil) Then
   Begin
    Result := TJSONValue.Create;
    Error  := Trim(MessageError) <> '';
    If (Trim(LDataSetList.ToJSON) <> '{}') And
       (Trim(LDataSetList.Value) <> '')    And
       (Not (Error))                       Then
     Begin
      Try
       Result.LoadFromJSON(LDataSetList.ToJSON);
      Finally
      End;
     End;
    If (Not (Error)) Then
     Begin
      If Assigned(vOnEventConnection) Then
       vOnEventConnection(True, 'ExecuteCommand Ok');
     End;
   End
  Else
   Begin
    If Assigned(vOnEventConnection) Then
     vOnEventConnection(False, MessageError);
   End;
 Except
  On E : Exception do
   Begin
    if Assigned(vOnEventConnection) then
     vOnEventConnection(False, E.Message);
   End;
 End;
 LDataSetList.Free;
 vRESTConnectionDB.Free;
End;

Procedure TRESTDWDataBase.ExecuteProcedure(ProcName         : String;
                                           Params           : TParams;
                                           Var Error        : Boolean;
                                           Var MessageError : String);
{
Var
 vDSRConnection    : TRESTClientPooler;
 vRESTConnectionDB : TSMPoolerMethodClient;
}
Begin
{
 if vRestPooler = '' then
  Exit;
 If Trim(ProcName) = '' Then
  Begin
   Error := True;
   MessageError := 'ProcName Cannot is Empty';
  End
 Else
  Begin
   SetConnectionOptions(vDSRConnection);
   vRESTConnectionDB             := TSMPoolerMethodClient.Create(vDSRConnection, True);
   vRESTConnectionDB.Compression := vCompression;
   vRESTConnectionDB.Encoding    := GetEncoding(VEncondig);
   Try
    If Params.Count > 0 Then
     vRESTConnectionDB.ExecuteProcedure(vRestPooler, vRestModule, ProcName, Params, Error, MessageError)
    Else
     vRESTConnectionDB.ExecuteProcedurePure(vRestPooler, vRestModule, ProcName, Error, MessageError);
   Except
    On E : Exception do
     Begin
      vDSRConnection.SessionID := '';
      if Assigned(vOnEventConnection) then
       vOnEventConnection(False, E.Message);
     End;
   End;
  vDSRConnection.Free;
  vRESTConnectionDB.Free;
 End;
}
End;

Function TRESTDWDataBase.GetRestPoolers : TStringList;
Var
 vTempList   : TStringList;
 vConnection : TDWPoolerMethodClient;
 I           : Integer;
Begin
 vConnection             := TDWPoolerMethodClient.Create(Nil);
 vConnection.Host        := vRestWebService;
 vConnection.Port        := vPoolerPort;
 vConnection.Compression := vCompression;
 Result := TStringList.Create;
 Try
  vTempList := vConnection.GetPoolerList(vRestModule, vTimeOut, vLogin, vPassword);
  Try
    For I := 0 To vTempList.Count -1 do
     Result.Add(vTempList[I]);
    If Assigned(vOnEventConnection) Then
     vOnEventConnection(True, 'GetRestPoolers Ok');
  Finally
   vTempList.Free;
  End;
 Except
  On E : Exception do
   Begin
    if Assigned(vOnEventConnection) then
     vOnEventConnection(False, E.Message);
   End;
 End;
End;

Function TRESTDWDataBase.GetStateDB: Boolean;
Begin
 Result := vConnected;
End;

Constructor TRESTDWPoolerList.Create(AOwner : TComponent);
Begin
 Inherited;
 vLogin                    := '';
 vPassword                 := vLogin;
 vPoolerPort               := 8082;
 vProxy                    := False;
 vProxyOptions             := TProxyOptions.Create;
 vPoolerList               := TStringList.Create;
End;

Constructor TRESTDWDataBase.Create(AOwner : TComponent);
Begin
 Inherited;
 vLogin                    := 'testserver';
 vMyIP                     := '0.0.0.0';
 vRestWebService           := '127.0.0.1';
 vCompression              := True;
 vPassword                 := vLogin;
 vRestModule               := '';
 vRestPooler               := '';
 vPoolerPort               := 8082;
 vProxy                    := False;
 vProxyOptions             := TProxyOptions.Create;
 vAutoCheckData            := TAutoCheckData.Create;
 vAutoCheckData.vAutoCheck := False;
 vAutoCheckData.vInTime    := 1000;
 vTimeOut                  := 10000;
// vAutoCheckData.vEvent     := CheckConnection;
 VEncondig                 := esUtf8;
 vContentex                := '';
 vStrsTrim                 := False;
 vStrsEmpty2Null           := False;
 vStrsTrim2Len             := True;
End;

Destructor  TRESTDWPoolerList.Destroy;
Begin
 vProxyOptions.Free;
 If vPoolerList <> Nil Then
  vPoolerList.Free;
 Inherited;
End;

Destructor  TRESTDWDataBase.Destroy;
Begin
 vAutoCheckData.vAutoCheck := False;
 vProxyOptions.Free;
 vAutoCheckData.Free;
 Inherited;
End;

Procedure TRESTDWDataBase.CheckConnection;
Begin
 vConnected := TryConnect;
End;

Procedure TRESTDWDataBase.Close;
Begin
 SetConnection(False);
End;

Function  TRESTDWPoolerList.TryConnect : Boolean;
Var
 vTempResult : String;
 vConnection : TDWPoolerMethodClient;
Begin
 Result       := False;
 vConnection  := TDWPoolerMethodClient.Create(Nil);
 vConnection.Host := vRestWebService;
 vConnection.Port := vPoolerPort;
 Try
  vPoolerList.Clear;
  vPoolerList.Assign(vConnection.GetPoolerList(vPoolerPrefix, 3000, vLogin, vPassword));
  Result      := True;
 Except
 End;
 vConnection.Free;
End;

Function  TRESTDWDataBase.TryConnect : Boolean;
Var
 vTempSend   : String;
 vConnection : TDWPoolerMethodClient;
Begin
 Result       := False;
 vConnection  := TDWPoolerMethodClient.Create(Nil);
 Try
  vTempSend   := vConnection.EchoPooler(vRestURL, vRestPooler, vTimeOut, vLogin, vPassword);
  Result      := Trim(vTempSend) <> '';
  If Result Then
   vMyIP       := vTempSend
  Else
   vMyIP       := '';
  If csDesigning in ComponentState Then
   If Not Result Then Raise Exception.Create(PChar('Error : ' + #13 + 'Authentication Error...'));
  If Trim(vMyIP) = '' Then
   Begin
    Result      := False;
    If Assigned(vOnEventConnection) Then
     vOnEventConnection(False, 'Authentication Error...');
   End;
 Except
  On E : Exception do
   Begin
    Result      := False;
    vMyIP       := '';
    If csDesigning in ComponentState Then
     Raise Exception.Create(PChar(E.Message));
    if Assigned(vOnEventConnection) then
     vOnEventConnection(False, E.Message);
   End;
 End;
 vConnection.Free;
End;

Procedure TRESTDWDataBase.SetConnection(Value : Boolean);
Begin
 If (Value) And
    (Trim(vRestPooler) = '') Then
  Exit;
 if (Value) And Not(vConnected) then
  If Assigned(vOnBeforeConnection) Then
   vOnBeforeConnection(Self);
 If Not(vConnected) And (Value) Then
  Begin
   If Value then
    vConnected := TryConnect
   Else
    vMyIP := '';
  End
 Else If Not (Value) Then
  Begin
   vConnected := Value;
   vMyIP := '';
  End;
End;

Procedure TRESTDWPoolerList.SetConnection(Value : Boolean);
Begin
 vConnected := Value;
 If vConnected Then
  vConnected := TryConnect;
End;

Procedure TRESTDWDataBase.SetPoolerPort(Value : Integer);
Begin
 vPoolerPort := Value;
End;

Procedure TRESTDWPoolerList.SetPoolerPort(Value : Integer);
Begin
 vPoolerPort := Value;
End;

Procedure TRESTDWDataBase.SetRestPooler(Value : String);
Begin
 vRestPooler := Value;
End;

Procedure TRESTDWClientSQL.SetDataBase(Value : TRESTDWDataBase);
Begin
 if Value is TRESTDWDataBase then
  vRESTDataBase := Value
 Else
  vRESTDataBase := Nil;
End;

Procedure TRESTDWClientSQL.SetMasterDataSet(Value : TRESTDWClientSQL);
Var
 MasterDetailItem : TMasterDetailItem;
Begin
 If (vMasterDataSet <> Nil) Then
  TRESTDWClientSQL(vMasterDataSet).vMasterDetailList.DeleteDS(TRESTClient(Self));
 If (Value = Self) And (Value <> Nil) Then
  Begin
   vMasterDataSet := Nil;
   MasterFields   := '';
   Exit;
  End;
 vMasterDataSet := Value;
 If (vMasterDataSet <> Nil) Then
  Begin
   MasterDetailItem         := TMasterDetailItem.Create;
   MasterDetailItem.DataSet := TRESTClient(Self);
   TRESTDWClientSQL(vMasterDataSet).vMasterDetailList.Add(MasterDetailItem);
   vDataSource.DataSet := Value;
  End
 Else
  Begin
   MasterFields := '';
  End;
End;



Constructor TRESTDWClientSQL.Create(AOwner : TComponent);
Begin
 vInactive                         := True;
 Inherited;
 vInactive                         := False;
 vDataCache                        := False;
 vConnectedOnce                    := True;
 vActive                           := False;
 vCacheUpdateRecords               := True;
 vBeforeClone                      := False;
 vReadData                         := False;
 vCascadeDelete                    := True;
 vSQL                              := TStringList.Create;
 vSQL.OnChange                     := OnChangingSQL;
 vParams                           := TParams.Create;
// vCacheDataDB                      := Self.CloneSource;
 vUpdateTableName                  := '';
 FieldDefsUPD                      := TFieldDefs.Create(Self);
 FieldDefs                         := FieldDefsUPD;
 vMasterDetailList                 := TMasterDetailList.Create;
 OldData                           := TMemoryStream.Create;
 vMasterDataSet                    := Nil;
 vDataSource                       := TDataSource.Create(Nil);
 {$IFDEF FPC}
 TDataset(Self).AfterScroll        := @ProcAfterScroll;
 TDataset(Self).AfterOpen          := @ProcAfterOpen;
 TDataset(Self).AfterInsert        := @ProcAfterInsert;
 TDataset(Self).BeforeDelete       := @ProcBeforeDelete;
 TDataset(Self).AfterClose         := @ProcAfterClose;
 TDataset(Self).BeforePost         := @ProcBeforePost;
 TDataset(Self).AfterPost          := @ProcAfterPost;
 Inherited AfterPost               := @OldAfterPost;
 Inherited AfterDelete             := @OldAfterDelete;
 {$ELSE}
 TDataset(Self).AfterScroll        := ProcAfterScroll;
 TDataset(Self).AfterOpen          := ProcAfterOpen;
 TDataset(Self).AfterInsert        := ProcAfterInsert;
 TDataset(Self).BeforeDelete       := ProcBeforeDelete;
 TDataset(Self).AfterClose         := ProcAfterClose;
 TDataset(Self).BeforePost         := ProcBeforePost;
 TDataset(Self).AfterPost          := ProcAfterPost;
 Inherited AfterPost               := OldAfterPost;
 Inherited AfterDelete             := OldAfterDelete;
 {$ENDIF}

End;

Destructor  TRESTDWClientSQL.Destroy;
Begin
 vSQL.Free;
 vParams.Free;
 FieldDefsUPD.Free;
 If (vMasterDataSet <> Nil) Then
  TRESTDWClientSQL(vMasterDataSet).vMasterDetailList.DeleteDS(TRESTClient(Self));
 vMasterDetailList.Free;
 vDataSource.Free;
 If vCacheDataDB <> Nil Then
  vCacheDataDB.Free;
 OldData.Free;
 vInactive := False;
 Inherited;
End;

Procedure TRESTDWClientSQL.DynamicFilter(Field, Value : String; InText : Boolean = False);
Begin
 ExecOrOpen;
 If vActive Then
  Begin
   If Length(Value) > 0 Then
    Begin
     If InText Then
      Filter := Format('%s Like ''%s''', [Field, '%' + Value + '%'])
     Else
      Filter := Format('%s Like ''%s''', [Field, Value + '%']);
     If Not (Filtered) Then
      Filtered := True;
    End
   Else
    Begin
     Filter   := '';
     Filtered := False;
    End;
  End;
End;

Function ScanParams(SQL : String) : TStringList;
Var
 vTemp        : String;
 FCurrentPos  : PChar;
 vOldChar     : Char;
 vParamName   : String;
 Function GetParamName : String;
 Begin
  Result := '';
  If FCurrentPos^ = ':' Then
   Begin
    Inc(FCurrentPos);
    if vOldChar in [' ', '=', '-', '+', '<', '>', '(', ')', ':', '|'] then
     Begin
      While Not (FCurrentPos^ = #0) Do
       Begin
        if FCurrentPos^ in ['0'..'9', 'A'..'Z','a'..'z', '_'] then

         Result := Result + FCurrentPos^
        Else
         Break;
        Inc(FCurrentPos);
       End;
     End;
   End
  Else
   Inc(FCurrentPos);
  vOldChar := FCurrentPos^;
 End;
Begin
 Result := TStringList.Create;
 vTemp  := SQL;
 FCurrentPos := PChar(vTemp);
 While Not (FCurrentPos^ = #0) do
  Begin
   If Not (FCurrentPos^ in [#0..' ', ',',
                           '''', '"',
                           '0'..'9', 'A'..'Z',
                           'a'..'z', '_',
                           '$', #127..#255]) Then


    Begin
     vParamName := GetParamName;
     If Trim(vParamName) <> '' Then
      Begin
       Result.Add(vParamName);
       Inc(FCurrentPos);
      End;
    End
   Else
    Begin
     vOldChar := FCurrentPos^;
     Inc(FCurrentPos);
    End;
  End;
End;

Function ReturnParams(SQL : String) : TStringList;
Begin
 Result := ScanParams(SQL);
End;

Procedure TRESTDWClientSQL.CreateParams;
Var
 I         : Integer;
 ParamList : TStringList;
 Procedure CreateParam(Value : String);
 Var
  FieldDef : TField;
 Begin
  FieldDef := FindField(Value);
  If FieldDef <> Nil Then
   vParams.CreateParam(FieldDef.DataType, Value, ptUnknown)
  Else
   vParams.CreateParam(ftUnknown, Value, ptUnknown);
 End;
Begin
 vParams.Clear;
 ParamList := ReturnParams(vSQL.Text);
 If ParamList <> Nil Then
 For I := 0 to ParamList.Count -1 Do
  CreateParam(ParamList[I]);
 ParamList.Free;
End;

Procedure TRESTDWClientSQL.ProcAfterScroll(DataSet: TDataSet);
Begin
 If State = dsBrowse Then
  Begin
   If Not Active Then
    PrepareDetailsNew
   Else
    Begin
     If RecordCount = 0 Then
      PrepareDetailsNew
     Else
      PrepareDetails(True)
    End;
  End
 Else If State = dsInactive Then
  PrepareDetails(False)
 Else If State = dsInsert Then
  PrepareDetailsNew;
 If Assigned(vOnAfterScroll) Then
  vOnAfterScroll(Dataset);
End;

Procedure TRESTDWClientSQL.GotoRec(Const aRecNo: Integer);
Var
 ActiveRecNo,
 Distance     : Integer;
Begin
 If (RecNo > 0) Then
  Begin
   ActiveRecNo := Self.RecNo;
   If (RecNo <> ActiveRecNo) Then
    Begin
     Self.DisableControls;
     Try
      Distance := RecNo - ActiveRecNo;
      Self.MoveBy(Distance);
     Finally
      Self.EnableControls;
     End;
    End;
  End;
End;

Procedure TRESTDWClientSQL.ProcBeforeDelete(DataSet: TDataSet);
Var
 I : Integer;
 vDetailClient : TRESTDWClientSQL;
Begin
 If Not vReadData Then
  Begin
   vReadData := True;
   vOldStatus   := State;
   Try
    vActualRec   := RecNo;
   Except
    vActualRec   := -1;
   End;
   OldData.Clear;
   SaveToStream(OldData);
   If Assigned(vOnBeforeDelete) Then
    vOnBeforeDelete(DataSet);
   If vCascadeDelete Then
    Begin
     For I := 0 To vMasterDetailList.Count -1 Do
      Begin
       vMasterDetailList.Items[I].ParseFields(TRESTDWClientSQL(vMasterDetailList.Items[I].DataSet).MasterFields);
       vDetailClient        := TRESTDWClientSQL(vMasterDetailList.Items[I].DataSet);
       If vDetailClient <> Nil Then
        Begin
         Try
          vDetailClient.First;
          While Not vDetailClient.Eof Do
           vDetailClient.Delete;
         Finally
          vReadData := False;
         End;
        End;
      End;
    End;
   vReadData := False;
  End;
End;

procedure TRESTDWClientSQL.ProcBeforePost(DataSet: TDataSet);
Var
 vOldState : TDatasetState;
Begin
 If Not vReadData Then
  Begin
   vActualRec := -1;
   vReadData  := True;
   vOldState  := State;
   OldData.Clear;
   SaveToStream(OldData);
   vOldStatus   := State;
   Try
    If vOldState = dsInsert then
     vActualRec  := RecNo + 1
    Else
     vActualRec  := RecNo;
   Except
    vActualRec   := -1;
   End;
   Edit;
   vReadData     := False;
   If Assigned(vOnBeforePost) Then
    vOnBeforePost(DataSet);
  End;
End;

procedure TRESTDWClientSQL.Refresh;
var
  Curso:integer;
begin
    Curso := 0;
    if Active then
    begin
      if RecordCount > 0 then
      Curso:= self.CurrentRecord;
      close;
      Open;
      if Active then
      begin
        if RecordCount > 0 then
        MoveBy(Curso);
      end;
    end;

end;

Procedure TRESTDWClientSQL.ProcAfterClose(DataSet: TDataSet);
Var
 I : Integer;
 vDetailClient : TRESTDWClientSQL;
Begin
 If Assigned(vOnAfterClose) then
  vOnAfterClose(Dataset);
 If vCascadeDelete Then
  Begin
   For I := 0 To vMasterDetailList.Count -1 Do
    Begin
     vMasterDetailList.Items[I].ParseFields(TRESTDWClientSQL(vMasterDetailList.Items[I].DataSet).MasterFields);
     vDetailClient        := TRESTDWClientSQL(vMasterDetailList.Items[I].DataSet);
     If vDetailClient <> Nil Then
      vDetailClient.Close;
    End;
  End;
End;

Procedure TRESTDWClientSQL.ProcAfterInsert(DataSet: TDataSet);
Var
 I : Integer;
 vFields       : TStringList;
 vDetailClient : TRESTDWClientSQL;
 Procedure CloneDetails(Value : TRESTDWClientSQL; FieldName : String);
 Begin
  If (FindField(FieldName) <> Nil) And (Value.FindField(FieldName) <> Nil) Then
   FindField(FieldName).Value := Value.FindField(FieldName).Value;
 End;
 Procedure ParseFields(Value : String);
 Var
  vTempFields : String;
 Begin
  vFields.Clear;
  vTempFields := Value;
  While (vTempFields <> '') Do
   Begin
    If Pos(';', vTempFields) > 0 Then
     Begin
      vFields.Add(UpperCase(Trim(Copy(vTempFields, 1, Pos(';', vTempFields) -1))));
      System.Delete(vTempFields, 1, Pos(';', vTempFields));
     End
    Else
     Begin
      vFields.Add(UpperCase(Trim(vTempFields)));
      vTempFields := '';
     End;
    vTempFields := Trim(vTempFields);
   End;
 End;
Begin
 vDetailClient := vMasterDataSet;
 If (vDetailClient <> Nil) And (Fields.Count > 0) Then
  Begin
   vFields     := TStringList.Create;
   ParseFields(MasterFields);
   For I := 0 To vFields.Count -1 Do
    Begin
     If vDetailClient.FindField(vFields[I]) <> Nil Then
      CloneDetails(vDetailClient, vFields[I]);
    End;
   vFields.Free;
  End;
 If Assigned(vOnAfterInsert) Then
  vOnAfterInsert(Dataset);
End;

Procedure TRESTDWClientSQL.ProcAfterOpen(DataSet: TDataSet);
Begin
 If Assigned(vOnAfterOpen) Then
  vOnAfterOpen(Dataset);
End;

Procedure TRESTDWClientSQL.ProcAfterPost(DataSet : TDataSet);
Begin
 If Not vReadData Then
  Begin
   If Assigned(vOnAfterPost) Then
    vOnAfterPost(Dataset);
  End;
End;

Function  TRESTDWClientSQL.ApplyUpdates(Var Error : String) : Boolean;
{
var
 LDeltaList    : TJSONValue;
 vError        : Boolean;
 vMessageError : String;
 oJsonObject   : TJSONObject;
 MemTable      : TDataset;
 Original      : TStringStream;
 gZIPStream    : TMemoryStream;
 Function GetDeltas : TJSONValue;
 Begin
  UpdateOptions.CountUpdatedRecords := vCacheUpdateRecords;
  If State In [dsEdit, dsInsert] Then
   Post;
  Result := TJSONValue.Create;
  TJSONValueWriter.ListAdd(Result, vUpdateTableName, TDataset(Self));
 End;
}
Begin
{
 If vReadData Then
  Begin
   Result := True;
   Exit;
  End;
 LDeltaList := GetDeltas;
 If vRESTDataBase <> Nil Then
  Begin
   If vRESTDataBase.vCompression Then
    Begin
     oJsonObject   := TJSONObject.Create;
      TFDJSONInterceptor.DataSetsToJSONObject(LDeltaList, oJsonObject);
      LDeltaList.Free;
      LDeltaList   := TJSONValue.Create;
      MemTable     := TDataset.Create(Nil);
      Original     := TStringStream.Create(oJsonObject.ToString);
      gZIPStream   := TMemoryStream.Create;
     Try
       //make it gzip
      doGZIP(Original, gZIPStream);
      MemTable.FieldDefs.Add('compress', ftBlob);
      MemTable.CreateDataSet;
      MemTable.CachedUpdates := True;
      MemTable.Insert;
      TBlobField(MemTable.FieldByName('compress')).LoadFromStream(gZIPStream);
      MemTable.Post;
      TJSONValueWriter.ListAdd(LDeltaList, 'TempTable', MemTable);
     Finally
      MemTable.Free;
      Original.Free;
      gZIPStream.Free;
     End;
    End;
  End
 Else
  Begin
   Raise Exception.Create(PChar('Empty Database Property'));
   Exit;
  End;
 If Assigned(vRESTDataBase) And (Trim(UpdateTableName) <> '') Then
  vRESTDataBase.ApplyUpdates(vSQL, vParams, LDeltaList, Trim(vUpdateTableName), vError, vMessageError)
 Else
  Begin
   vError := True;
   If Not Assigned(vRESTDataBase) Then
    vMessageError := 'No RESTDatabase defined'
   Else
    vMessageError := 'No UpdateTableName defined';
  End;
 Result       := Not vError;
 Error        := vMessageError;
 vErrorBefore := vError;
 If (Result) And (Not(vError)) Then
  Begin
   TDataset(Self).ApplyUpdates(-1);
   If Not (vErrorBefore)     Then
    TDataset(Self).CommitUpdates;
  End
 Else If vError Then
  Begin
   TDataset(Self).Close;
   OldData.Position := 0;
   LoadFromStream(OldData, TFDStorageFormat.sfBinary);
   vReadData  := False;
  End;
 Try
  If vActualRec > -1 Then
   GoToRec(vActualRec);
 Except
 End;
}
End;

Function  TRESTDWClientSQL.ParamByName(Value : String) : TParam;
Var
 I : Integer;
 vParamName,
 vTempParam : String;
 Function CompareValue(Value1, Value2 : String) : Boolean;
 Begin
   Result := Value1 = Value2;
 End;
Begin
 Result := Nil;
 For I := 0 to vParams.Count -1 do
  Begin
   vParamName := UpperCase(vParams[I].Name);
   vTempParam := UpperCase(Trim(Value));
   if CompareValue(vTempParam, vParamName) then
    Begin
     Result := vParams[I];
     Break;
    End;
  End;
End;

Function TRESTDWClientSQL.ParamCount: Integer;
Begin
 Result := vParams.Count;
End;

Procedure TRESTDWClientSQL.FieldDefsToFields;
Var
 I          : Integer;
 FieldValue : TField;
Begin
 For I := 0 To FieldDefs.Count -1 Do
  Begin
   FieldValue           := TField.Create(Self);
   FieldValue.DataSet   := Self;
   FieldValue.FieldName := FieldDefs[I].Name;
   FieldValue.SetFieldType(FieldDefs[I].DataType);
   FieldValue.Size      := FieldDefs[I].Size;
//   FieldValue.Offset    := FieldDefs[I].Precision;
   Fields.Add(FieldValue);
  End;
End;

Function TRESTDWClientSQL.FirstWord(Value : String) : String;
Var
 vTempValue : PChar;
Begin
 vTempValue := PChar(Trim(Value));
 While Not (vTempValue^ = #0) Do
  Begin
   If (vTempValue^ <> ' ') Then
    Result := Result + vTempValue^
   Else
    Break;
   Inc(vTempValue);
  End;
End;

Procedure TRESTDWClientSQL.ExecOrOpen;
Var
 vError : String;
 Function OpenSQL : Boolean;
 Var
  vSQLText : String;
 Begin
  vSQLText := UpperCase(Trim(vSQL.Text));
  Result := FirstWord(vSQLText) = 'SELECT';
 End;
Begin
 If OpenSQL Then
  Open
 Else
  Begin
   If Not ExecSQL(vError) Then
    Begin
     If csDesigning in ComponentState Then
      Raise Exception.Create(PChar(vError))
     Else
      Begin
       If Assigned(vOnGetDataError) Then
        vOnGetDataError(False, vError)
       Else
        Raise Exception.Create(PChar(vError));
      End;
    End;
  End;
End;

Function TRESTDWClientSQL.ExecSQL(Var Error : String) : Boolean;
Var
 vError        : Boolean;
 vMessageError : String;
Begin
 Result := False;
 Try
  If vRESTDataBase <> Nil Then
   Begin
    vRESTDataBase.ExecuteCommand(vSQL, vParams, vError, vMessageError, True);
    Result := Not vError;
    Error  := vMessageError;
   End
  Else
   Raise Exception.Create(PChar('Empty Database Property'));
 Except
 End;
End;

Function TRESTDWClientSQL.InsertMySQLReturnID : Integer;
Var
 vError        : Boolean;
 vMessageError : String;
Begin
 Result := -1;
 Try
  If vRESTDataBase <> Nil Then
   Result := vRESTDataBase.InsertMySQLReturnID(vSQL, vParams, vError, vMessageError)
  Else 
   Raise Exception.Create(PChar('Empty Database Property')); 
 Except
 End;
End;

Procedure TRESTDWClientSQL.OnChangingSQL(Sender: TObject);
Begin
 CreateParams;
End;

Procedure TRESTDWClientSQL.SetSQL(Value : TStringList);
Var
 I : Integer;
Begin
 vSQL.Clear;
 For I := 0 To Value.Count -1 do
  vSQL.Add(Value[I]);
End;

Procedure TRESTDWClientSQL.CreateDataSet;
Begin
 vCreateDS := True;
 TJvMemoryData(Self).Open;
 vActive   := True;
 vCreateDS := False;
End;

Procedure TRESTDWClientSQL.Close;
Begin
 vActive := False;
 Inherited Close;
// TDataset(Self).Fields.Clear;
// TDataset(Self).FieldDefs.Clear;
End;

Procedure TRESTDWClientSQL.CommitData;
Begin

End;

Procedure TRESTDWClientSQL.Open;
Begin
 If Not vInactive Then
  Begin
   If Not vActive Then
    SetActiveDB(True);
  End;
 If vActive Then
  Inherited Open;
End;

Procedure TRESTDWClientSQL.Open(SQL : String);
Begin
 If Not vActive Then
  Begin
   Close;
   vSQL.Clear;
   vSQL.Add(SQL);
   SetActiveDB(True);
   Inherited Open;
  End;
End;

Procedure TRESTDWClientSQL.OpenCursor(InfoQuery: Boolean);
Begin
 If Not (vBeforeClone) And Not(vInactive) Then
  Begin
   vBeforeClone := True;
   If vRESTDataBase <> Nil Then
    Begin
     vRESTDataBase.Active := True;
     If vRESTDataBase.Active Then
      Begin
       Try
        Try
         If Not (vActive) And (Not (vCreateDS)) Then
          Begin
           If GetData Then
            Begin
             If Not (csDesigning in ComponentState) Then
              vActive := True;
             Inherited OpenCursor(InfoQuery);
            End;
          End
         Else
          Inherited OpenCursor(InfoQuery);
        Except
         On E : Exception do
          Begin
           If csDesigning in ComponentState Then
            Raise Exception.Create(PChar(E.Message))
           Else
            Begin
             If Assigned(vOnGetDataError) Then
              vOnGetDataError(False, E.Message)
             Else
              Raise Exception.Create(PChar(E.Message));
            End;
          End;
        End;
       Finally
        vBeforeClone := False;
       End;
      End;
    End
   Else
    Raise Exception.Create(PChar('Empty Database Property'));
  End
 Else If vInactive Then
  Begin
   Try
    Inherited OpenCursor(InfoQuery);
    If Not (csDesigning in ComponentState) Then
     vActive := True;
   Except
    On E : Exception do
     Begin
      If csDesigning in ComponentState Then
       Raise Exception.Create(PChar(E.Message))
      Else
       Begin
        If Assigned(vOnGetDataError) Then
         vOnGetDataError(False, E.Message)
        Else
         Raise Exception.Create(PChar(E.Message));
       End;
     End;
   End;
  End;
End;

Procedure TRESTDWClientSQL.OldAfterPost(DataSet: TDataSet);
Begin
 vErrorBefore := False;
 If Not vReadData Then
  Begin
   If Assigned(vOnAfterPost) Then
    vOnAfterPost(Self);
  End;
End;

Procedure TRESTDWClientSQL.OldAfterDelete(DataSet: TDataSet);
Begin
 vErrorBefore := False;
 Try
  If Assigned(vOnAfterDelete) Then
   vOnAfterDelete(Self);
  If Not vErrorBefore Then
   CommitData;
 Finally
  vReadData := False;
 End;
End;

Procedure TRESTDWClientSQL.SetUpdateTableName(Value : String);
Begin
 vCommitUpdates    := Trim(Value) <> '';
 vUpdateTableName  := Value;
End;

Procedure TRESTDWClientSQL.Loaded;
Begin
 Inherited Loaded;
End;

Procedure TRESTDWClientSQL.CloneDefinitions(Source : TJvMemoryData; aSelf : TJvMemoryData);
Var
 I, A : Integer;
Begin
 aSelf.Close;
 For I := 0 to Source.FieldDefs.Count -1 do
  Begin
   For A := 0 to aSelf.FieldDefs.Count -1 do
    If Uppercase(Source.FieldDefs[I].Name) = Uppercase(aSelf.FieldDefs[A].Name) Then
     Begin
      aSelf.FieldDefs.Delete(A);
      Break;
     End;
  End;
 For I := 0 to Source.FieldDefs.Count -1 do
  Begin
   If Trim(Source.FieldDefs[I].Name) <> '' Then
    Begin
     With aSelf.FieldDefs.AddFieldDef Do
      Begin
       Name     := Source.FieldDefs[I].Name;
       DataType := Source.FieldDefs[I].DataType;
       Size     := Source.FieldDefs[I].Size;
       Required := Source.FieldDefs[I].Required;
       CreateField(aSelf);
      End;
    End;
  End;
 If aSelf.FieldDefs.Count > 0 Then
  aSelf.Open;
End;

Procedure TRESTDWClientSQL.PrepareDetailsNew;
Var
 I : Integer;
 vDetailClient : TRESTDWClientSQL;
Begin
 For I := 0 To vMasterDetailList.Count -1 Do
  Begin
   vMasterDetailList.Items[I].ParseFields(TRESTDWClientSQL(vMasterDetailList.Items[I].DataSet).MasterFields);
   vDetailClient        := TRESTDWClientSQL(vMasterDetailList.Items[I].DataSet);
   If vDetailClient <> Nil Then
    Begin
     If vDetailClient.Active Then
      Begin
       vDetailClient.ClearFields;
       vDetailClient.ProcAfterScroll(vDetailClient);
      End;
    End;
  End;
End;

Procedure TRESTDWClientSQL.PrepareDetails(ActiveMode : Boolean);
Var
 I : Integer;
 vDetailClient : TRESTDWClientSQL;
 Procedure CloneDetails(Value : TRESTDWClientSQL);
 Var
  I : Integer;
 Begin
  For I := 0 To Value.Params.Count -1 Do
   Begin
    If FindField(Value.Params[I].Name) <> Nil Then
     Begin
      Value.Params[I].DataType := FindField(Value.Params[I].Name).DataType;
      Value.Params[I].Size     := FindField(Value.Params[I].Name).Size;
      Value.Params[I].Value    := FindField(Value.Params[I].Name).Value;
     End;
   End;
 End;
Begin
 If vReadData Then
  Exit;
 For I := 0 To vMasterDetailList.Count -1 Do
  Begin
   vMasterDetailList.Items[I].ParseFields(TRESTDWClientSQL(vMasterDetailList.Items[I].DataSet).MasterFields);
   vDetailClient        := TRESTDWClientSQL(vMasterDetailList.Items[I].DataSet);
   If vDetailClient <> Nil Then
    Begin
     vDetailClient.Active := False;
     CloneDetails(vDetailClient);
     vDetailClient.Active := ActiveMode;
    End;
  End;
End;

Function TRESTDWClientSQL.GetData : Boolean;
Var
 LDataSetList  : TJSONValue;
 vError        : Boolean;
 vMessageError : String;
Begin
 Result := False;
 LDataSetList := nil;
 Self.Close;
 If Assigned(vRESTDataBase) Then
  Begin
   Try
    LDataSetList := vRESTDataBase.ExecuteCommand(vSQL, vParams, vError, vMessageError, False);
    If (LDataSetList <> Nil) And (Not (vError)) Then
     Begin
      Try
       LDataSetList.WriteToDataset(dtFull, LDataSetList.ToJSON, Self);
       Result := True;
      Except
      End;
     End;
   Except
    If LDataSetList <> Nil Then
     LDataSetList.Free;
   End;
   If vError Then
    Begin
     If csDesigning in ComponentState Then
      Raise Exception.Create(PChar(vMessageError))
     Else
      Begin
       If Assigned(vOnGetDataError) Then
        vOnGetDataError(Not(vError), vMessageError)
       Else
        Raise Exception.Create(PChar(vMessageError));
      End;
    End;
  End
 Else
  Raise Exception.Create(PChar('Empty Database Property'));
End;

Procedure TRESTDWClientSQL.SaveToStream(var Stream: TMemoryStream);
Begin

End;

Procedure TRESTDWClientSQL.SetActiveDB(Value : Boolean);
Begin
 If vInactive then
  Begin
   vActive := Value;
   Exit;
  End;
 vActive := False;
 If (vRESTDataBase <> Nil) And (Value) Then
  Begin
   If vRESTDataBase <> Nil Then
    If Not vRESTDataBase.Active Then
     vRESTDataBase.Active := True;
   If Not vRESTDataBase.Active then
    Exit;
   Try
    If Not(vActive) And (Value) Then
     Begin
      Filter                       := '';
      Filtered                     := False;
      vActive                      := GetData;
     End;
    If State = dsBrowse Then
     PrepareDetails(True)
    Else If State = dsInactive Then
     PrepareDetails(False);
   Except
    On E : Exception do
     Begin
      If csDesigning in ComponentState Then
       Raise Exception.Create(PChar(E.Message))
      Else
       Begin
        If Assigned(vOnGetDataError) Then
         vOnGetDataError(False, E.Message)
        Else
         Raise Exception.Create(PChar(E.Message));
       End;
     End;
   End;
  End
 Else
  Begin
   vActive := False;
   Close;
   If Value Then
    If vRESTDataBase = Nil Then
     Raise Exception.Create(PChar('Empty Database Property'));
  End;
End;

Procedure TRESTDWClientSQL.SetCacheUpdateRecords(Value: Boolean);
Begin
 vCacheUpdateRecords := Value;
End;

constructor TRESTDWStoredProc.Create(AOwner: TComponent);
begin
 Inherited;
 vParams   := TParams.Create;
 vParams   := Nil;
 vProcName := '';
end;

destructor TRESTDWStoredProc.Destroy;
begin
 vParams.Free;
 Inherited;
end;

Function TRESTDWStoredProc.ExecProc(Var Error : String) : Boolean;
Begin
 If vRESTDataBase <> Nil Then
  Begin
   If vParams.Count > 0 Then
    vRESTDataBase.ExecuteProcedure(vProcName, vParams, Result, Error);
  End
 Else
  Raise Exception.Create(PChar('Empty Database Property'));
End;

Function TRESTDWStoredProc.ParamByName(Value: String): TParam;
Begin
 Result := Params.ParamByName(Value);
End;

procedure TRESTDWStoredProc.SetDataBase(const Value: TRESTDWDataBase);
begin
 vRESTDataBase := Value;
end;

Procedure TRESTDWDataBase.SetMyIp(Value: String);
Begin
End;

Function TRESTDWClientSQL.FieldDefExist(Value: String): TFieldDef;
Var
 I : Integer;
Begin
 Result := Nil;
 For I := 0 To FieldDefs.Count -1 Do
  Begin
   If UpperCase(Value) = UpperCase(FieldDefs[I].Name) Then
    Begin
     Result := FieldDefs[I];
     Break;
    End;
  End;
End;

end.
