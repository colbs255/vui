# vui
vui (**v**im **u**ser **i**nterface) is a vim plugin that serves as a lightweight frontend to your command line tools by allowing you to quickly edit arguments and execute the commands directly from vim

Some command line tools have many arguments and are a hastle to remember and edit. vui allows you to quickly select the command line tool you want, edit the arguments in a vim buffer using vim completion, and then run the command directly from vim. vui can also print the results directly into the vim buffer and save them to a file.

# Installation
- Requires vim 8
- Can install with any plugin manager
- Can also manually install via vim 8's package system
``` shell
git clone https://github.com/colbs255/vui ~/.vim/pack/plugins/start/vui
```


# Configuration
vui reads from a json file to figure out which command to run, what arguments to display, and what values can be completed.

Set `g:vui_config_file` in your vim config to let vim know where to find your config. This line in your `.vimrc` would work for example:
``` vim-script
g:vui_config_file = '~/vui_config.json'
```

If the config variable is not set then vui will attempt to use `~/.vim/vui.json`
## Example Configuration
``` json
{
    "Tool1-Name": {
        "description": "Description for tool 1",
        "command": "java -jar ~/Tool1.jar",
        "args-order": ["arg1", "arg2", "arg3"],
        "args": {
            "arg1": {
                "type": "string",
                "values": ["www.google.com", "www.bing.com", "www.yahoo.com"],
                "default": "www.yahoo.com"
            },
            "arg2": {
                "type": "string",
                "values": ["2020-04-01"]
            },
            "arg3": {
                "type": "boolean",
                "default": "_enabled_"
            }
        }
    },
    "StockCLI": {
        "description": "Look up statistics for stocks",
        "command": "python  ~/StockCLI.py",
        "args-order": ["exchange", "ticker", "date", "statistic"],
        "args": {
            "exchange": {
                "values": ["NYSE", "NASDAQ", "JPX", "XLON"],
                "default": "NYSE"
            },
            "ticker": {
                "values": ["AAPL", "PLTR"],
                "default": "AAPL"
            },
            "date": {
                "values": ["2020-04-01"]
            },
            "statistic": {
                "values": ["High", "Low", "Avg", "Volume"]
            }
        }
    }
}
```
## Configuration Format
- Configure vui via a json file with each key being the name of the tool and the value containing information about the tool:
    - `description`: quick discription of tool that is displayed on vui page
    - `command`: the command to run
    - `args-order`: list of args indicating the order in which they will be displayed in the vui buffer
    - `args`: the display information for each arg of the tool
- There are 2 types of arguments: binary and string
    - String is just a basic argument with no special logic, if the type is not specified then the arg will be treated as a string
    - Binary args don't have a value paired with them - they are just on or off. `_enabled_` means it will appear in the final command
        - `"type": "binary"` will make it a binary arg.
- For each arg, specify the values used for completion via a list in `values` and a default value with `default`
    - If no default is specified then `_disabled_` will be used

# Completion
vui reads from the config to suggest values for completion. It detects the argument in the current line and suggests only the values for that argument.
- See the mappings section for how to activate argument completion
- `Ctrl-N` moves to the **n**ext match and `Ctrl-P` moves to the **p**revious
    - `Tab` and `Shift-Tab` can also be used
- The completion menu will always have `_disabled_` as an option. This means the arg won't appear in the command output
## File Completion
You can press `Ctrl-X Ctrl-F` while in insert mode for file completion

# Commands
## Global Commands
- `:VUI <vui_config_name>`
    - This is the entrypoint to vui
    - Running this will open a vui buffer for the specified tool
    - Tab completion is supported for all the config-defined tools
## VUI Buffer Commands
- `:VUIOutputCommand`
    - Outputs the command generated from the current vui buffer
- `:VUIExecuteCommand`
    - Generate the command from the buffer and then execute it from vim
- `:VUIExecuteCommandAndReadOuput`
    - Same as `VUIExecuteCommand` but read the output into the vui buffer instead
- `:VUISaveResults`
    - Save the results in the current vui buffer into a user-specified file

# Mappings
Each mapping can be overridden with the corresponding `<Plug>` mapping. For example, `nmap <CR> <Plug>(vui-execute-command)` would run `VUIExecuteCommand` when enter is pressed.
## Normal Mode
- `<localleader>enter`
    - Delete the arg value in the current line, go into insert mode and activate autocomplete - useful for quick changes
    - `<Plug>(vui-change-arg-for-line)`
- `<localleader>c`
    - Same as `<Plug>(vui-change-arg-for-line)` but don't activate autocomplete
    - `<Plug>(vui-clear-arg-for-line)`
- `<localleader>t`
    - Toggle the arg value in the current line. Enabled will switch to disabled and vice versa
    - `<Plug>(vui-toggle-arg)`
- `<localleader>o`
    - Same as `:VUIOutputCommand`
    - `<Plug>(vui-output-command)`
- `<localleader>e`
    - Same as `:VUIExecuteCommand`
    - `<Plug>(vui-execute-command)`
- `<localleader>r`
    - Same as `:VUIExecuteCommandAndReadOuput`
    - `<Plug>(vui-execute-command-and-read)`
- `<localleader>s`
    - Same as `:VUISaveResults`
    - `<Plug>(vui-save-results)`
## Insert Mode
- `F5`
    - Activate autocomplete for the current line
