local duck = require("duck")

_G.duck_spawner = vim.loop.new_timer()
_G.duck_killer = vim.loop.new_timer()

vim.api.nvim_create_user_command("DuckSpawner", function(opts)
  local animal = opts.fargs[1] or "🐧"

  _G.duck_spawner:start(
    0,
    1000,
    vim.schedule_wrap(function()
      duck.hatch(animal, 5)
    end)
  )
  _G.duck_killer:start(
    4000,
    1000,
    vim.schedule_wrap(function()
      if duck.ducks_list[1] ~= nil then
        duck.cook()
      end
    end)
  )
end, { nargs = "?" })

vim.api.nvim_create_user_command("DuckKiller", function()
  if duck.ducks_list[1] ~= nil then
    duck.cook()
  end
  _G.duck_spawner:stop()
  _G.duck_killer:stop()
end, {})
