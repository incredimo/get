Markdown Installer Specification (v3)The system works by parsing a Markdown file, treating text as narration and executing annotated code blocks. This version uses info string attributes for metadata, enabling powerful conditional flows.1. Standard Markdown as NarrationThis feature remains unchanged. Headings, paragraphs, and other text elements are printed to the console during execution to narrate the process, making the file a self-documenting script.2. Annotated Code BlocksAll execution logic is defined in standard fenced code blocks. Metadata is provided in the "info string" section, within curly braces {}.

~~~markdown
# This is an installation script
this can be de description of the process itself
```language {attribute="value" flag=true}


```
~~~


# code to be executed
3. Core Attributesos (optional): A list of operating systems where the block should run. Valid values are "windows", "linux", and "macos". If omitted, the block runs on the default OS for the language (powershell -> windows, bash/sh -> linux, macos).sudo (optional): A boolean (true/false). If true, the command is executed with elevated privileges.continue_on_error (optional): A boolean (true/false). If true, the script will continue even if this block fails. Default is false.# This will only run on Linux with sudo, and won't stop the script if it fails.
apt-get update
4. Conditional ExecutionThis system enables powerful, readable conditional logic.The ask blockA special language, ask, prompts the user and saves the result to a variable. It does not execute any code itself.prompt: The question to ask the user.name: The variable name to store the true (yes) or false (no) answer.```ask {prompt="Would you like to install Visual Studio Code?", name="install_vscode"}
The if attributeAny executable block can use the if attribute to make its execution conditional on a variable defined by an ask block.if: The name of the boolean variable to check. The block only runs if the variable is true. To check for false, prefix the variable name with an exclamation mark (!).```powershell {if="install_vscode"}
# This block only runs if the user answered 'yes' to the 'install_vscode' prompt.
Write-Host "Installing Visual Studio Code..."
# ... commands to install vscode ...
```

```powershell {if="!install_vscode"}
# This block runs if the user answered 'no'.
Write-Host "Skipping VS Code installation."
This refined structure makes the installation documents extremely readable, flexible, and powerful, turning a simple README.md into a sophisticated, cross-platform installer.