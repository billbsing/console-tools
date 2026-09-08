unit ConsoleTools;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Generics.Collections;

type

  { TConsoleTextWord }

  TConsoleTextWord = class(TObject)
  private
    FText: ansistring;
    FLength: integer;
  public
    constructor Create(AText: ansistring; ALength: integer);
    property Length: integer read FLength;
    property Text: ansistring read FText;
  end;

  TConsoleTextWordList = {$ifdef FPC}specialize{$endif}TObjectList<TConsoleTextWord>;

  { TConsoleTextSplitter }

  TConsoleTextSplitter = class(TObject)
  private
    FWordList: TConsoleTextWordList;
  protected
    procedure SetText(AText: ansistring);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure AddWord(AText: ansistring; ALength: integer);
    procedure Render(StartPosition, LineLength: integer);
    property Text: ansistring write SetText;
  end;


  TArgumentValidationType = (avString, avInteger, avChoice, avSwitch);
  TArgumentState = (asRequired, asOptional);

  EArgumentParserException = class(Exception);


  { TArgumentBase }

  TArgumentBase = class(TObject)
  private
    FChoiceList: TStringList;
    FName: ansistring;
    FDescription: ansistring;
    FValidationType: TArgumentValidationType;
    FIsValue: boolean;
    FValue: ansistring;
    FHelpParameter: ansistring;
  protected
    function GetChoiceListText: ansistring; virtual;
    procedure SetChoiceListText(ACommaText: ansistring);
  public
    constructor Create(AName, ADescription: ansistring);
    destructor Destroy; override;
    procedure AddChoice(AName, ADescription: ansistring);
    function ValueAsInteger: integer;
    procedure ValidateValue; virtual;
    property Name: ansistring read FName;
    property Description: ansistring read FDescription;
    property ChoiceListText: ansistring read GetChoiceListText write SetChoiceListText;
    property ChoiceList: TStringList read FChoiceList;
    property Value: ansistring read FValue write FValue;
    property IsValue: boolean read FIsValue write FIsValue;
    property ValidationType: TArgumentValidationType read FValidationType write FValidationType;
    property HelpParameter: ansistring read FHelpParameter write FHelpParameter;

  end;

  { TArgument }

  TArgument = class(TArgumentBase)
  private
    FState: TArgumentState;
  protected
    function GetChoiceListText: ansistring; override;
  public
    constructor Create(AName, ADescription: ansistring; AState: TArgumentState);
    destructor Destroy; override;
    property State: TArgumentState read FState write FState;
  end;

  { TOption }

  TOption = class(TArgumentBase)
  private
    FLong: ansistring;
    FShort: ansichar;
  public
    constructor Create(AName, AShort, ALong, ADescription: ansistring);
    destructor Destroy; override;
    function IsShort: boolean;
    function IsLong: boolean;
    property Short: ansichar read FShort;
    property Long: ansistring read FLong;
  end;

  TOptionMap = {$ifdef FPC}specialize{$endif}TObjectDictionary<ansistring, TOption>;
  TArgumentList = {$ifdef FPC}specialize{$endif}TObjectList<TArgument>;
  TArgumentIndexMap = {$ifdef FPC}specialize{$endif}TDictionary<ansistring, integer>;

  { TArgumentParser }

  TArgumentParser = class(TObject)
  private
    FTitle: ansistring;
    FDescription: ansistring;
    FOptions: TOptionMap;
    FArguments: TArgumentList;
    FArgumentIndexMap: TArgumentIndexMap;
    FLineLength: integer;
  protected
    function FindOptionShort(AValue: char): TOption;
    function FindOptionLong(AValue: ansistring): TOption;
    function GetOption(AName: ansistring): TOption;
    function GetArgumentFromName(AName: ansistring): TArgument;
    function GetArgumentFromIndex(AIndex: integer): TArgument;
    procedure ShowHelpUsage;
    procedure ShowHelpDescription;
    procedure ShowHelpOptions;
    procedure ShowHelpArguments;
    function ParseOption(Out ArgIndex: integer): boolean;
    procedure BuildSortedOptions(AList: TStringList);
    procedure SortChoiceLists;
  public
    constructor Create;
    destructor Destroy; override;
    function AddOption(AName, Short, Long, ADescription, HelpParameter: ansistring; AValidationType: TArgumentValidationType = avString): TOption;
    function AddArgument(AName, ADescription, HelpParameter: ansistring; AState: TArgumentState = asRequired; AValidationType: TArgumentValidationType = avString): TArgument;
    function GetOptionValueAsString(AName: ansistring; DefaultValue: ansistring = ''): ansistring;
    function GetOptionValueAsInteger(AName: ansistring; DefaultValue: integer = 0): integer;
    function GetArgumentValueAsString(AName: ansistring; DefaultValue: ansistring = ''): ansistring;
    procedure Parse;
    procedure Validate;
    procedure ShowHelp;
    function IsOption(AName: ansistring): boolean;
    property Title: ansistring read FTitle write FTitle;
    property Description: ansistring read FDescription write FDescription;
    property LineLength: integer read FLineLength write FLineLength;
    property Options[AName: ansistring]: TOption read GetOption;
    property Arguments[AIndex: integer]: TArgument read GetArgumentFromIndex;
    property ArgumentNames[AName: ansistring]: TArgument read GetArgumentFromName;
  end;


