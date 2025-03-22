--
-- Copy, paste
--
KEYMAP({ "n", "v" }, "<Leader>y", '"+y', GET_OPTIONS("Copy-paste: [Y]oink to clipboard"))
KEYMAP("v", "<Leader>x", '"+x', GET_OPTIONS("Copy-paste: Cut to clipboard"))
KEYMAP("v", "<Leader>p", '"_c<Esc>p', GET_OPTIONS("Copy-paste: [P]aste without yoinking selected"))
KEYMAP("v", "<Leader>d", '"_d', GET_OPTIONS("Copy-paste: [D]elete without yoinking selected"))
