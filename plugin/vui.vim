if exists("g:loaded_vui")
  finish
endif

if v:version < 800
    echoerr 'Vim 8 required for vui'
    finish
endif
let g:loaded_vui = 1

"""""""""""""""""""""""""""""""""""""""""""
" Section: Constants
"""""""""""""""""""""""""""""""""""""""""""
let g:vui_config_file = get(g:, 'vui_config_file', '~/.vim/vui.json')
let s:disabled_keyword = '_disabled_'
let s:enabled_keyword = '_enabled_'
let s:arg_only_pattern = '\v^:(\S+):'
let s:arg_and_value_pattern = s:arg_only_pattern . '\s+(.*)\s*$'
let s:range_and_expression_pattern = '\v\s*\((.*)\)\s+-\>\s+(.*)\s*'
let s:results_title = '=Results='
let s:args_title = '=Args='

"""""""""""""""""""""""""""""""""""""""""""
" Section: Utils
"""""""""""""""""""""""""""""""""""""""""""
function s:AppendLast(text)
    call append(line('$'), a:text)
endfunction

" Return list with first elem being p-name and second being p-value
" If match not successful then empty list returned
" If value not found then only list with arg name returned
function s:GetArgProperyFromLine()
    let line = getline('.')
    let arg_only_match = matchlist(line, s:arg_only_pattern)
    if empty(arg_only_match)
        return []
    endif
    let arg_name = arg_only_match[1]
    let match_list = matchlist(line, s:arg_and_value_pattern)
    if len(match_list) < 3
        return [arg_name]
    endif
    let arg_value = match_list[2]
    return [arg_name, arg_value]
endfunction

function s:SaveResultsToFile(file_name)
    if search('^' . s:results_title, 'w')
        execute '.,$write! ' . a:file_name
    endif
endfunction

function s:GetConfigForTool(tool, file)
    let raw_config = s:LoadVUIConfig(a:file)
    let config_for_tool = get(raw_config, a:tool, {})
    let config_for_tool['args-map'] = s:CreateArgsMap(config_for_tool)
    call s:LoadArgCompletionsFromFilesIntoConfig(config_for_tool)
    return config_for_tool
endfunction

function s:LoadVUIConfig(file)
    let file_text = join(s:GetLinesFromFile(a:file))
    return json_decode(file_text)
endfunction

function s:CreateArgsMap(config)
    let args_map = {}
    let args_list = get(a:config, 'args', [])
    for arg_entry in args_list
        let arg_name = get(arg_entry, 'name', '')
        if empty(arg_name)
            echoerr 'Arg entry in config is missing a name attribute'
        endif
        let args_map[arg_name] = arg_entry
    endfor

    return args_map
endfunction

" Load arg completions from files specified in the config
" Replaces the file name in config with list of args
function s:LoadArgCompletionsFromFilesIntoConfig(config)
    for arg_info in a:config['args']
        let values = get(arg_info, 'values', [])
        if type(values) == v:t_string && !s:IsRangeAndExpression(values)
            let arg_info['values'] = s:GetLinesFromFile(values)
        endif
    endfor
endfunction

function s:GetLinesFromFile(file)
    return readfile(glob(a:file))
endfunction

function s:GetInfoForArg(arg_name)
    let args = get(b:current_vui_config, 'args-map', {})
    return get(args, a:arg_name, {})
endfunction

function s:FormatArgNameForBuffer(arg_name)
    return ':' . a:arg_name . ':'
endfunction

function s:IsPrefix(str, prefix)
    return stridx(a:str, a:prefix) == 0
endfunction

" Checks if current line is argument line
" Useful for mappings, user can change key functionality based on what
" line they are on
function VUIIsArgLine()
    return !empty(s:GetArgProperyFromLine())
endfunction

function s:IsRangeAndExpression(expression)
    return len(matchlist(a:expression, s:range_and_expression_pattern)) >= 3
endfunction

function s:EvalArgValueGenerator(expression)
    " Example: '(0,5,1) -> strftime("%Y-%m-%d", localtime() - v:val*24*60*60)'
    let inner_number_regex = '\s*(-?\d+)\s*'
    let range_splitter_regex = '\v'
                \ . inner_number_regex . ',' . inner_number_regex . ',' . inner_number_regex

    let main_match = matchlist(a:expression, s:range_and_expression_pattern)
    if !s:IsRangeAndExpression(a:expression)
        echoerr "Invalid generator expression '" . a:expression . "'. Should be in format: '(start, end, step) -> expression'"
        return []
    endif

    let [range_secion, user_expression] = main_match[1:2]
    let range_split = matchlist(range_secion, range_splitter_regex)
    if len(range_split) < 4
        echoerr 'Must specify range in format (start, end, step)'
        return []
    endif
    let range = {'start': range_split[1], 'end': range_split[2], 'step': range_split[3]}

    return s:EvalLoop(range, user_expression, 'v:val')
endfunction

