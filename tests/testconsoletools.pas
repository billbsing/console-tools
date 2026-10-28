unit TestConsoleTools;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, ConsoleTools;

type

  { TTestArgumentParser }

  // Exposes the protected BuildSortedOptions and DetectColorSupport for testing
  TTestArgumentParser = class(TArgumentParser)
  public
    procedure SortedOptionNames(AList: TStrings);
    function IsColorSupported: boolean;
  end;

  { TParseTest }

  TParseTest = class(TTestCase)
  private
    FParser: TTestArgumentParser;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestNoArgs;
    procedure TestShortSwitch;
    procedure TestLongSwitch;
    procedure TestShortWithValue;
    procedure TestLongWithValue;
    procedure TestPositionalArguments;
    procedure TestOptionalArgumentDefault;
    procedure TestIntegerValue;
  end;

  { TValidationTest }

  TValidationTest = class(TTestCase)
  private
    FParser: TTestArgumentParser;
    procedure ParseAndValidate(const Args: array of string);
    procedure AssertParserError(const Args: array of string; const AMessagePart: string);
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestUnknownShortOption;
    procedure TestUnknownLongOption;
    procedure TestShortOptionMissingValue;
    procedure TestLongOptionMissingValue;
    procedure TestInvalidInteger;
    procedure TestInvalidChoice;
    procedure TestValidChoice;
    procedure TestMissingRequiredArgument;
    procedure TestTooManyArguments;
    procedure TestExtraArgumentWhenNoneNeeded;
    procedure TestDuplicateShortOption;
    procedure TestDuplicateLongOption;
  end;

  { TSortOrderTest }

  TSortOrderTest = class(TTestCase)
  published
    procedure TestLongOnlyOptionsSorted;
    procedure TestMixedOptionsSorted;
  end;

  { TColorTest }

  TColorTest = class(TTestCase)
  private
    FParser: TTestArgumentParser;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestColorDisabled;
    procedure TestColorEnabled;
    procedure TestColorDefaultsToDetected;
    procedure TestColorPerParser;
  end;

implementation

{ TTestArgumentParser }

procedure TTestArgumentParser.SortedOptionNames(AList: TStrings);
var
  Sorted: TStringList;
  Index: integer;
begin
  Sorted := TStringList.Create;
  try
    BuildSortedOptions(Sorted);
    for Index := 0 to Sorted.Count - 1 do
    begin
      AList.Add(Sorted.ValueFromIndex[Index]);
    end;
  finally
    Sorted.Free;
  end;
end;

function TTestArgumentParser.IsColorSupported: boolean;
begin
  Result := DetectColorSupport;
end;

{ TParseTest }

procedure TParseTest.SetUp;
begin
  FParser := TTestArgumentParser.Create;
  FParser.AddOption('verbose', '-v', '--verbose', 'Verbose output', '', avSwitch);
  FParser.AddOption('output', '-o', '--output', 'Output file', 'file');
  FParser.AddOption('count', '-c', '--count', 'Repeat count', 'number', avInteger);
  FParser.AddArgument('source', 'Source file', 'source');
  FParser.AddArgument('target', 'Target file', 'target', asOptional);
end;

procedure TParseTest.TearDown;
begin
  FreeAndNil(FParser);
end;

procedure TParseTest.TestNoArgs;
begin
  FParser.Parse([]);
  AssertFalse(FParser.IsOption('verbose'));
  AssertFalse(FParser.IsOption('output'));
  AssertFalse(FParser.ArgumentNames['source'].IsValue);
end;

procedure TParseTest.TestShortSwitch;
begin
  FParser.Parse(['-v']);
  AssertTrue(FParser.IsOption('verbose'));
  AssertFalse(FParser.IsOption('output'));
end;

procedure TParseTest.TestLongSwitch;
begin
  FParser.Parse(['--verbose']);
  AssertTrue(FParser.IsOption('verbose'));
end;

procedure TParseTest.TestShortWithValue;
begin
  FParser.Parse(['-o', 'out.txt']);
  AssertTrue(FParser.IsOption('output'));
  AssertEquals('out.txt', FParser.GetOptionValueAsString('output'));
end;

procedure TParseTest.TestLongWithValue;
begin
  FParser.Parse(['--output=out.txt']);
  AssertEquals('out.txt', FParser.GetOptionValueAsString('output'));
