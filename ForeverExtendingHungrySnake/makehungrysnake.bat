del hungrysnake.prg
c:\64tass\64tass.exe hungrysnake.asm -ohungrysnake.prg
ifnotexist hungrysnake.prg goto abort
c:\exomizer\win32\exomizer.exe sfx $4800 hungrysnake.prg -o hungrysnake.prg -x1
c:\vice_runtime\x64sc hungrysnake.prg
abort:
