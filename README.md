# OSB-file-validator
OSB validator by
	Daniel Quintillán Quintillán
	Jorge Paz Ruza


## INTRODUCTION
The aim of this assignment is to build a program that checks the correctness of an osb file. To gain a better understanding of why this would be a useful tool, we need to know in which context these files appear.
OSU! is a comunity-based rythm videogame where visual cues such as narrowing concentric circles inform the player on when to click them.  
To make the game more appealing or challenging, the user can program animations and sounds to appear at specific moments during the run. These additional components conform the storyboard, which can be programmed in the OSB scripting language. The .osb file is then parsed in real time with few error management features, which often results in run time errors. Our program checks for inconsistencies and errors that may result in crashes, effectively avoiding the poor user experience that comes with the dynamic behaviour of the default implementation.


## FILES AND FOLDERS
The following files and folders are included in this directory:
	- sb folder: Includes the files that the storyboard refers to
	- bg.jpg (Also referenced by the storyboard)
	- Makefile
	- project.l (lexer)
	- project.y (parser)
	- project_example_X.osb
The example files and their expected outputs are listed below.
- project_example_1.osb : Timestamp warnings (the timestamps of the commands are not in ascending order.)
- project_example_2.osb : Invalid easing value (The first argument of the SCALE command is out of range)
- project_example_3.osb : Asset error (the sprite object references a non-existent file)
- project_example_4.osb : Frame count out of range(animations play for at least one frame)
- project_example_5.osb : Missing prolog (a prolog is required)
- project_example_6.osb : Incorrect object declaration(the first FADE command should be indented)
- project_example_7.osb : Unrecognised token (Z doesn't belong to any token)
- project_example_8.osb : Incorrect number format (A comma was not expected after the last INT. The command should be shorter.)
- project_example_9.osb : Incorrect number format (The last argument of the SCALE command must be an INT.)
- project_example_10.osb: Asset error (file format not supported.)
- project_example_11.osb: Valid (storyboards with no images are allowed)
- project_example_12.osb: Comments are disallowed in command lists
- project_example_13.osb: Incorrect object declaration(only one object declaration or command is allowed per line)
- project_example_14.osb: Spaces are only allowed for indentation
- project_example_15.osb: This command is not well formed(bad indentation)
- project_example_16.osb: Unrecognised token (Loopforever is mispelled)
- project_example_17.osb: Opacity out of range (the opacity argument of the FADE command cannot be negative)
- project_example_18.osb: This command is not well formed(the last argument of the PARAMETER command must be a single character, namely either H,V or A)
- project_example_19.osb: Incorrect volume format (the volume in the sample declaration must be an INT.)


## COMPILATION AND EXECUTION INSTRUCTIONS
Given that the user is in this folder, the following commands are available:
- make
- make run 
- make compile
- ./project FILENAME [0|1] the binary flag indicates whether warnings shall be printed or not (hidden by default)


## LEXING AND PARSING
Regarding lexing and parsing, each of the components performs its expected tasks.  

The OSB scripting language is somewhat primitive in terms of flexibility, which leads to an extensive but extremely rigid lexis and gramatic. Therefore, lexical errors conform an important feature in our validator.
Most of the tokens' lexing is straightforward, as they're reserved words ("F", "LoopOnce", "Sprite",...) which aren't really worthy to talk about; the lexer's complexity resides in the most problematic feature of the language, both when creating an script and when trying to validate it: indentation.  

The OSB scripting language features python-like indentation, where the "indents" and "dedents" are an indispensable part of the language's gramatic for parsing the script. This poses a challenge to lexing, as we need to detect when indentation changes, and emit INDENT and DEDENT tokens accordingly. For this purpose, we need to keep a depth counter, which lets us compare the last recorded "depth" of the indentation with the one we're detecting right now. This last thing is done by detecting a line-break character followed by any number of whitespaces. However, FLEX can only return one token at a time, which means it's incompatible with parsing possible consecutive INDENT/DEDENT that may appear on the script (valid or not).  

To solve this, we decided to take a workaround approach, where we store all the INDENT/DEDENT tokens in a queue as we detect a change in indentation, only returning a newline token NL at the end of the rule's code (these NL tokens are also specially important since OSB does not allow for multiple operations/declarations on the same line, not even in-line comments). This queue is checked every time the lexer is run to get a new token, handling "pending" INDENT/DEDENT tokens and sending them to the parser before resuming the lexing of the input string. This extra work on the lexer lets us have a much easier time dealing with the rigid gramatic on the parser.  

Other important things to notice on the lexer is the preemptive detection of some errors: outside of filepaths and other than for indentation purposes, whitespaces aren't allowed in the OSB language. Therefore, we can raise an error in the lexer as soon as we detect one that doesn't belong to any of those specific two cases.
Furthermore, any other character that doesn't belong to filepaths, reserved keywords, numbers or other minor features of the language, is also considered a lexical error, as OSB does not allow for any kind of variable declaration.  

Concering the parsing, we have followed a pretty standard approach both with the construction of the grammar and the error managament. We have used the official (but incomplete) specification of the language in order to replicate every feature of the language, to build a fully working validator.  

While most of the language is pretty straightforward, we consider important to address interesting or odd pecularities of the language and its parsing that may be deemed strange without a proper explanation, and which:  

- For forward-compatibility purposes, every OSB files ends with an empty line. This was mandatory in the original specification of the OSB v1.0 language (latest is v14.0) and it is a convention for "OSB creators" to end all files with an empty line, in order for players using older versions of the client to also be able to play the latest released levels of the game.

- Comments are only allowed when between object declarations, which also means no indentation is allowed on a line with comments. Also, no in-line comments are allowed. This was also a intended feature since OSB v1.0 and is intended to preserve the "one line = one command/declaration" nature of the language.

- Just as no in-line comments are allowed, and as we mentioned earlier when discussing the lexing, every line has one and only one command or declaration. Not even extra whitespaces are allowed in the line. No need to be said, this is also a part of the actual specification of the language.

- While the "prolog"/"header" is mandatory, an storyboard can be completely empty, as in having no object+command declarations, and it's actually a pretty common case. Many levels due not require an additional storyboards but nonetheless include an "empty" OSB in the folder as it's required by the built-in anticheat software to check for file integrity when playing a level.

- Most commands have what is called "shorthand" forms, that is, an abbreviation of their complete structure when some of the parameters are not necessary or redundant.
 
      Per Example, the following "FADE" command:
        
        F,0,200,200,0.5,0.5
        
      can be put in various shorthand forms:
      
        · F,0,200,200,0.5
        . F,0,200,,0.5
        · F,0,200,,0.5,0.5
        
       our parser accepts all of them while still detecting any possible incorrect or invalid syntatic forms of each command.
       

## ERROR MANAGEMENT
Given the few dynamic error management already implemented in OSU!, a distinction must be made betweeen crash-inducing errors and warnings. The only example of a warning is the timestamp order. The commands within an object should be declared in ascending order by starting time. However, the program will not crash if it encounters commands with the wrong timestamp, it will just ignore them. So the validator was configure to report this as a warning (if the warning flag is properly set) and continue the analysis instead of finishing it.
The rest of the inconsistencies are treated as errors and were addressed in three major groups: Range checking,file checking and syntax checking.  
Multiple commands and object declarations require their arguments to be bounded to specific intervals, so they have to be checked in their associated semantic rules.  
Regarding file checking, the validator not only tries to open the referenced files, but also checks their extension to further ensure that the game does not crash due to file errors in the storyboard.  
Lastly, all possible syntax errors regarding commands(missing or unnecessarry arguments,bad indentation,inline comments,multiple commands in one line) are encapsulated into a generic "Malformed command" error. This way, when the parser reaches the level of the object list, it assumes that the only possible error at that level must be an incorrect object declaration.


## GRAMMAR DETAILS
An incomplete specification of the OSB scripting language is available at the following links:

- [Forum](https://osu.ppy.sh/community/forums/topics/1869)
- [Objects](https://osu.ppy.sh/wiki/en/Storyboard_Scripting/Objects)
- [Commands](https://osu.ppy.sh/wiki/en/Storyboard_Scripting/Commands)

Regarding implementation, we worked on a compact yet flexible grammar, so several intermediate non-terminals were introduced. For example, the separation between command_list and command_list_1 avoids unnecessary repetition of the indent and dedent tokens, while common_params improves readability of the lengthy command non-terminal.

It is also worth noting that the character "V" can be both a command name or a parameter. Since this distinction can only be resolved in the parser, the lexer treats both cases as a V_TOKEN. 
