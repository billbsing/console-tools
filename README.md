# console-tools

A small Free Pascal unit (`consoletools.pas`) for writing command-line programs. It handles:

- Parsing short (`-v`, `-c 3`) and long (`--verbose`, `--count=3`) options
- Positional arguments, both required and optional
- Value validation: string, integer, a fixed list of choices, or a plain on/off switch
- Coloured, word-wrapped `--help` output, built from the options you define

## Requirements

Free Pascal 3.2.0 or later. The unit uses `Generics.Collections`, which first shipped with FPC 3.2.0. It is tested with FPC 3.2.2.

## Usage

Add `consoletools.pas` to your project, or put its folder on the unit search path (`-Fu`), and add `ConsoleTools` to your `uses` clause.

```pascal
program copytool;

{$mode ObjFPC}{$H+}

uses
  SysUtils, ConsoleTools;

var
  Parser: TArgumentParser;
  Mode: TOption;
begin
  Parser := TArgumentParser.Create;
  try
    Parser.Title := 'copytool';
    Parser.Description := 'Copy a file, optionally more than once.';
    Parser.AddOption('help', '-h', '--help', 'Show this help', '', avSwitch);
    Parser.AddOption('verbose', '-v', '--verbose', 'Print each step', '', avSwitch);
    Parser.AddOption('count', '-c', '--count', 'Number of copies', 'number', avInteger);
    Mode := Parser.AddOption('mode', '-m', '--mode', 'Copy mode', 'mode', avChoice);
    Mode.ChoiceListText := 'fast,safe';
    Parser.AddArgument('source', 'File to copy', 'source');
    Parser.AddArgument('target', 'Destination file', 'target', asOptional);

    try
      Parser.Parse;
      if Parser.IsOption('help') then
      begin
        Parser.ShowHelp;
        Exit;
      end;
      Parser.Validate;
    except
      on E: EArgumentParserException do
      begin
        WriteLn(E.Message);
        ExitCode := 1;
        Exit;
      end;
    end;

    WriteLn('source:  ', Parser.GetArgumentValueAsString('source'));
    WriteLn('target:  ', Parser.GetArgumentValueAsString('target', 'copy.out'));
    WriteLn('count:   ', Parser.GetOptionValueAsInteger('count', 1));
    WriteLn('mode:    ', Parser.GetOptionValueAsString('mode', 'safe'));
    WriteLn('verbose: ', Parser.IsOption('verbose'));
  finally
    Parser.Free;
  end;
end.
```

Running `copytool --help` prints:

```
Usage:
  copytool [-c <number> | --count=<number>] [-h | --help] [-m <mode> | --mode=<mode>] [-v | --verbose]
           <source> [target]

Description:
  Copy a file, optionally more than once.

Options:
  -c  --count <number>                  Number of copies
  -h  --help                            Show this help
  -m  --mode <mode>                     Copy mode    {fast,safe}
  -v  --verbose                         Print each step

Arguments:
  source                                File to copy
  target                                Destination file
```

Bad input raises `EArgumentParserException` with a readable message:

```
$ copytool --count=x a.txt
Option "count" must be an integer instead of the value: x
$ copytool
No values found for argument: "source"
```

### Defining options and arguments

```pascal
AddOption(Name, Short, Long, Description, HelpParameter, ValidationType = avString)
AddArgument(Name, Description, HelpParameter, State = asRequired, ValidationType = avString)
```

- `Name` is the key you use later to look up the value.
- `Short` and `Long` include their dashes (`'-c'`, `'--count'`). Pass `''` to leave one out.
- `HelpParameter` is the placeholder shown in the help text, such as `<number>`.
- The validation types are `avString`, `avInteger`, `avChoice` and `avSwitch`. A switch takes no value.
- For `avChoice`, set the allowed values with `ChoiceListText := 'a,b,c'`. On arguments you can also use `AddChoice(Name, Description)`, which lists each choice with its description in the help.
- Adding an option whose short or long form is already in use raises `EArgumentParserException`.

### Passing values on the command line

- Short options take their value as the next argument: `-c 3`.
- Long options take their value after `=`: `--count=3`. Writing `--count 3` is an error.
- Options and positional arguments can come in any order. Positional arguments fill in the order they were added.

### Reading results

| Call | Returns |
| --- | --- |
| `IsOption(Name)` | `True` if the option was given |
| `GetOptionValueAsString(Name, Default)` | The option's value, or `Default` if it wasn't given |
| `GetOptionValueAsInteger(Name, Default)` | The same, as an integer |
| `GetArgumentValueAsString(Name, Default)` | The argument's value, or `Default` if it wasn't given |
| `Arguments[Index]`, `ArgumentNames[Name]`, `Options[Name]` | The underlying `TArgument` / `TOption` objects |

`Parse` reads only the command line. `Validate` then checks each value's type and that all required arguments are present. Call `Validate` after `Parse`, and after any `--help` check, so that `--help` works even when other values are missing.

### Parsing a custom argument list

`Parse` with no arguments reads `ParamStr(1..ParamCount)`. To parse a list of your own instead, for example in tests, pass it directly:

```pascal
Parser.Parse(['-v', '--count=3', 'a.txt']);
```

### Colour output

Help output is coloured with ANSI escape codes. Each `TArgumentParser` checks for colour support when it is created, and turns colour off when:

- the `NO_COLOR` environment variable is set to any non-empty value (see [no-color.org](https://no-color.org)), or
- stdout is not a terminal, for example when output is piped or redirected to a file.

To override this, set the parser's `IsColor` property before calling `ShowHelp`:

```pascal
Parser.IsColor := False;
```

The setting belongs to each parser, so two parsers can differ. To colour your own output the same way, wrap the `ANSI_*` codes in the parser's `ColorCode`, which returns an empty string when `IsColor` is off:

```pascal
WriteLn(Parser.ColorCode(ANSI_RED) + 'error' + Parser.ColorCode(ANSI_RESET));
```

## Running the tests

The tests use FPCUnit and live in `tests/`. Build them with Lazarus's `lazbuild`, then run the result:

```
lazbuild tests/consoletoolstests.lpi
tests/consoletoolstests --all --format=plain
```

If more than one FPC is installed, make sure `lazbuild` and `fpc` here are 3.2.0 or later (see [Requirements](#requirements)).

Or compile with `fpc` directly, without Lazarus:

```
mkdir -p tests/lib
fpc -Fu. -FUtests/lib tests/consoletoolstests.lpr
tests/consoletoolstests --all --format=plain
```

To run a single suite, use `--suite=<name>`, for example `--suite=TSortOrderTest`. The suites are `TParseTest`, `TValidationTest`, `TSortOrderTest` and `TColorTest`.

## License

MIT. See [LICENSE](LICENSE).
