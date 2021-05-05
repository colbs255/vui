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
let s:arg_only_pattern = "^:\\(\\w\\+\\):"
let s:arg_and_value_pattern = s:arg_only_pattern . "\\s\\+\\(.*\\)\\s*$"
let s:results_title = '=Results='

"""""""""""""""""""""""""""""""""""""""""""
" Section: Utils
"""""""""""""""""""""""""""""""""""""""""""
function s:AppendLast(text)
    call append(line('$'), a:text)
endfunction

function s:GetArgProperyFromLine()
    " Return list with first elem being p-name and second being p-value
    " If match not successful then empty list returned
    " If value not found then only list with arg name returned
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

function s:WriteResultsToFile(file_name)
    call cursor(1,1)
    if search('^' . s:results_title, 'W')
        execute '.,$write! ' . a:file_name
    endif
endfunction

function s:LoadVUIConfig(file)
    let file_text = join(readfile(glob(a:file)))
    return json_decode(file_text)
endfunction

function s:GetInfoForArg(arg_name)
    let args = get(b:current_vui_config, 'args', {})
    return get(args, a:arg_name, {})
endfunction

function s:FormatArgNameForBuffer(arg_name)
    return ':' . a:arg_name . ':'
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
    let description = get(a:vui_config, 'description', 'No description defined')
    let header_lines = [description, '']
    call append(line('^'), '=' . config_name . '=')
    call s:AppendLast(header_lines)
endfunction

function s:PrintVUIBufferArgs(vui_config)
    if !has_key(a:vui_config, 'args')
        call s:AppendLast('No args defined')
        return
    endif

    call s:AppendLast('=Args=')
    let arg_names = get(a:vui_config, 'args-order', keys(a:vui_config['args']))
    for arg in arg_names
        if !has_key(a:vui_config['args'], arg)
            echom "No config defined for " . arg
            continue
        endif
        let arg_node = a:vui_config['args'][arg]
        let arg_value = get(arg_node, 'default', s:disabled_keyword)
        call s:AppendLast(s:FormatArgNameForBuffer(arg) . ' '  . arg_value)
    endfor
endfunction

"""""""""""""""""""""""""""""""""""""""""""
" Section: Editing Buffer
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
    if arg_type == 'boolean'
        call add(result, s:enabled_keyword)
    else
        let config_values = get(arg_node, 'values', [])
        let base_str = strpart(line, start, col('.') - start)

        for elem in config_values
            if elem =~ '^' . base_str
                call add(result, elem)
            endif
        endfor
    endif

    if empty(result)
        return ''
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
        if type == 'boolean'
            let new_value = current_value == s:disabled_keyword ? s:enabled_keyword : s:disabled_keyword
        else
            let new_value = current_value == s:disabled_keyword ? "" : s:disabled_keyword
        endif
    endif
    call setline(line('.'), s:FormatArgNameForBuffer(pair[0]) . ' ' . new_value)
endfunction

"""""""""""""""""""""""""""""""""""""""""""
" Section: Parse Buffer
"""""""""""""""""""""""""""""""""""""""""""
function s:GetCommand()
    return  s:GenerateCommand(b:current_vui_config)
endfunction

function s:GenerateCommand(vui_config)
    let args_dict = s:ParseVUIBufferArgs(a:vui_config)
    let components = [a:vui_config['command']]
    let prefix = "--"
    let config_args = a:vui_config['args']
    for [k,v] in items(args_dict)
        if !has_key(config_args, k)
            echom "No config defined for " . k
            continue
        endif

        let arg_node = config_args[k]
        let arg_type = get(arg_node, 'type', 'string')

        if arg_type == 'boolean'
            if v == s:enabled_keyword
                call add(components, prefix . k)
            endif
        elseif arg_type == 'string'
            if v != s:disabled_keyword
                call add(components, prefix . k . ' ' . v)
            endif
        else
            echom 'Invalid type for ' . k . ' defaulting to string'
            call add(components, prefix . k . ' ' . v)
        endif
    endfor
    return join(components, " ")    
endfunction

function s:ParseVUIBufferArgs(vui_config)
    let args_dict = {}
    " use search to go through buffer for matches
    call cursor(1,1)
    " (word at beginning of line) followed by colon followed by 1 or more whitespace
    " (followed by any characters) excluding trailing whitespace
    while search(s:arg_and_value_pattern, 'W')
        let arg_pair = s:GetArgProperyFromLine()
        let args_dict[arg_pair[0]] = arg_pair[1]
    endwhile
    return args_dict
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
    execute '!' . command
endfunction

function VUIExecuteCommandAndReadOuput()
    let command = s:GetCommand()
    echom 'Executing command: ' . command
    call s:AppendLast('*Command* ' . command)
    call cursor('$', 1)    
    execute 'read !' . command
    call s:AppendLast('')
endfunction

function VUIWriteResults()
    let file_name = input('Enter file name: ', '', 'file')
    call s:WriteResultsToFile(file_name)
endfunction

"""""""""""""""""""""""""""""""""""""""""""
" Section: Mappings
"""""""""""""""""""""""""""""""""""""""""""
noremap <Plug>(vui-output-command) :call VUIOutputCommand()<CR>
noremap <Plug>(vui-execute-command) :call VUIExecuteCommand()<CR>
noremap <Plug>(vui-execute-command-and-read) :call VUIExecuteCommandAndReadOuput()<CR>
noremap <Plug>(vui-write-results) :call VUIWriteResults()<CR>

noremap <silent> <Plug>(vui-clear-arg-for-line) :call <SID>ClearArgValueForLine()<CR>
noremap <silent> <Plug>(vui-toggle-arg) :call <SID>ToggleArgForLine()<CR>

noremap <Plug>(vui-change-arg-for-line) :call <SID>ClearArgValueForLine()<CR><C-R>=<SID>AutoCompleteHandler()<CR><C-p>
inoremap <Plug>(vui-complete) <C-R>=<SID>AutoCompleteHandler()<CR>

"""""""""""""""""""""""""""""""""""""""""""
" Section: Entry Point
"""""""""""""""""""""""""""""""""""""""""""
command -complete=customlist,<SID>GetVUIsCompletionFunction  -nargs=1 VUI call s:OpenVUI(<f-args>)

function s:GetVUIsCompletionFunction(ArgLead, CmdLine, CursoPos)
    let vui_dict = s:LoadVUIConfig(g:vui_config_file)
    let result = []
    for k in keys(vui_dict)
        if k =~ '^' . a:ArgLead
            call add(result, k)
        endif
    endfor
    return result
endfunction

function s:OpenVUI(vui_name)
    execute 'silent edit __' . a:vui_name . '__.vui'
    call s:UpdateVUI(a:vui_name)
endfunction

function s:UpdateVUI(vui_name)
    let b:current_vui_config = get(s:LoadVUIConfig(g:vui_config_file), a:vui_name, {})
    call s:PrintVUIBuffer(a:vui_name, b:current_vui_config)
endfunction

