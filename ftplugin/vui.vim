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
    for s:arg in s:arg_names
        if !has_key(a:vui_config['args'], s:arg)
            echo "No config defined for " . s:arg
            continue
        endif
        let s:arg_node = a:vui_config['args'][s:arg]
        let s:arg_value = get(s:arg_node, 'default', s:disabled_keyword)
        call AppendLast(s:arg . ': '  . s:arg_value)
    endfor
endfunction

"""""""""""""""""""""""""""""""""""""""""""
" Parse Buffer
"""""""""""""""""""""""""""""""""""""""""""
function OutputCommandFromVUIBuffer(vui_config)
endfunction
function ParseVUIBufferArgs(vui_config)
endfunction
function GenerateCommand(args_dict, vui_config)
    let s:result = vui_config['command']
    return s:result
endfunction


function AppendLast(text)
    call append(line('$'), a:text)
endfunction

let g:vui_config = LoadVUIConfig(glob('~/Desktop/CurrentProjects/vui/doc/example.json'))
call PrintVUIBuffer(g:vui_config)
echo GenerateCommand('', g:vui_config)
