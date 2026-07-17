-- Theme is generated from themes/current.toml by `theme apply`.
dofile('/home/maksis/.xmonad/theme-conky.lua')

function conky_binary_oscillator()
    local c = conky_parse("${time %s}")
    if (c % 2 == 0) then
        return 1
    else
        return 0
    end
end
