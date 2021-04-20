command -complete=customlist,GetVUIsCompletionFunction  -nargs=1 VUI call s:OpenVUI(<f-args>)

function GetVUIsCompletionFunction(ArgLead, CmdLine, CursoPos)
    let vui_dict = LoadVUIConfig(g:vui_config_file)
    return keys(vui_dict)
endfunction

function LoadVUIConfig(file)
    let file_text = join(readfile(a:file))
    return json_decode(file_text)
endfunction

function s:OpenVUI(vui_name)
    execute ':e ~/.vim/__' . a:vui_name . '__.vui'
endfunction

