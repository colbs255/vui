function LoadVUIConfig(file)
    let s:file_text = join(readfile(a:file))
    return json_decode(s:file_text)
endfunction

function OutputVUI(vui_config)
    let s:config_name = a:vui_config["name"]
    vnew
    %delete
    append(s:config_name)
endfunction

let b:vui_config = LoadVUIConfig(glob('~/Desktop/CurrentProjects/vui/doc/example.json'))
call OutputVUI(b:vui_config)
