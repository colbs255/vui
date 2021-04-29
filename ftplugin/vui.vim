setlocal completefunc=ArgValueCompletion
setlocal buftype=nofile
setlocal bufhidden=hide

command -buffer VUIOutputCommand :call VUIOutputCommand()
command -buffer VUIExecuteCommand :call VUIExecuteCommand()
command -buffer VUIExecuteCommandAndReadOuput :call VUIExecuteCommandAndReadOuput()

" TODO: Figure these mappings out
noremap <Plug>(vui-output-command) :VUIOutputCommand<CR>
noremap <Plug>(vui-execute-command) :VUIExecuteCommand<CR>
noremap <Plug>(vui-execute-command-and-read) :VUIExecuteCommandAndReadOuput<CR>

nmap <buffer> <localleader>o <Plug>(vui-output-command) 
nmap <buffer> <localleader>e <Plug>(vui-execute-command)
nmap <buffer> <localleader>r <Plug>(vui-execute-command-and-read)
