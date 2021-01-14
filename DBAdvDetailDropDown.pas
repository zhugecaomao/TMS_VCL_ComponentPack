{***************************************************************************}
{ TDBAdvDetailDropDown component                                              }
{ for Delphi & C++Builder                                                   }
{                                                                           }
{ written by TMS Software                                                   }
{            copyright � 2009                                               }
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

unit DBAdvDetailDropDown;

interface

uses
  AdvDetailDropDown, Windows, Classes, DB, DBCtrls, Messages, Controls;

type
  TDBAdvDetailDropDown = class(TAdvDetailDropDown)
  private
    FDataLink: TFieldDataLink;
    FOldState: TDataSetState;
    FInternalCall: Boolean;
    procedure DataUpdate(Sender: TObject);
    procedure DataChange(Sender: TObject);
    procedure ActiveChange(Sender: TObject);

    function GetDataField: string;
    function GetDataSource: TDataSource;
    procedure SetDataField(const Value: string);
    procedure SetDataSource(const Value: TDataSource);
    procedure CMGetDataLink(var Message: TMessage); message CM_GETDATALINK;
  protected
    function EditCanModify: Boolean; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure Change; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function ExecuteAction(Action: TBasicAction): Boolean; override;
    function UpdateAction(Action: TBasicAction): Boolean; override;
  published
    property DataField: string read GetDataField write SetDataField;
    property DataSource: TDataSource read GetDataSource write SetDataSource;
  end;

implementation

{ TDBAdvDropDown }

procedure TDBAdvDetailDropDown.ActiveChange(Sender: TObject);
begin
  if Assigned(FDataLink) then
  begin
    if Assigned(FDataLink.DataSet) then
    begin
      if not FDataLink.DataSet.Active then
        Text := '';
    end
    else
    begin
      Text := '';
    end;
  end;
end;

procedure TDBAdvDetailDropDown.Change;
begin
  inherited;
  if not FInternalCall then
  begin
    if EditCanModify then
    begin
      FDataLink.Modified;
    end;
  end;
end;

procedure TDBAdvDetailDropDown.CMGetDataLink(var Message: TMessage);
begin
  Message.Result := Integer(FDataLink);
end;

constructor TDBAdvDetailDropDown.Create(AOwner: TComponent);
begin
  inherited;
  FDataLink := TFieldDataLink.Create;
  FDataLink.Control := Self;
  FDataLink.OnDataChange := DataChange;
  FDataLink.OnUpdateData := DataUpdate;
  FDataLink.OnActiveChange := ActiveChange;

  FInternalCall:= false;
end;

procedure TDBAdvDetailDropDown.DataChange(Sender: TObject);
begin
  if not Assigned(FDataLink.DataSet) then
    Exit;

  if Assigned(FDataLink.Field) then
  begin
    if not (FDataLink.DataSet.State = dsInsert) then
    begin
      if (FOldState <> dsInsert)  then
      begin
        FInternalCall:= true;
        if FDataLink.Field.AsString = '' then
        begin
          Text := '';
        end
        else
        begin
          Text := FDataLink.Field.DisplayText;
        end;
        FInternalCall:= false;
      end
      else
      begin
        Text := FDataLink.Field.DisplayText;
      end;
    end;

    if (FDataLink.DataSet.State = dsInsert) then
    begin
      Text := FDataLink.Field.DisplayText;
    end;
  end;

  FOldState := FDataLink.DataSet.State;
end;

procedure TDBAdvDetailDropDown.DataUpdate(Sender: TObject);
begin
  if Assigned(FDataLink.Field) and FDataLink.Editing then
  begin
    FDataLink.Field.Value := Text;
  end;
end;

destructor TDBAdvDetailDropDown.Destroy;
begin
  FDataLink.Free;
  FDataLink := nil;

  inherited;
end;

function TDBAdvDetailDropDown.EditCanModify: Boolean;
begin
  FDataLink.OnDataChange := nil;
  try
    Result := FDataLink.Edit;
  finally
    FDataLink.OnDataChange := DataChange;
  end;
end;

function TDBAdvDetailDropDown.ExecuteAction(Action: TBasicAction): Boolean;
begin
  Result := inherited ExecuteAction(Action) or (FDataLink <> nil) and
    FDataLink.ExecuteAction(Action);
end;

function TDBAdvDetailDropDown.GetDataField: string;
begin
  Result := FDataLink.FieldName;
end;

function TDBAdvDetailDropDown.GetDataSource: TDataSource;
begin
  Result := FDataLink.DataSource;
end;

procedure TDBAdvDetailDropDown.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited;

  if (csDestroying in ComponentState) then
    Exit;

  if (Operation = opRemove) and (FDataLink <> nil)
      and (AComponent = DataSource) then
    DataSource := nil;
end;

procedure TDBAdvDetailDropDown.SetDataField(const Value: string);
begin
  FDataLink.FieldName := Value;
end;

procedure TDBAdvDetailDropDown.SetDataSource(const Value: TDataSource);
begin
  if not (FDataLink.DataSourceFixed and (csLoading in ComponentState)) then
    FDataLink.DataSource := Value;
  if Value <> nil then Value.FreeNotification(Self);
end;

function TDBAdvDetailDropDown.UpdateAction(Action: TBasicAction): Boolean;
begin
  Result := inherited UpdateAction(Action) or (FDataLink <> nil) and
    FDataLink.UpdateAction(Action);
end;

end.