const

  SHORT_OPTION_EMPTY = #0;
  ARGUMENT_PARSER_DEFAULT_LINE_LENGTH = 164;

  // Reset sequence (crucial to clear styles after writing text)
  ANSI_RESET = #27'[0m';
  ANSI_BOLD = #27'[1m';

  // Standard Foreground Colors (30-37)
  ANSI_BLACK = #27'[30m';
  ANSI_RED = #27'[31m';
  ANSI_GREEN = #27'[32m';
  ANSI_YELLOW = #27'[33m';
  ANSI_BLUE = #27'[34m';
  ANSI_MAGENTA = #27'[35m';
  ANSI_CYAN = #27'[36m';
  ANSI_WHITE = #27'[37m';

  // Bright/Light Foreground Colors (90-97)
  ANSI_BRIGHT_BLACK = #27'[90m'; // Often used as Dark Gray
  ANSI_BRIGHT_RED = #27'[91m';
  ANSI_BRIGHT_GREEN = #27'[92m';
  ANSI_BRIGHT_YELLOW = #27'[93m';
  ANSI_BRIGHT_BLUE = #27'[94m';
  ANSI_BRIGHT_MAGENTA = #27'[95m';
  ANSI_BRIGHT_CYAN = #27'[96m';
  ANSI_BRIGHT_WHITE = #27'[97m';

  // Standard Background Colors (40-47)
  ANSI_BG_BLACK = #27'[40m';
  ANSI_BG_RED = #27'[41m';
  ANSI_BG_GREEN = #27'[42m';
  ANSI_BG_YELLOW = #27'[43m';
  ANSI_BG_BLUE = #27'[44m';
  ANSI_BG_MAGENTA = #27'[45m';
  ANSI_BG_CYAN = #27'[46m';
  ANSI_BG_WHITE = #27'[47m';

  // Bright/Light Background Colors (100-107)
  ANSI_BG_BRIGHT_BLACK = #27'[100m';
  ANSI_BG_BRIGHT_RED = #27'[101m';
  ANSI_BG_BRIGHT_GREEN = #27'[102m';
  ANSI_BG_BRIGHT_YELLOW = #27'[103m';
  ANSI_BG_BRIGHT_BLUE = #27'[104m';
  ANSI_BG_BRIGHT_MAGENTA = #27'[105m';
  ANSI_BG_BRIGHT_CYAN = #27'[106m';
  ANSI_BG_BRIGHT_WHITE = #27'[107m';

implementation

uses StrUtils;

  { TConsoleTextWord }

constructor TConsoleTextWord.Create(AText: ansistring; ALength: integer);
begin
  FText := AText;
  FLength := ALength;
end;

{ TConsoleTextSplitter }

procedure TConsoleTextSplitter.SetText(AText: ansistring);
var
  Words: TStringArray;
  Index: integer;
  WordText: ansistring;