function s:EvalLoop(range, expression, placeholder)
    let parameterized_expr = substitute(a:expression, '\C' . a:placeholder, '_vui_eval_index', 'g')
    let _vui_eval_index = a:range['start']
    let result = []
    while (a:range['step'] > 0 && _vui_eval_index < a:range['end'])
                \ || (a:range['step'] < 0 && _vui_eval_index > a:range['end'])
        call add(result, eval(parameterized_expr))
        let _vui_eval_index += a:range['step']
    endwhile
    return result
endfunction

function s:ParseArgsFromFormattedString(str, parse_config)
    let result = {}
    for [name, regex] in items(a:parse_config)
        let matches = matchlist(a:str, '\v' . regex)
        if len(matches) > 1
            " add the user defined submatch
            let result[name] = matches[1]
        endif
    endfor
    return result
endfunction

function s:IsSubstring(candidate, pattern)
    return stridx(a:candidate, a:pattern) != -1
endfunction

"""""""""""""""""""""""""""""""""""""""""""
" Section: Create Buffer
"""""""""""""""""""""""""""""""""""""""""""
function s:PrintVUIBuffer(vui_name, vui_config)
    %delete
    call s:PrintVUIBufferHeader(a:vui_name, a:vui_config)
    call s:PrintVUIBufferArgs(a:vui_config)
    call s:AppendLast(['', s:results_title])
endfunction

function s:PrintVUIBufferHeader(vui_name, vui_config)
    let config_name = a:vui_name != "" ? a:vui_name : "No name defined"
    let title = '=' . config_name . '='
    let description = 'Description: ' . get(a:vui_config, 'description', 'No description defined')
    let help_line = "Help: '<localleader>h' for list of commands"
    let header_lines = [description, help_line, '']
    call append(line('^'), title)
    call s:AppendLast(header_lines)
endfunction

function s:PrintVUIBufferArgs(vui_config)
    if !has_key(a:vui_config, 'args-map')
        call s:AppendLast('No args defined')
        return
    endif

    call s:AppendLast(s:args_title)
    for arg_node in a:vui_config['args']
        if !has_key(arg_node, 'name')
            echoerr 'No name defined in config for arg'
            break
        endif
        let arg_value = get(arg_node, 'default', s:disabled_keyword)
        call s:AppendLast(s:FormatArgNameForBuffer(arg_node['name']) . ' '  . arg_value)
    endfor
endfunction

"""""""""""""""""""""""""""""""""""""""""""
" Section: Edit Buffer
"""""""""""""""""""""""""""""""""""""""""""
func s:AutoCompleteHandler()
    let line = getline('.')
    let start = col('.') - 1
    while start > 0 && line[start - 1] =~ '\S'
        let start -= 1
    endwhile
    let arg_pair = s:GetArgProperyFromLine()
    if empty(arg_pair)
        return ''
    endif

    let arg_node = s:GetInfoForArg(arg_pair[0])
    if empty(arg_node)
        return ''
    endif

    let arg_type = get(arg_node, 'type', 'string')
    let result = []
    if arg_type ==? 'boolean'
        call add(result, s:enabled_keyword)
    else
        let config_values = get(arg_node, 'values', [])
        if type(config_values) == v:t_string
            " user entered an expression instead of list
            let config_values = s:EvalArgValueGenerator(config_values)
        endif
        let base_str = strpart(line, start, col('.') - start)

        for elem in config_values
            if s:IsSubstring(elem, base_str)
                call add(result, elem)
            endif
        endfor
    endif

    call add(result, s:disabled_keyword)
    call complete(start + 1, result)
    return ''
endfunc

function s:ClearArgValueForLine()
    let pair = s:GetArgProperyFromLine()
    if !empty(pair)
        call setline(line('.'), s:FormatArgNameForBuffer(pair[0]) . ' ')
        startinsert!
        " equivalent to A in normal mode
    endif
endfunction

function s:ToggleArgForLine()
    let pair = s:GetArgProperyFromLine()
    let new_value = ''
    if empty(pair)
        return
    elseif len(pair) == 1
        let new_value = s:disabled_keyword
    else
        " check if binary
        let arg_node = s:GetInfoForArg(pair[0])
        let current_value = pair[1]
        let type = get(arg_node, 'type', 'string')
        if type ==? 'boolean'
            let new_value = current_value ==# s:disabled_keyword ? s:enabled_keyword : s:disabled_keyword
        else
            let new_value = current_value ==# s:disabled_keyword ? "" : s:disabled_keyword
        endif
    endif
    call setline(line('.'), s:FormatArgNameForBuffer(pair[0]) . ' ' . new_value)
endfunction

function s:UpdateArgs(args_dict)
    for [name, value] in items(a:args_dict)
        call cursor(1,1)
        if search(s:FormatArgNameForBuffer(name))
            call setline(line('.'), s:FormatArgNameForBuffer(name) . ' ' . value)
        elseif
            echoerr 'Could not find ' . name . ' check config'
        endif
    endfor
endfunction

