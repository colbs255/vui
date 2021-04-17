let s:disabled_keyword = '_disabled_'
let s:enabled_keyword = '_enabled_'

"""""""""""""""""""""""""""""""""""""""""""
" Create Buffer
"""""""""""""""""""""""""""""""""""""""""""
function LoadVUIConfig(file)
    let s:file_text = join(readfile(a:file))
    return json_decode(s:file_text)
endfunction

function PrintVUIBuffer(vui_config)
    vnew '__VUI__'
    %delete
    call PrintVUIBufferHeader(a:vui_config)
    call PrintVUIBufferArgs(a:vui_config)
endfunction

function PrintVUIBufferHeader(vui_config)
    let s:config_name = get(a:vui_config, 'name', 'No name defined')
    let s:description = get(a:vui_config, 'description', 'No description defined')
    let s:header_lines = [s:description, '']
    call append(line('^'), s:config_name)
    call AppendLast(s:header_lines)
endfunction

function PrintVUIBufferArgs(vui_config)
    if !has_key(a:vui_config, 'args')
        call AppendLast('No args defined')
        return
    endif

    call AppendLast('=Args=')
    let s:arg_names = get(a:vui_config, 'args-order', keys(a:vui_config['args']))
    for arg in s:arg_names
        if !has_key(a:vui_config['args'], arg)
            echo "No config defined for " . arg
            continue
        endif
        let s:arg_node = a:vui_config['args'][arg]
        let s:arg_value = get(s:arg_node, 'default', s:disabled_keyword)
        call AppendLast(arg . ': '  . s:arg_value)
    endfor
endfunction

"""""""""""""""""""""""""""""""""""""""""""
" Parse Buffer
"""""""""""""""""""""""""""""""""""""""""""
function OutputCommandFromVUIBuffer(vui_config)
    echom GenerateCommand(ParseVUIBufferArgs(a:vui_config), a:vui_config)
endfunction

function ParseVUIBufferArgs(vui_config)
    let s:args_dict = {}
    " use search to go through buffer for matches
    call cursor(line('^'), 0)
    let s:pattern = "^\\(\\w\\+\\):\\s\\+\\(.*\\)\\s*$"
    " (word at beginning of line) followed by colon followed by 1 or more whitespace
    " (followed by any characters) excluding trailing whitespace
    while search(s:pattern, 'W')
        let s:line = getline('.')
        let s:match_list = matchlist(s:line, s:pattern)
        let s:arg_name = s:match_list[1]
        let s:arg_value = s:match_list[2]
        let s:args_dict[s:arg_name] = s:arg_value
    endwhile
    return s:args_dict
endfunction

function GenerateCommand(args_dict, vui_config)
    let s:components = [a:vui_config['command']]
    let s:prefix = "--"
    let s:config_args = a:vui_config['args']
    for [k,v] in items(a:args_dict)
        if !has_key(s:config_args, k)
            echo "No config defined for " . k
            continue
        endif

        let s:arg_node = s:config_args[k]
        let s:arg_type = get(s:arg_node, 'type', 'string')

        if s:arg_type == 'boolean'
            if v == s:enabled_keyword
                call add(s:components, s:prefix . k)
            endif
        elseif s:arg_type == 'string'
            call add(s:components, s:prefix . k . ' ' . v)
        else
            echo 'Invalid type for ' . k . ' defaulting to string'
            call add(s:components, s:prefix . k . ' ' . v)
        endif
    endfor
    return join(s:components, " ")    
endfunction

function AppendLast(text)
    call append(line('$'), a:text)
endfunction

let g:vui_config = LoadVUIConfig(glob('~/Desktop/CurrentProjects/vui/doc/example.json'))
call PrintVUIBuffer(g:vui_config)
