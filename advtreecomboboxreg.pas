{********************************************************************}
{ TAdvTreeComboBox component                                         }
{ for Delphi & C++Builder                                            }
{ version 1.0                                                        }
{                                                                    }
{ written by TMS Software                                            }
{            copyright � 2003                                        }
{            Email : info@tmssoftware.com                            }
{            Web : http://www.tmssoftware.com                        }
{                -                                                   }
{ The source code is given as is. The author is not responsible      }
{ for any possible damage done due to the use of this code.          }
{ The component can be freely used in any application. The source    }
{ code remains property of the author and may not be distributed     }
{ freely as such.                                                    }
{********************************************************************}

unit AdvTreeComboBoxReg;

{$I TMSDEFS.INC}
interface

uses
  Classes, AdvTreeComboBox;

{$IFDEF TMSDOTNET}
{$R TAdvTreeComboBox.bmp}
{$ENDIF}
  
procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('TMS Edits', [TAdvTreeComboBox]);
end;


end.