begin
  Clear;
  Words := AText.Split([' ']);
  for Index := Low(Words) to High(Words) do
  begin
    WordText := Words[Index];
    AddWord(WordText, WordText.Length);
  end;
end;

constructor TConsoleTextSplitter.Create;
begin
  FWordList := TConsoleTextWordList.Create(True);
end;

destructor TConsoleTextSplitter.Destroy;
begin
  FreeAndNil(FWordList);
  inherited Destroy;
end;

procedure TConsoleTextSplitter.Clear;
begin
  FWordList.Clear;
end;

procedure TConsoleTextSplitter.AddWord(AText: ansistring; ALength: integer);
var
  AWord: TConsoleTextWord;
begin
  AWord := TConsoleTextWord.Create(AText, ALength);
  FWordList.Add(AWord);
end;

procedure TConsoleTextSplitter.Render(StartPosition, LineLength: integer);
var
  AWord: TConsoleTextWord;
  Position: integer;
begin
  Position := StartPosition;
  for AWord in FWordList do
  begin
    // WriteLn(Format('%d - %d', [Position, LineLength]));
    if (Position + AWord.Length + 1) > LineLength then
    begin
      WriteLn;
      Position := StartPosition;
      Write(StringOfChar(' ', StartPosition));
    end;
    Write(AWord.Text + ' ');
    Inc(Position, AWord.Length + 1);
  end;
  // if (Position > StartPosition) then WriteLn;
end;


function GetOptionShort(AValue: ansistring): char;
begin
  Result := SHORT_OPTION_EMPTY;
  if AValue.Length <> 2 then
    Exit;
  if AValue.Chars[0] <> '-' then
    Exit;
  Result := AValue.Chars[1];
end;

function GetOptionLong(AValue: ansistring): ansistring;
var
  EqualPosition: integer;
begin
  Result := '';
  if AValue.Length < 3 then
    Exit;
  if (AValue.Chars[0] <> '-') or (AValue.Chars[1] <> '-') then
    Exit;
  EqualPosition := Pos('=', AValue);
  if EqualPosition > 0 then
  begin
    Result := MidStr(AValue, 3, EqualPosition - 3);
    Exit;
  end;
  Result := RightStr(AValue, AValue.Length - 2);
end;

function GetOptionLongValue(AValue: ansistring): ansistring;
var
  EqualPosition: integer;
begin
  Result := '';
  EqualPosition := Pos('=', AValue);
  if EqualPosition > 0 then
  begin
    Result := RightStr(AValue, AValue.Length - EqualPosition);
  end;
end;

{ TArgumentBase }

function TArgumentBase.GetChoiceListText: ansistring;
begin
  Result := FChoiceList.CommaText;
end;

procedure TArgumentBase.SetChoiceListText(ACommaText: ansistring);
begin
  FChoiceList.CommaText := ACommaText;
end;

constructor TArgumentBase.Create(AName, ADescription: ansistring);
begin
  FChoiceList := TStringList.Create;
  FName := AName;
  FDescription := ADescription;
  FValidationType := avString;
end;

destructor TArgumentBase.Destroy;
begin
  FreeAndNil(FChoiceList);
  inherited Destroy;
end;

procedure TArgumentBase.AddChoice(AName, ADescription: ansistring);
begin
  FChoiceList.AddPair(AName, ADescription);
end;

function TArgumentBase.ValueAsInteger: integer;
begin
  Result := StrToInt(FValue);
end;

procedure TArgumentBase.ValidateValue;
var
  ValueInteger: integer;
  Index: integer;
  ArgType, ItemName: ansistring;
begin
  ArgType := 'Option';
  if Self is TArgument then
  begin
    ArgType := 'Argument';
  end;
  ItemName := AnsiQuotedStr(FName, '"');
  case FValidationType of
    avString: begin
      if FValue.Length = 0 then
      begin
        raise EArgumentParserException.Create(ArgType + ' ' + ItemName + ' must have a value');
      end;
    end;
    avChoice: begin
      if not (FChoiceList.Contains(FValue) or FChoiceList.ContainsName(FValue)) then
      begin
        raise EArgumentParserException.Create(ArgType + ' ' + ItemName + ' must be one of the following : {' + ChoiceListText + '} instead of the value: ' + FValue);
      end;
    end;
    avInteger: begin
      if not TryStrToInt(FValue, ValueInteger) then
      begin
        raise EArgumentParserException.Create(ArgType + ' ' + Itemname + ' must be an integer instead of the value: ' + FValue);
      end;
    end;
  end;