"""""""""""""""""""""""""""""""""""""""""""
" Section: Parse Buffer
"""""""""""""""""""""""""""""""""""""""""""
function s:GetCommand()
    return  s:GenerateCommand(b:current_vui_config)
endfunction

function s:GenerateCommand(vui_config)
    let components = [a:vui_config['command']]
    let prefix = "--"
    let config_args = a:vui_config['args-map']
    let args_list = s:ParseVUIBufferArgs(a:vui_config)

    for [name, value] in args_list
        if !has_key(config_args, name)
            echoerr 'No config defined for ' . name
            continue
        endif

        let arg_node = config_args[name]
        let arg_type = get(arg_node, 'type', 'string')

        if arg_type ==? 'boolean'
            if value ==# s:enabled_keyword
                call add(components, prefix . name)
            endif
        elseif arg_type ==? 'string'
            if value != s:disabled_keyword
                call add(components, prefix . name . ' ' . value)
            endif
        else
            echoerr 'Invalid type in config for ' . name . ' defaulting to string'
            call add(components, prefix . name . ' ' . value)
        endif
    endfor

    return join(components, " ")    
endfunction

function s:ParseVUIBufferArgs(vui_config)
    let args_list = []
    " use search to go through buffer for matches
    call cursor(1,1)
    while search(s:arg_and_value_pattern, 'W')
        let arg_pair = s:GetArgProperyFromLine()
        call add(args_list, [arg_pair[0], arg_pair[1]])
    endwhile
    return args_list
endfunction

"""""""""""""""""""""""""""""""""""""""""""
" Section: Commands
"""""""""""""""""""""""""""""""""""""""""""
function VUIOutputCommand()
    echom s:GetCommand()
endfunction

function VUIExecuteCommand()
    let command = s:GetCommand()
    echom 'Executing command: ' . command
    execute '! echo ' command . ';' . command
endfunction

function VUIExecuteCommandAndReadOuput()
    let command = s:GetCommand()
    echom 'Executing command: ' . command
    call s:AppendLast('*Command* ' . command)
    call cursor('$', 1)    
    execute 'read !' . command
    call s:AppendLast('')
endfunction

function VUISaveResults()
    let file_name = input('Enter file name: ', '', 'file')
    call s:SaveResultsToFile(file_name)
endfunction

function VUIParseArgsFromString()
    if !has_key(b:current_vui_config, 'parser')
        echoerr 'No parser config defined'
        return
    endif
    let str_to_parse = input('Enter string to parse args from: ')
    let parsed_args = s:ParseArgsFromFormattedString(str_to_parse, b:current_vui_config['parser'])
    call s:UpdateArgs(parsed_args)
endfunction

"""""""""""""""""""""""""""""""""""""""""""
" Section: Mappings
"""""""""""""""""""""""""""""""""""""""""""
noremap <Plug>(vui-output-command) :call VUIOutputCommand()<CR>
noremap <Plug>(vui-execute-command) :call VUIExecuteCommand()<CR>
noremap <Plug>(vui-execute-command-and-read) :call VUIExecuteCommandAndReadOuput()<CR>
noremap <Plug>(vui-save-results) :call VUISaveResults()<CR>
noremap <Plug>(vui-parse-args) :call VUIParseArgsFromString()<CR>

noremap <silent> <Plug>(vui-clear-arg-for-line) :call <SID>ClearArgValueForLine()<CR>
noremap <silent> <Plug>(vui-toggle-arg) :call <SID>ToggleArgForLine()<CR>

noremap <Plug>(vui-change-arg-for-line) :call <SID>ClearArgValueForLine()<CR><C-R>=<SID>AutoCompleteHandler()<CR><C-p>
inoremap <Plug>(vui-complete) <C-R>=<SID>AutoCompleteHandler()<CR>
noremap <Plug>(vui-help) :h vui-maps<CR>

"""""""""""""""""""""""""""""""""""""""""""
" Section: Entry Point
"""""""""""""""""""""""""""""""""""""""""""
command -complete=customlist,<SID>GetVUIsCompletionFunction  -nargs=1 VUI call s:OpenVUI(<f-args>)

function s:GetVUIsCompletionFunction(ArgLead, CmdLine, CursoPos)
    let vui_dict = s:LoadVUIConfig(g:vui_config_file)
    let result = []
    for k in keys(vui_dict)
        if s:IsPrefix(k, a:ArgLead)
            call add(result, k)
        endif
    endfor
    return result
endfunction

function s:OpenVUI(vui_name)
    execute 'silent edit __' . a:vui_name . '__.vui'
    call s:UpdateVUI(a:vui_name)
    " Position the cursor 1 line below args title
    " so user can quickly start editing the args
    call search('^' . s:args_title, 'w')
    call cursor(line('.') + 1, 1)
endfunction

function s:UpdateVUI(vui_name)
    let b:current_vui_config = s:GetConfigForTool(a:vui_name, g:vui_config_file)
    call s:PrintVUIBuffer(a:vui_name, b:current_vui_config)
endfunction

