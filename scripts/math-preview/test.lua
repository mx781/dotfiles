local m = dofile('scripts/math-preview/preview.lua')
local function check(lines, row, col, expected)
  local actual = m.extract(lines, row, col)
  assert(actual == expected, vim.inspect({lines, actual=actual, expected=expected}))
end
check({'hello $x^2$ world'}, 1, 8, 'x^2')
check({'hello $x^2$ world'}, 1, 13, nil)
check({'$$', '\\frac{a}{b}', '$$'}, 2, 4, '\n\\frac{a}{b}\n')
check({'α $x$ and $y$'}, 1, 12, 'y')
check({'`$x$`'}, 1, 2, nil)
check({'```tex', '$x$', '```'}, 2, 2, nil)
check({'~~~', '$x$', '~~~', '$y$'}, 4, 1, 'y')
check({'\\$5 and $x$'}, 1, 10, 'x')
check({'\\(x+1\\)'}, 1, 3, 'x+1')
check({'\\[', 'x+1', '\\]'}, 2, 2, '\nx+1\n')
check({'  [', '  t^*=\\arg\\max_t E[\\text{PnL}(t)]', '  ]'}, 2, 8,
  '  t^*=\\arg\\max_t E[\\text{PnL}(t)]')
check({'[a Markdown link](target)'}, 1, 2, nil)
check({'```text', '[', 'x^2', ']', '```'}, 3, 1, nil)
check({'$unfinished'}, 1, 3, nil)
print('14 extraction checks passed')
-- Exercise the real renderer, intercepting only the graphical viewer.
vim.api.nvim_buf_set_lines(0, 0, -1, false, {'$\\frac{a}{b}$'})
vim.api.nvim_win_set_cursor(0, {1, 4})
local original = vim.fn.jobstart
local viewed = false
vim.fn.jobstart = function(argv, opts)
  assert(argv[1] == 'feh')
  assert(vim.fn.filereadable(argv[#argv]) == 1)
  local file = assert(io.open(argv[#argv], 'rb'))
  assert(file:read(8) == '\137PNG\r\n\26\n')
  file:close()
  opts.on_exit()
  assert(vim.fn.filereadable(argv[#argv]) == 0)
  viewed = true
  return 1
end
assert(m.preview(false))
assert(vim.wait(10000, function() return viewed end), 'renderer/viewer handoff timed out')
vim.fn.jobstart = original
print('PNG rendering, viewer handoff, and cleanup passed')