end;

{ TOption }

constructor TOption.Create(AName, AShort, ALong, ADescription: ansistring);
begin
  inherited Create(AName, ADescription);
  FShort := GetOptionShort(AShort);
  FLong := GetOptionLong(ALong);
end;

destructor TOption.Destroy;
begin
  inherited Destroy;
end;

function TOption.IsShort: boolean;
begin
  Result := FShort <> SHORT_OPTION_EMPTY;
end;

function TOption.IsLong: boolean;
begin
  Result := not FLong.IsEmpty;
end;

{ TArgument }

function TArgument.GetChoiceListText: ansistring;
var
  List: TStringList;
  AName: ansistring;
  Index: integer;
begin
  List := TStringList.Create;
  for Index := 0 to FChoiceList.Count - 1 do
  begin
    List.Add(FChoiceList.Names[Index]);
  end;
  Result := List.CommaText;
  FreeAndNil(List);
end;

constructor TArgument.Create(AName, ADescription: ansistring; AState: TArgumentState);
begin
  inherited Create(AName, ADescription);
  FState := AState;
end;

destructor TArgument.Destroy;
begin
  inherited Destroy;
end;

{ TArgumentParser }

function TArgumentParser.GetArgumentFromName(AName: ansistring): TArgument;
var
  Index: integer;
begin
  Index := FArgumentIndexMap.Items[AName];
  Result := FArguments.Items[Index];
end;

function TArgumentParser.GetArgumentFromIndex(AIndex: integer): TArgument;
begin
  Result := FArguments.Items[AIndex];
end;

function TArgumentParser.FindOptionShort(AValue: char): TOption;
var
  Option: TOption;
begin
  Result := nil;
  for Option in FOptions.Values do
  begin
    if Option.Short = AValue then
    begin
      Result := Option;
      Exit;
    end;
  end;
end;

function TArgumentParser.FindOptionLong(AValue: ansistring): TOption;
var
  Option: TOption;
begin
  Result := nil;
  for Option in FOptions.Values do
  begin
    if AnsiCompareStr(AValue, Option.Long) = 0 then
    begin
      Result := Option;
      Exit;
    end;
  end;
end;

function TArgumentParser.GetOption(AName: ansistring): TOption;
begin
  Result := FOptions.Items[AName];
end;

procedure TArgumentParser.ShowHelpUsage;
var
  Option: TOption;
  Argument: TArgument;
  SpaceCount, TextCount: integer;
  ArgHolders: ansistring;
  ConsoleSplitter: TConsoleTextSplitter;
  SortedOptions: TStringList;
  Index: integer;
  OptionText, SeperatiorText: ansistring;
