{
 Esse pacote de Componentes foi desenhado com o Objetivo de ajudar as pessoas a desenvolverem
com WebServices REST o mais pr�ximo poss�vel do desenvolvimento local DB, com componentes de
f�cil configura��o para que todos tenham acesso as maravilhas dos WebServices REST/JSON DataSnap.

Desenvolvedor Principal : Gilberto Rocha da Silva (XyberX)
Empresa : XyberPower Desenvolvimento
}

unit uPoolerServerMethods;

interface

uses System.SysUtils, System.Classes, Soap.EncdDecd,   uRestCompressTools, System.ZLib
      {$if CompilerVersion >= 28}
       ,System.NetEncoding, System.JSON
     {$ifend};

implementation

end.