end;

procedure TParseTest.TestPositionalArguments;
begin
  FParser.Parse(['-v', 'a.txt', '--output=o.txt', 'b.txt']);
  AssertTrue(FParser.IsOption('verbose'));
  AssertEquals('o.txt', FParser.GetOptionValueAsString('output'));
  AssertEquals('a.txt', FParser.GetArgumentValueAsString('source'));
  AssertEquals('b.txt', FParser.GetArgumentValueAsString('target'));
  AssertEquals('a.txt', FParser.Arguments[0].Value);
end;

procedure TParseTest.TestOptionalArgumentDefault;
begin
  FParser.Parse(['a.txt']);
  FParser.Validate;
  AssertEquals('fallback', FParser.GetArgumentValueAsString('target', 'fallback'));
  AssertEquals('default', FParser.GetOptionValueAsString('output', 'default'));
  AssertEquals(7, FParser.GetOptionValueAsInteger('count', 7));
end;

procedure TParseTest.TestIntegerValue;
begin
  FParser.Parse(['--count=42', 'a.txt']);
  FParser.Validate;
  AssertEquals(42, FParser.GetOptionValueAsInteger('count'));
end;

{ TValidationTest }

procedure TValidationTest.SetUp;
var
  Mode: TOption;
begin
  FParser := TTestArgumentParser.Create;
  FParser.AddOption('verbose', '-v', '--verbose', 'Verbose output', '', avSwitch);
  FParser.AddOption('output', '-o', '--output', 'Output file', 'file');
  FParser.AddOption('count', '-c', '--count', 'Repeat count', 'number', avInteger);
  Mode := FParser.AddOption('mode', '-m', '--mode', 'Run mode', 'mode', avChoice);
  Mode.ChoiceListText := 'fast,slow';
  FParser.AddArgument('source', 'Source file', 'source');
end;

procedure TValidationTest.TearDown;
begin
  FreeAndNil(FParser);
end;

procedure TValidationTest.ParseAndValidate(const Args: array of string);
begin
  FParser.Parse(Args);
  FParser.Validate;
end;

procedure TValidationTest.AssertParserError(const Args: array of string; const AMessagePart: string);
begin
  try
    ParseAndValidate(Args);
  except
    on E: EArgumentParserException do
    begin
      AssertTrue('Unexpected message: ' + E.Message, Pos(AMessagePart, E.Message) > 0);
      Exit;
    end;
  end;
  Fail('Expected EArgumentParserException containing: ' + AMessagePart);
end;

procedure TValidationTest.TestUnknownShortOption;
begin
  AssertParserError(['-x', 'a.txt'], 'Cannot find option -x');
end;

procedure TValidationTest.TestUnknownLongOption;
begin
  AssertParserError(['--nope', 'a.txt'], 'Cannot find option for value: --nope');
end;

procedure TValidationTest.TestShortOptionMissingValue;
begin
  AssertParserError(['a.txt', '-o'], 'Cannot find option for value: -o');
end;

procedure TValidationTest.TestLongOptionMissingValue;
begin
  AssertParserError(['--output', 'a.txt'], 'needs a valid parameter');
end;

procedure TValidationTest.TestInvalidInteger;
begin
  AssertParserError(['--count=abc', 'a.txt'], 'must be an integer');
end;

procedure TValidationTest.TestInvalidChoice;
begin
  AssertParserError(['--mode=medium', 'a.txt'], 'must be one of the following');
end;

procedure TValidationTest.TestValidChoice;
begin
  ParseAndValidate(['-m', 'slow', 'a.txt']);
  AssertEquals('slow', FParser.GetOptionValueAsString('mode'));
end;

procedure TValidationTest.TestMissingRequiredArgument;
begin
  AssertParserError(['-v'], 'No values found for argument: "source"');
end;

procedure TValidationTest.TestTooManyArguments;
begin
  AssertParserError(['a.txt', 'b.txt'], 'Too many arguments provided: b.txt');
end;

procedure TValidationTest.TestExtraArgumentWhenNoneNeeded;
var
  Parser: TArgumentParser;