begin
  SortedOptions := TStringList.Create;
  BuildSortedOptions(SortedOptions);

  ConsoleSplitter := TConsoleTextSplitter.Create;
  WriteLn(ANSI_BRIGHT_BLUE + 'Usage:');
  Write(ANSI_BRIGHT_MAGENTA + '  ' + Title + ANSI_RESET + ' ');
  for Index := 0 to SortedOptions.Count - 1 do
  begin
    SeperatiorText := '';
    Option := FOptions.Items[SortedOptions.ValueFromIndex[Index]];
    OptionText := '';
    TextCount := 0;
    if Option.IsShort then
    begin
      OptionText := OptionText + ANSI_RESET + '[' + ANSI_GREEN + '-' + Option.Short;
      Inc(TextCount, 3);
      if Option.ValidationType <> avSwitch then
      begin
        OptionText := OptionText + ' ' + ANSI_YELLOW + '<' + Option.HelpParameter + '>';
        Inc(TextCount, 1 + Option.HelpParameter.Length + 2);
      end;
      OptionText := OptionText + ANSI_RESET;
      SeperatiorText := ' | ';
    end;
    if Option.IsLong then
    begin
      OptionText := OptionText + ANSI_RESET + SeperatiorText + ANSI_GREEN + '--' + Option.Long;
      Inc(TextCount, 4 + SeperatiorText.Length + Option.Long.Length);
      if Option.ValidationType <> avSwitch then
      begin
        OptionText := OptionText + '=' + ANSI_YELLOW + '<' + Option.HelpParameter + '>';
        Inc(TextCount, Option.HelpParameter.Length + 2);
      end;
      OptionText := OptionText + ANSI_RESET + ']';
    end;
    ConsoleSplitter.AddWord(OptionText, TextCount);
  end;

  ConsoleSplitter.Render(3 + Title.Length, FLineLength);
  if FArguments.Count > 0 then
  begin
    WriteLn;
    SpaceCount := 3 + Title.Length;
    Write(StringOfChar(' ', SpaceCount));
    for Argument in FArguments do
    begin
      ArgHolders := '[]';
      if (Argument.State = asRequired) then
        ArgHolders := '<>';
      Write(ArgHolders.Chars[0] + ANSI_GREEN + Argument.HelpParameter + ANSI_RESET + ArgHolders.chars[1] + ' ');
    end;
    WriteLn;
  end;
  WriteLn;
  FreeAndNil(ConsoleSplitter);
  FreeAndNil(SortedOptions);
end;

procedure TArgumentParser.ShowHelpDescription;
var
  ConsoleSplitter: TConsoleTextSplitter;
begin
  ConsoleSplitter := TConsoleTextSplitter.Create;
  WriteLn(ANSI_BRIGHT_BLUE + 'Description: ' + ANSI_RESET);
  Write('  ');
  ConsoleSplitter.Text := FDescription;
  ConsoleSplitter.Render(2, FLineLength);
  WriteLn;
  WriteLn;
  FreeAndNil(ConsoleSplitter);
end;

procedure TArgumentParser.ShowHelpOptions;
var
  Option: TOption;
  SpaceCount: integer;
  ConsoleSplitter: TConsoleTextSplitter;
  SortedOptions: TStringList;
  Index: integer;
begin
  SortedOptions := TStringList.Create;
  BuildSortedOptions(SortedOptions);

  ConsoleSplitter := TConsoleTextSplitter.Create;
  WriteLn(ANSI_BRIGHT_BLUE + 'Options:' + ANSI_RESET);
  for Index := 0 to SortedOptions.Count - 1 do
  begin
    Option := FOptions.Items[SortedOptions.ValueFromIndex[Index]];
    SpaceCount := 2;
    Write('  ');
    if Option.IsShort then
    begin
      Write(ANSI_GREEN + '-' + Option.Short + ' ' + ANSI_RESET);
      Inc(SpaceCount, 3);
    end;
    if Option.IsLong then
    begin
      Write(' ' + ANSI_BRIGHT_CYAN + '--' + Option.Long + ANSI_RESET);
      Inc(SpaceCount, 3 + Option.Long.Length);
    end;
    if Option.ValidationType <> avSwitch then
    begin
      Write(' ' + ANSI_YELLOW + '<' + Option.HelpParameter + '>' + ANSI_RESET);
      Inc(SpaceCount, 1 + Option.HelpParameter.Length + 2);
    end;
    Write(StringOfChar(' ', 40 - SpaceCount));
    ConsoleSplitter.Text := Option.FDescription;
    if Option.ChoiceList.Count > 0 then
    begin
      ConsoleSplitter.AddWord('  ' + ANSI_YELLOW + ' {' + Option.ChoiceListText + '} ' + ANSI_RESET, Option.ChoiceListText.Length);
    end;
    ConsoleSplitter.Render(40, FLineLength);
    WriteLn;
  end;
  WriteLn;
  FreeAndNil(ConsoleSplitter);
  FreeAndNil(SortedOptions);

end;

