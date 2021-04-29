if exists("g:loaded_vui")
  finish
endif
let g:loaded_vui = 1

"""""""""""""""""""""""""""""""""""""""""""
" Section: Constants
"""""""""""""""""""""""""""""""""""""""""""
let g:vui_config_file = get(g:, 'vui_config_file', '~/.vim/vui.json')
let s:disabled_keyword = '_disabled_'
let s:enabled_keyword = '_enabled_'
let s:arg_pattern = "^:\\(\\w\\+\\):\\s\\+\\(.*\\)\\s*$"
let s:quick_change_arg_pattern = "^:\\(\\w\\+\\):"
" This is just the arg pattern but only the arg name (no value)
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
    let line = getline('.')
    let match_list = matchlist(line, s:arg_pattern)
    if empty(match_list)
        return []
    endif

    return [match_list[1], match_list[2]]
endfunction

function s:WriteResultsToFile(file_name)
    call cursor(1,1)
    if search('^' . s:results_title, 'W')
        execute '.,$write! ' . a:file_name
    endif
endfunction

function s:LoadVUIConfig(file)
    let file_text = join(readfile(a:file))
    return json_decode(file_text)
endfunction


"""""""""""""""""""""""""""""""""""""""""""
" Section: Create Buffer
"""""""""""""""""""""""""""""""""""""""""""
function s:PrintVUIBuffer(vui_name, vui_config)
    %delete
    call s:PrintVUIBufferHeader(a:vui_name, a:vui_config)
    call s:PrintVUIBufferArgs(a:vui_config)
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
        call s:AppendLast(':' . arg . ': '  . arg_value)
    endfor
    call s:AppendLast(['', s:results_title])
endfunction

"""""""""""""""""""""""""""""""""""""""""""
" Section: Editing Buffer
"""""""""""""""""""""""""""""""""""""""""""
function VUIArgValueCompletion(findstart, base)
    if a:findstart
	    " locate the start of the word
	    let line = getline('.')
	    let start = col('.') - 1
	    while start > 0 && line[start - 1] =~ '\S'
	      let start -= 1
	    endwhile
	    return start
    endif

    let arg_pair = s:GetArgProperyFromLine()
    if empty(arg_pair)
        return []
    endif

    let config_args = get(b:current_vui_config, 'args', [])
    if empty(config_args)
        return []
    endif

    if !has_key(config_args, arg_pair[0])
        return []
    endif

    let arg_node = config_args[arg_pair[0]]
    let arg_type = get(arg_node, 'type', 'string')
    if arg_type == 'boolean'
        return [s:enabled_keyword, s:disabled_keyword]
    endif
    
    let config_values = get(arg_node, 'values', [])
    let result = []
    for elem in config_values
        if elem =~ '^' . a:base
            call add(result, elem)
        endif
    endfor

    return add(result, s:disabled_keyword)
endfunction

function s:ChangeArgValueForLine()
    let line = getline('.')
    let arg = matchstr(line, s:quick_change_arg_pattern)
    if arg != ''
        call setline(line('.'), arg . ' ')
        startinsert!
        " equivalent to A in normal mode
    endif
endfunction

"""""""""""""""""""""""""""""""""""""""""""
" Section: Parse Buffer
"""""""""""""""""""""""""""""""""""""""""""
function s:ParseVUIBufferArgs(vui_config)
    let args_dict = {}
    " use search to go through buffer for matches
    call cursor(1,1)
    " (word at beginning of line) followed by colon followed by 1 or more whitespace
    " (followed by any characters) excluding trailing whitespace
    while search(s:arg_pattern, 'W')
        let arg_pair = s:GetArgProperyFromLine()
        let args_dict[arg_pair[0]] = arg_pair[1]
    endwhile
    return args_dict
endfunction

function s:GetCommand()
    return  s:GenerateCommand(b:current_vui_config)
endfunction

function s:GenerateCommand(vui_config)
    let args_dict = s:ParseVUIBufferArgs(b:current_vui_config)
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
    call s:AppendLast('Command: ' . command)
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
noremap <silent> <Plug>(vui-change-arg-for-line) :call <SID>ChangeArgValueForLine()<CR>

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