begin
  Parser := TArgumentParser.Create;
  try
    try
      Parser.Parse(['stray']);
      Fail('Expected EArgumentParserException');
    except
      on E: EArgumentParserException do
        AssertTrue(Pos('Extra argument provided', E.Message) > 0);
    end;
  finally
    Parser.Free;
  end;
end;

procedure TValidationTest.TestDuplicateShortOption;
begin
  try
    FParser.AddOption('other', '-v', '--other', 'Clashes on -v', '', avSwitch);
    Fail('Expected EArgumentParserException');
  except
    on E: EArgumentParserException do
      AssertTrue(Pos('Duplicate short option', E.Message) > 0);
  end;
end;

procedure TValidationTest.TestDuplicateLongOption;
begin
  try
    FParser.AddOption('other', '-z', '--verbose', 'Clashes on --verbose', '', avSwitch);
    Fail('Expected EArgumentParserException');
  except
    on E: EArgumentParserException do
      AssertTrue(Pos('Duplicate long option', E.Message) > 0);
  end;
end;

{ TSortOrderTest }

procedure TSortOrderTest.TestLongOnlyOptionsSorted;
var
  Parser: TTestArgumentParser;
  Names: TStringList;
begin
  Parser := TTestArgumentParser.Create;
  Names := TStringList.Create;
  try
    // Before the fix every long-only key was '--'#0, so the sort fell back to the
    // option name; names are chosen so that ordering differs from the long flags
    Parser.AddOption('opt1', '', '--zeta', 'Z', '', avSwitch);
    Parser.AddOption('opt4', '', '--alpha', 'A', '', avSwitch);
    Parser.AddOption('opt2', '', '--mike', 'M', '', avSwitch);
    Parser.AddOption('opt3', '', '--bravo', 'B', '', avSwitch);
    Parser.SortedOptionNames(Names);
    AssertEquals('opt4,opt3,opt2,opt1', Names.CommaText);
  finally
    Names.Free;
    Parser.Free;
  end;
end;

procedure TSortOrderTest.TestMixedOptionsSorted;
var
  Parser: TTestArgumentParser;
  Names: TStringList;
begin
  Parser := TTestArgumentParser.Create;
  Names := TStringList.Create;
  try
    Parser.AddOption('zeta', '', '--zeta', 'Z', '', avSwitch);
    Parser.AddOption('verbose', '-v', '--verbose', 'V', '', avSwitch);
    Parser.AddOption('alpha', '', '--alpha', 'A', '', avSwitch);
    Parser.AddOption('count', '-c', '--count', 'C', 'n', avInteger);
    Parser.SortedOptionNames(Names);
    AssertEquals(4, Names.Count);
    // Long-only options keep their relative alphabetical order among the short ones
    AssertTrue(Names.IndexOf('alpha') < Names.IndexOf('zeta'));
    AssertTrue(Names.IndexOf('count') < Names.IndexOf('verbose'));
  finally
    Names.Free;
    Parser.Free;
  end;
end;

{ TColorTest }

procedure TColorTest.SetUp;
begin
  FParser := TTestArgumentParser.Create;
end;

procedure TColorTest.TearDown;
begin
  FParser.Free;
end;

procedure TColorTest.TestColorDisabled;
begin
  FParser.IsColor := False;
  AssertEquals('', FParser.ColorCode(ANSI_RED));
  AssertEquals('', FParser.ColorCode(ANSI_RESET));
end;

procedure TColorTest.TestColorEnabled;
begin
  FParser.IsColor := True;
  AssertEquals(ANSI_RED, FParser.ColorCode(ANSI_RED));
end;

procedure TColorTest.TestColorDefaultsToDetected;
begin
  AssertEquals(FParser.IsColorSupported, FParser.IsColor);
end;

procedure TColorTest.TestColorPerParser;
var
  Other: TTestArgumentParser;
begin
  Other := TTestArgumentParser.Create;
  try
    FParser.IsColor := True;
    Other.IsColor := False;
    AssertEquals(ANSI_RED, FParser.ColorCode(ANSI_RED));
    AssertEquals('', Other.ColorCode(ANSI_RED));
  finally
    Other.Free;
  end;
end;

initialization
  RegisterTest(TParseTest);
  RegisterTest(TValidationTest);
  RegisterTest(TSortOrderTest);
  RegisterTest(TColorTest);

end.