procedure TArgumentParser.ShowHelpArguments;
var
  Argument: TArgument;
  Index: integer;
  ChoiceName: ansistring;
  ConsoleSplitter: TConsoleTextSplitter;
begin
  ConsoleSplitter := TConsoleTextSplitter.Create;
  WriteLn(ANSI_BRIGHT_BLUE + 'Arguments:' + ANSI_RESET);
  for Argument in FArguments do
  begin
    Write('  ' + ANSI_GREEN + Argument.HelpParameter + ANSI_RESET);
    Write(StringOfChar(' ', 38 - Argument.HelpParameter.Length));
    ConsoleSplitter.Text := Argument.Description;
    ConsoleSplitter.Render(40, FLineLength);
    WriteLn;
    if Argument.ChoiceList.Count > 0 then
    begin
      for Index := 0 to Argument.ChoiceList.Count - 1 do
      begin
        ChoiceName := Argument.ChoiceList.Names[Index];
        Write('    ' + ANSI_YELLOW + ChoiceName + ANSI_RESET);
        Write(StringOfChar(' ', 38 - ChoiceName.Length));
        Write(Argument.ChoiceList.ValueFromIndex[Index]);
        WriteLn;
      end;
    end;
  end;
  WriteLn;
  FreeAndNil(ConsoleSplitter);
end;

function TArgumentParser.ParseOption(out ArgIndex: integer): boolean;
var
  Value: ansistring;
  Short: char;
  Long, LongValue: ansistring;
  Option: TOption;
begin
  Result := False;
  Value := ParamStr(ArgIndex);
  Short := GetOptionShort(Value);
  if Short <> SHORT_OPTION_EMPTY then
  begin
    Option := FindOptionShort(Short);
    if not Assigned(Option) then
    begin
      raise EArgumentParserException.Create('Cannot find option ' + Value);
    end;
    Result := True;
    Option.IsValue := True;
    if Option.ValidationType <> avSwitch then
    begin
      Inc(ArgIndex);
      if ArgIndex > ParamCount then
      begin
        raise EArgumentParserException.Create('Cannot find option for value: ' + Value);
      end;
      Option.Value := ParamStr(ArgIndex);
    end;
  end;
  Long := GetOptionLong(Value);
  if not Long.IsEmpty then
  begin
    Option := FindOptionLong(Long);
    if not Assigned(Option) then
    begin
      raise EArgumentParserException.Create('Cannot find option for value: ' + Value);
    end;
    Result := True;
    Option.IsValue := True;
    if Option.ValidationType <> avSwitch then
    begin
      LongValue := GetOptionLongValue(Value);
      if LongValue.IsEmpty then
      begin
        raise EArgumentParserException.Create('Option ' + Option.Name + ' needs a valid parameter ' + Long);
      end;
      Option.Value := LongValue;
    end;
  end;
end;

procedure TArgumentParser.BuildSortedOptions(AList: TStringList);
var
  Option: TOption;
  KeyValue: ansistring;
begin
  for Option in FOptions.Values do
  begin
    KeyValue := Format('-%s--%s', [Option.Short, Option.Long]);
    if not Option.IsShort then
    begin
      KeyValue := Format('--%s', [Option.Short, Option.Long]);
    end;
    AList.AddPair(KeyValue, Option.Name);
  end;
  AList.Sort;
end;

procedure TArgumentParser.SortChoiceLists;
var
  Option: TOption;
  Argument: TArgument;
begin
  for Option in FOptions.Values do
  begin
    Option.ChoiceList.Sort;
  end;
  for Argument in FArguments do
  begin
    Argument.ChoiceList.Sort;
  end;
end;

constructor TArgumentParser.Create;
begin
  FOptions := TOptionMap.Create([doOwnsValues]);
  FArguments := TArgumentList.Create(True);
  FLineLength := ARGUMENT_PARSER_DEFAULT_LINE_LENGTH;
  FArgumentIndexMap := TArgumentIndexMap.Create;
end;

destructor TArgumentParser.Destroy;
begin
  FreeAndNil(FOptions);
  FreeAndNil(FArguments);
  FreeAndNil(FArgumentIndexMap);
  inherited Destroy;
end;

