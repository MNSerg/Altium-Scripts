{ ScriptBoot.inc — DO NOT {$I} this file into multiple units.                  }
{ Altium .PrjScr compiles all listed .pas into one namespace. {$I} pastes      }
{ source, so any procedure/var here would be redeclared once per including     }
{ file (Identifier redeclared: R, CS_ScriptFolder, Start, ...).                }
{                                                                              }
{ Each script inlines its own uniquely prefixed copies:                        }
{   FilCS_ScriptFolder / DxfCS_ScriptFolder / PanCS_ScriptFolder / ...         }
{ Image path: this .PrjScr folder, then images\  (not focused PCB project)     }
{ Do not read EXE command-line args (native AV in DelphiScript).                             }
{ Form must have ImageHelp (TImage) and LabelImageHint (TLabel).               }
{ TImage: only Left/Top/Width/Height — no Stretch/Proportional/Center.         }
