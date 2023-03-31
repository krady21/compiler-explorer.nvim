format:
	stylua --column-width 80 --indent-type Spaces --indent-width 2 --collapse-simple-statement Always lua/ plugin/*.lua

check:
	luacheck .