function TArgumentParser.AddOption(AName, Short, Long, ADescription, HelpParameter: ansistring; AValidationType: TArgumentValidationType): TOption;
var
  Option: TOption;
begin
  Option := TOption.Create(AName, Short, Long, ADescription);
  Option.ValidationType := AValidationType;
  Option.HelpParameter := HelpParameter;
  if Option.IsShort then
  begin
    if Assigned(FindOptionShort(Option.Short)) then
    begin
      raise EArgumentParserException.Create('Duplicate short option for ' + AName + ' ' + Short);
    end;
  end;
  if Option.IsLong then
  begin
    if Assigned(FindOptionLong(Option.Long)) then
    begin
      raise EArgumentParserException.Create('Duplicate long option for ' + AName + ' ' + Long);
    end;
  end;
  FOptions.Add(AName, Option);
  Result := Option;
end;

function TArgumentParser.AddArgument(AName, ADescription, HelpParameter: ansistring; AState: TArgumentState; AValidationType: TArgumentValidationType): TArgument;
var
  Argument: TArgument;
begin
  Argument := TArgument.Create(AName, ADescription, AState);
  Argument.State := AState;
  Argument.ValidationType := AValidationType;
  Argument.HelpParameter := HelpParameter;
  FArguments.Add(Argument);
  FArgumentIndexMap.Add(AName, FArguments.Count - 1);
  Result := Argument;
end;

function TArgumentParser.GetOptionValueAsString(AName: ansistring; DefaultValue: ansistring): ansistring;
var
  Option: TOption;
begin
  Result := DefaultValue;
  Option := GetOption(AName);
  if Option.IsValue then
  begin
    Result := Option.Value;
  end;
end;

function TArgumentParser.GetOptionValueAsInteger(AName: ansistring; DefaultValue: integer): integer;
var
  Option: TOption;
begin
  Result := DefaultValue;
  Option := GetOption(AName);
  if Option.IsValue then  Result := StrToInt(Option.Value);
end;

function TArgumentParser.GetArgumentValueAsString(AName: ansistring; DefaultValue: ansistring): ansistring;
var
  Argument: TArgument;
begin
  Result := DefaultValue;
  Argument := GetArgumentFromName(AName);
  if Argument.IsValue then Result := Argument.Value;
end;

procedure TArgumentParser.Parse;
var
  Index, ArgumentIndex: integer;
  Value: ansistring;
  Argument: TArgument;
begin
  Index := 1;
  ArgumentIndex := 0;
  while Index <= ParamCount do
  begin
    if not ParseOption(Index) then
    begin
      Value := ParamStr(Index);
      if FArguments.Count = 0 then
      begin
        raise EArgumentParserException.Create('Extra argument provided when none are needed: ' + Value);
      end;
      if ArgumentIndex >= FArguments.Count then
      begin
        raise EArgumentParserException.Create('Too many arguments provided: ' + Value);
      end;
      Argument := FArguments.Items[ArgumentIndex];
      Argument.IsValue := True;
      Argument.Value := Value;
      Inc(ArgumentIndex);
    end;
    Inc(Index);
  end;
  SortChoiceLists;
end;

procedure TArgumentParser.Validate;
var
  Option: TOption;
  Argument: TArgument;
begin
  for Option in FOptions.Values do
  begin
    if Option.IsValue then
    begin
      Option.ValidateValue;
    end;
  end;
  for Argument in FArguments do
  begin
    if Argument.IsValue then
    begin
      Argument.ValidateValue;
    end
    else
    begin
      if (Argument.State = asRequired) then
      begin
        raise EArgumentParserException.Create('No values found for argument: ' + AnsiQuotedStr(Argument.Name, '"'));
      end;
    end;
  end;
end;

procedure TArgumentParser.ShowHelp;
begin
  ShowHelpUsage;
  ShowHelpDescription;
  ShowHelpOptions;
  ShowHelpArguments;
end;

function TArgumentParser.IsOption(AName: ansistring): boolean;
var
  Option: TOption;
begin
  Option := GetOption(AName);
  Result := Option.IsValue;
end;

end.
