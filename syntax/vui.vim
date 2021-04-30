syntax keyword enabled_keyword _enabled_
syntax keyword disabled_keyword _disabled_
syntax match command_keyword /^\*Command\*/
syntax match arg_name /^:\w\+:/
syntax match title /^=\w\+=/

hi def link title Keyword
hi def link enabled_keyword Boolean
hi def link disabled_keyword Boolean
hi def link arg_name Type
hi def link command_keyword Type
