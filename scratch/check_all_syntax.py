import glob

scripts = glob.glob('scripts/*.gd')
errors = []
for s in scripts:
    with open(s, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    bracket_stack = []
    line_num = 0
    for l in lines:
        line_num += 1
        code = l.split('#')[0]
        in_str = False
        str_char = ''
        filtered = []
        for ch in code:
            if not in_str:
                if ch in ('"', "'"):
                    in_str = True
                    str_char = ch
                else:
                    filtered.append(ch)
            else:
                if ch == str_char:
                    in_str = False
        code = ''.join(filtered)
        for ch in code:
            if ch in '([{':
                bracket_stack.append((ch, line_num))
            elif ch in ')]}':
                if not bracket_stack:
                    errors.append(f'{s}:{line_num} Unmatched closing {ch}')
                else:
                    open_ch, open_line = bracket_stack.pop()
                    expected = {')': '(', ']': '[', '}': '{'}[ch]
                    if open_ch != expected:
                        errors.append(f'{s}:{line_num} Mismatched {ch}, opened with {open_ch} at line {open_line}')
    if bracket_stack:
        for open_ch, open_line in bracket_stack:
            errors.append(f'{s}:{open_line} Unclosed bracket {open_ch}')

if errors:
    print(f'Found {len(errors)} errors:')
    for e in errors:
        print(' ', e)
else:
    print(f'All {len(scripts)} scripts passed syntax checks!')
