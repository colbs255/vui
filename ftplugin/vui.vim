setlocal completefunc=ArgValueCompletion
setlocal buftype=nofile
setlocal bufhidden=hide

command -buffer VUIOutputCommand :call VUIOutputCommand()
command -buffer VUIExecuteCommand :call VUIExecuteCommand()
command -buffer VUIExecuteCommandAndReadOuput :call VUIExecuteCommandAndReadOuput()
command -buffer VUIWriteResults :call VUIWriteResults()
command -buffer VUITest <Plug>(vui-output-command)

if !hasmapto('<Plug>(vui-output-command)')
    nmap <buffer> <localleader>o <Plug>(vui-output-command) 
endif
if !hasmapto('<Plug>(vui-execute-command)')
    nmap <buffer> <localleader>e <Plug>(vui-execute-command)
endif
if !hasmapto('<Plug>(vui-execute-command-and-read)')
    nmap <buffer> <localleader>r <Plug>(vui-execute-command-and-read)
endif
if !hasmapto('<Plug>(vui-write-results)')
    nmap <buffer> <localleader>w <Plug>(vui-write-results)
endif
if !hasmapto('<Plug>(vui-change-arg-for-line)')
    nmap <buffer> <localleader>c <Plug>(vui-change-arg-for-line)
endif
