function s:EvalArgValueGenerator(expression)
    let range_and_expression_regex = '\v\s*\((.*)\)\s+-\>\s+(.*)\s*'
    let inner_number_regex = '\s*(-?\d+)\s*'
    let range_splitter_regex = '\v'
                \ . inner_number_regex . ',' . inner_number_regex . ',' . inner_number_regex

    let [range_secion, user_expression] = matchlist(a:expression, range_and_expression_regex)[1:2]
    let range_split = matchlist(range_secion, range_splitter_regex)
    let range = {'start': range_split[1], 'end': range_split[2], 'step': range_split[3]}

    return s:EvalLoop(range, user_expression, 'v:val')
endfunction

function s:EvalLoop(range, expression, placeholder)
    let parameterized_expr = substitute(a:expression, '\C' . a:placeholder, '_vui_eval_index', 'g')
    let _vui_eval_index = a:range['start']
    let result = []
    while (a:range['step'] > 0 && _vui_eval_index < a:range['end'])
                \ || (a:range['step'] < 0 && _vui_eval_index > a:range['end'])
        call add(result, eval(parameterized_expr))
        let _vui_eval_index += a:range['step']
    endwhile
    return result
endfunction

echo s:EvalArgValueGenerator('(0,5,1) -> strftime("%Y-%m-%d", localtime() - v:val*24*60*60)')
