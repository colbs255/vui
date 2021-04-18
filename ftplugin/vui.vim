let s:disabled_keyword = '_disabled_'
let s:enabled_keyword = '_enabled_'

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

    return ['red', 'blue', 'green']
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
    let l:pattern = "^\\(\\w\\+\\):\\s\\+\\(.*\\)\\s*$"
    " (word at beginning of line) followed by colon followed by 1 or more whitespace
    " (followed by any characters) excluding trailing whitespace
    while search(l:pattern, 'W')
        let l:line = getline('.')
        let l:match_list = matchlist(l:line, l:pattern)
        let l:arg_name = l:match_list[1]
        let l:arg_value = l:match_list[2]
        let l:args_dict[l:arg_name] = l:arg_value
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
            call add(l:components, l:prefix . k . ' ' . v)
        else
            echo 'Invalid type for ' . k . ' defaulting to string'
            call add(l:components, l:prefix . k . ' ' . v)
        endif
    endfor
    return join(l:components, " ")    
endfunction

function AppendLast(text)
    call append(line('$'), a:text)
endfunction

let g:vui_config = LoadVUIConfig(glob('~/Desktop/CurrentProjects/vui/doc/example.json'))
call PrintVUIBuffer(g:vui_config)
