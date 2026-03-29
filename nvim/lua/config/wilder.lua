local wilder = require("wilder")
wilder.setup({ modes = { ":", "/", "?" } })

wilder.set_option("pipeline", {
    wilder.branch(
        wilder.python_file_finder_pipeline({
            file_command = function(ctx, arg)
                if string.find(arg, ".") ~= nil then
                    return { "fdfind", "-tf", "-H" }
                else
                    return { "fdfind", "-tf" }
                end
            end,
            dir_command = { "fd", "-td" },
            filters = { "cpsm_filter" },
        }),
        wilder.substitute_pipeline({
            pipeline = wilder.cmdline_pipeline({
                language = 'vim',
                fuzzy = 1,
            }),
        }),
        wilder.cmdline_pipeline({
            language = 'vim',
            fuzzy = 1,
        }),
        {
            wilder.check(function(ctx, x)
                return x == ""
            end),
            wilder.history(),
        }
    ),
})

-- === Gradient highlighting ===
local gradient = {
	"#f4468f",
	"#fd4a85",
	"#ff507a",
	"#ff566f",
	"#ff5e63",
	"#ff6658",
	"#ff704e",
	"#ff7a45",
	"#ff843d",
	"#ff9036",
	"#f89b31",
	"#efa72f",
	"#e6b32e",
	"#dcbe30",
	"#d2c934",
	"#c8d43a",
	"#bfde43",
	"#b6e84e",
	"#aff05b",
}

for i, fg in ipairs(gradient) do
	gradient[i] = wilder.make_hl("WilderGradient" .. i, "Pmenu", { { a = 1 }, { a = 1 }, { foreground = fg } })
end

-- Base highlighters - use basic_highlighter (works without dependencies)
local base_highlighters = {
	wilder.pcre2_highlighter(),
	wilder.basic_highlighter(),
}

-- Popupmenu renderer with gradient
local popupmenu_renderer = wilder.popupmenu_renderer(wilder.popupmenu_border_theme({
	border = "rounded",
	empty_message = wilder.popupmenu_empty_message_with_spinner(),
	highlights = {
		gradient = gradient,
	},
	highlighter = wilder.highlighter_with_gradient(base_highlighters),
	left = {
		" ",
		wilder.popupmenu_devicons(),
		wilder.popupmenu_buffer_flags({
			flags = " a + ",
			icons = { ["+"] = "", a = "", h = "" },
		}),
	},
	right = {
		" ",
		wilder.popupmenu_scrollbar(),
	},
}))

-- Wildmenu renderer with gradient
local wildmenu_renderer = wilder.wildmenu_renderer({
	highlights = {
		gradient = gradient,
	},
	highlighter = wilder.highlighter_with_gradient(base_highlighters),
	separator = " · ",
	left = { " ", wilder.wildmenu_spinner(), " " },
	right = { " ", wilder.wildmenu_index() },
})

-- Renderer mux
wilder.set_option(
	"renderer",
	wilder.renderer_mux({
		[":"] = popupmenu_renderer,
		["/"] = wildmenu_renderer,
		substitute = wildmenu_renderer,
	})
)
