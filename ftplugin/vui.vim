let s:disabled_keyword = '_disabled_'
let s:enabled_keyword = '_enabled_'
let s:arg_pattern = "^\\(\\w\\+\\):\\s\\+\\(.*\\)\\s*$"

"""""""""""""""""""""""""""""""""""""""""""
" Create Buffer
"""""""""""""""""""""""""""""""""""""""""""
function LoadVUIConfig(file)
    let l:file_text = join(readfile(a:file))
    return json_decode(l:file_text)
endfunction

function PrintVUIBuffer(vui_config)
    vnew '__VUI__'
    %delete
    call PrintVUIBufferHeader(a:vui_config)
    call PrintVUIBufferArgs(a:vui_config)
endfunction

function PrintVUIBufferHeader(vui_config)
    let l:config_name = get(a:vui_config, 'name', 'No name defined')
    let l:description = get(a:vui_config, 'description', 'No description defined')
    let l:header_lines = [l:description, '']
    call append(line('^'), l:config_name)
    call AppendLast(l:header_lines)
endfunction

function PrintVUIBufferArgs(vui_config)
    if !has_key(a:vui_config, 'args')
        call AppendLast('No args defined')
        return
    endif

    call AppendLast('=Args=')
    let l:arg_names = get(a:vui_config, 'args-order', keys(a:vui_config['args']))
    for arg in l:arg_names
        if !has_key(a:vui_config['args'], arg)
            echo "No config defined for " . arg
            continue
        endif
        let l:arg_node = a:vui_config['args'][arg]
        let l:arg_value = get(l:arg_node, 'default', s:disabled_keyword)
        call AppendLast(arg . ': '  . l:arg_value)
    endfor
endfunction

"""""""""""""""""""""""""""""""""""""""""""
" Editing Buffer
"""""""""""""""""""""""""""""""""""""""""""
function ArgValueCompletion(findstart, base)
    if a:findstart
        return col('.')
    endif

    let l:arg_pair = GetArgProperyFromLine()
    if empty(l:arg_pair)
        return []
    endif

    let l:config_args = get(s:vui_config, 'args', [])
    if empty(l:config_args)
        return []
    endif

    if !has_key(l:config_args, l:arg_pair[0])
        return []
    endif
    let l:arg_node = l:config_args[l:arg_pair[0]]

    let l:arg_type = get(l:arg_node, 'type', 'string')
    if l:arg_type == 'boolean'
        return [s:enabled_keyword, s:disabled_keyword]
    endif
    
    let l:config_values = get(l:arg_node, 'values', [])
    let l:result = []
    for elem in l:config_values
        " TODO fix
        if elem =~ '^' . a:base
            call add(l:result, elem)
        endif
    endfor

    return add(l:result, s:disabled_keyword)

endfunction

"""""""""""""""""""""""""""""""""""""""""""
" Parse Buffer
"""""""""""""""""""""""""""""""""""""""""""
function OutputCommandFromVUIBuffer(vui_config)
    echom GenerateCommand(ParseVUIBufferArgs(a:vui_config), a:vui_config)
endfunction

function ParseVUIBufferArgs(vui_config)
    let l:args_dict = {}
    " use search to go through buffer for matches
    call cursor(1,1)
    " (word at beginning of line) followed by colon followed by 1 or more whitespace
    " (followed by any characters) excluding trailing whitespace
    while search(s:arg_pattern, 'W')
        let l:arg_pair = GetArgProperyFromLine()
        let l:args_dict[l:arg_pair[0]] = l:arg_pair[1]
    endwhile
    return l:args_dict
endfunction

function GenerateCommand(args_dict, vui_config)
    let l:components = [a:vui_config['command']]
    let l:prefix = "--"
    let l:config_args = a:vui_config['args']
    for [k,v] in items(a:args_dict)
        if !has_key(l:config_args, k)
            echo "No config defined for " . k
            continue
        endif

        let l:arg_node = l:config_args[k]
        let l:arg_type = get(l:arg_node, 'type', 'string')

        if l:arg_type == 'boolean'
            if v == s:enabled_keyword
                call add(l:components, l:prefix . k)
            endif
        elseif l:arg_type == 'string'
            if v != s:disabled_keyword
                call add(l:components, l:prefix . k . ' ' . v)
            endif
        else
            " TODO clean this part up
            echo 'Invalid type for ' . k . ' defaulting to string'
            call add(l:components, l:prefix . k . ' ' . v)
        endif
    endfor
    return join(l:components, " ")    
endfunction

"""""""""""""""""""""""""""""""""""""""""""
" Utils
"""""""""""""""""""""""""""""""""""""""""""
function AppendLast(text)
    call append(line('$'), a:text)
endfunction

function GetArgProperyFromLine()
    " Return list with first elem being p-name and second being p-value
    " If match not successful then empty list returned
    let l:line = getline('.')
    let l:match_list = matchlist(l:line, s:arg_pattern)
    if empty(l:match_list)
        return []
    endif

    return [l:match_list[1], l:match_list[2]]
endfunction

"""""""""""""""""""""""""""""""""""""""""""
" Settings
"""""""""""""""""""""""""""""""""""""""""""
let g:vui_config_file = glob('~/Desktop/CurrentProjects/vui/doc/example.json')
let s:vui_config = LoadVUIConfig(g:vui_config_file)
call PrintVUIBuffer(s:vui_config)
setlocal completefunc=ArgValueCompletion
