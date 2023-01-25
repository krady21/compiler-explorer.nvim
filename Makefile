format:
	stylua --indent-type Spaces --indent-width=2 lua/ plugin/*.lua

check:
	luacheck .
