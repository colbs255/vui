setlocal completefunc=ArgValueCompletion
setlocal buftype=nofile
setlocal bufhidden=hide

command -buffer VUIOutputCommand :call VUIOutputCommand()
command -buffer VUIExecuteCommand :call VUIExecuteCommand()
command -buffer VUIExecuteCommandAndReadOuput :call VUIExecuteCommandAndReadOuput()

if !hasmapto('<Plug>(vui-output-command)')
    nmap <buffer> <localleader>o <Plug>(vui-output-command) 
endif
if !hasmapto('<Plug>(vui-execute-command)')
    nmap <buffer> <localleader>e <Plug>(vui-execute-command)
endif
if !hasmapto('<Plug>(vui-execute-command-and-read)')
    nmap <buffer> <localleader>r <Plug>(vui-execute-command-and-read)
endif
