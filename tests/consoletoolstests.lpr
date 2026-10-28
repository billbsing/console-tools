program ConsoleToolsTests;

{$mode ObjFPC}{$H+}

uses
  Classes, consoletestrunner, TestConsoleTools;

var
  App: TTestRunner;

begin
  DefaultFormat := fPlain;
  DefaultRunAllTests := True;
  App := TTestRunner.Create(nil);
  App.Initialize;
  App.Title := 'ConsoleTools tests';
  App.Run;
  App.Free;
end.
