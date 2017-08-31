unit uDWDatamodule;

interface

Uses
  SysUtils, Classes, SysTypes, uDWJSONObject, uDWConstsData;

 Type
  TServerMethodDataModule = Class(TDataModule)
  Private
   vReplyEvent : TReplyEvent;
  Public
   Encoding: TEncodeSelect;
  Published
   Property OnReplyEvent : TReplyEvent Read vReplyEvent Write vReplyEvent;
 End;

implementation

{$IFDEF FPC}
{$R *.lfm}
{$ELSE}
{$R *.dfm}
{$ENDIF}

end.
