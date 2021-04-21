# vui
This vim plugin allows you to run complex command line tools and edit their arguments directly from vim.

Some command line tools have many arguments - they can be a hastle to remember and edit. This plugin allows you to edit the arguments in a vim buffer (using some of vim's built in features like autocomplete) and then run the command directly from vim. You can also print the output directly in the vim buffer.

# Configuration
VUI reads from a json file to figure out which command to run, what arguments to display, and what values can be autocompleted
You need to set `g:vui_config_file` in your vim config to let vim know where to find your config. This line in your `.vimrc` would work for example:
``` vim-script
g:vui_config_file = glob('~/vui_config.json')
```
## Example Config
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
## Config Notes
- There are 2 types of args as of now: binary and string
    - Each arg is a string by default (`"type": "binary"` will make it a binary arg).
    - Binary fields don't have a value paired with them. `_enabled_` means it will appear in the final command

# Completion
vui reads from your config to suggest values for autocompletion. It detects the argument in the current line you are editing and suggests only the values for that argument. This is done via vim's user defined comletion (see `:h compl-function`)

- While in insert mode `Ctrl-X Ctrl-U` activates the autocompletion for the command argument of the line are you are on
- `Ctrl-N` moves to the *n*ext match and `Ctrl-P` moves to the *p*revious
- Once you've selected your value you can keep typing or leave insert mode

# Commands
## Global Commands
- `:VUI <vui_config_name>`
    - This is the entrypoint to VUI
    - Running this will open a VUI buffer for the specified tool
    - Tab completion is supported for all your config-defined tools
## VUI Buffer Commands
- `:VUIOutputCommand`
    - Outputs the command generated from the current VUI buffer
- `:VUIExecuteCommand`
    - Generate the command from the buffer and then execute it from vim
- `:VUIExecuteCommandAndReadOuput`
    - Same as `VUIExecuteCommand` but read the output into the vui buffer instead
