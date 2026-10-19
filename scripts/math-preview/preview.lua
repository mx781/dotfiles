local M = {}
local directory = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':h')

local function trim(text)
  return (text:gsub('^%s+', ''):gsub('%s+$', ''))
end

local function unwrap(text)
  text = trim(text)
  local delimiters = {
    {'$$', '$$', true},
    {'\\[', '\\]', true},
    {'\\(', '\\)', false},
    {'$', '$', false},
  }
  for _, delimiter in ipairs(delimiters) do
    local opening, closing, display = unpack(delimiter)
    if text:sub(1, #opening) == opening and text:sub(-#closing) == closing
        and #text >= #opening + #closing then
      return trim(text:sub(#opening + 1, -#closing - 1)), display
    end
  end
  return text, text:find('\n', 1, true) ~= nil
end

-- Byte offsets match Neovim cursor columns, including in UTF-8 notes.
function M.extract(lines, row, col)
  -- Some terminal/LLM output uses standalone `[` and `]` lines as display
  -- delimiters instead of LaTeX's `\[` and `\]`. Accept only whole lines so
  -- Markdown links and ordinary brackets do not become math accidentally.
  local bracket_start, line_fence
  for line_number, line in ipairs(lines) do
    local fence_run = line:match('^%s*(```+)') or line:match('^%s*(~~~+)')
    if fence_run then
      if not line_fence then line_fence = fence_run
      elseif fence_run:sub(1, 1) == line_fence:sub(1, 1)
          and #fence_run >= #line_fence then line_fence = nil end
    elseif not line_fence then
      if not bracket_start and line:match('^%s*%[%s*$') then
        bracket_start = line_number
      elseif bracket_start and line:match('^%s*%]%s*$') then
        if row >= bracket_start and row <= line_number then
          return table.concat(vim.list_slice(lines, bracket_start + 1, line_number - 1), '\n'), true
        end
        bracket_start = nil
      end
    end
  end

  local text = table.concat(lines, '\n')
  local cursor = col + 1
  for n = 1, row - 1 do cursor = cursor + #lines[n] + 1 end
  local function escaped(i)
    local n = 0
    while i > 1 and text:sub(i - 1, i - 1) == '\\' do n = n + 1; i = i - 1 end
    return n % 2 == 1
  end
  local i, opening, fence, ticks = 1, nil, nil, nil
  while i <= #text do
    local c, pair = text:sub(i, i), text:sub(i, i + 1)
    local advance = 1
    if not opening and (i == 1 or text:sub(i - 1, i - 1) == '\n') then
      local run = text:sub(i):match('^ *(```+)' ) or text:sub(i):match('^ *(~~~+)')
      if run then
        if not fence then fence = run
        elseif run:sub(1, 1) == fence:sub(1, 1) and #run >= #fence then fence = nil end
        i = text:find('\n', i, true) or (#text + 1)
        c, pair = '\n', '\n'
      end
    end
    if not fence then
      if not opening and c == '`' and not escaped(i) then
        local run = text:sub(i):match('^`+')
        if not ticks then ticks = #run elseif ticks == #run then ticks = nil end
        advance = #run
      elseif not ticks and not escaped(i) then
        if opening then
          if text:sub(i, i + #opening.close - 1) == opening.close then
            if cursor >= opening.start and cursor < i + #opening.close then
              return text:sub(opening.body, i - 1), opening.display
            end
            advance = #opening.close
            opening = nil
          elseif c == '\n' and not opening.display then opening = nil end
        else
          local close, display
          if pair == '$$' then close, display = '$$', true
          elseif pair == '\\[' then close, display = '\\]', true
          elseif pair == '\\(' then close, display = '\\)', false
          elseif c == '$' and text:sub(i + 1, i + 1):match('%S') then close, display = '$', false end
          if close then
            advance = #close
            opening = {start = i, body = i + advance, close = close, display = display}
          end
        end
      end
    end
    i = i + advance
  end
end

local function render(tex, display)
  local function warn(message) vim.notify('NFHMath: ' .. message, vim.log.levels.ERROR) end
  if trim(tex) == '' then warn('empty selection'); return true end
  for _, exe in ipairs({'node', 'feh'}) do
    if vim.fn.executable(exe) == 0 then warn('missing executable: ' .. exe); return true end
  end
  if vim.fn.isdirectory(directory .. '/node_modules') == 0 then
    warn('install renderer dependencies: npm ci --prefix ' .. vim.fn.shellescape(directory))
    return true
  end
  local output = vim.fn.tempname() .. '.png'
  vim.system({'node', directory .. '/render.mjs', output, display and 'display' or 'inline'},
    {stdin = tex, text = true, timeout = 30000}, vim.schedule_wrap(function(result)
      if result.code ~= 0 then
        vim.fn.delete(output)
        warn(result.stderr or 'render failed')
        return
      end
      local job = vim.fn.jobstart({'feh', '--title', 'Markdown math', '--auto-zoom', output}, {
        on_exit = function() vim.fn.delete(output) end,
      })
      if job <= 0 then vim.fn.delete(output); warn('could not start feh') end
    end))
  return true
end

function M.preview(quiet)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local tex, display = M.extract(vim.api.nvim_buf_get_lines(0, 0, -1, false), cursor[1], cursor[2])
  if not tex then
    if not quiet then vim.notify('NFHMath: no math under cursor', vim.log.levels.WARN) end
    return false
  end
  return render(tex, display)
end

function M.preview_line()
  local tex, display = unwrap(vim.api.nvim_get_current_line())
  return render(tex, display)
end

function M.preview_selection()
  local start_pos, end_pos = vim.fn.getpos("'<"), vim.fn.getpos("'>")
  local lines = vim.api.nvim_buf_get_text(0, start_pos[2] - 1, start_pos[3] - 1,
    end_pos[2] - 1, end_pos[3], {})
  local tex, display = unwrap(table.concat(lines, '\n'))
  return render(tex, display)
end
return M
