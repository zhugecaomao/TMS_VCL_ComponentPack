{***************************************************************************}
{ TAdvHintInfo component                                                    }
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

{$I TMSDEFS.INC}

unit AdvHintInfo;

interface

uses
  Classes
  {$IFNDEF TMSDOTNET}
  , GDIPicture
  {$ENDIF}
  {$IFDEF TMSDOTNET}
  , Graphics
  {$ENDIF}
  ;

type
   {$IFDEF TMSDOTNET}
   TGDIPPicture = class(TPicture);
   {$ENDIF}

   TAdvHintInfo = class(TPersistent)
   private
    FPicture: TGDIPPicture;
    FShowHelp: boolean;
    FNotes: TStrings;
    FTitle: string;
    FWideTitle: widestring;
    FWideNotes: widestring;
    procedure SetNotes(const Value: TStrings);
    procedure SetPicture(const Value: TGDIPPicture);
   public
     constructor Create;
     destructor Destroy; override;
     procedure Assign(Source: TPersistent); override;
     property WideTitle: widestring read FWideTitle write FWideTitle;
     property WideNotes: widestring read FWideNotes write FWideNotes;
   published
     property Title: string read FTitle write FTitle;
     property Notes: TStrings read FNotes write SetNotes;
     property Picture: TGDIPPicture read FPicture write SetPicture;
     property ShowHelp: boolean read FShowHelp write FShowHelp default false;
   end;

implementation

{ TAdvHintInfo }

procedure TAdvHintInfo.Assign(Source: TPersistent);
begin
  if (Source is TAdvHintInfo) then
  begin
    Title := (Source as TAdvHintInfo).Title;
    Notes.Assign((Source as TAdvHintInfo).Notes);
    ShowHelp := (Source as TAdvHintInfo).ShowHelp;
    Picture.Assign((Source as TAdvHintInfo).Picture);
    WideTitle := (Source as TAdvHintInfo).WideTitle;
    WideNotes := (Source as TAdvHintInfo).WideNotes;
  end;
end;

constructor TAdvHintInfo.Create;
begin
  inherited;
  FNotes := TStringList.Create;
  FPicture := TGDIPPicture.Create;
end;

destructor TAdvHintInfo.Destroy;
begin
  FNotes.Free;
  FPicture.Free;
  inherited;
end;

procedure TAdvHintInfo.SetNotes(const Value: TStrings);
begin
  FNotes.Assign(Value);
end;

procedure TAdvHintInfo.SetPicture(const Value: TGDIPPicture);
begin
  FPicture.Assign(Value);
end;

end.