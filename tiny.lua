local lpeg = require "lpeglabel"
local relabel = require "relabel"
--local lpeglabel = require "lpeglabel"
lpeg.locale(lpeg)

local P, V, C, Ct, R, S, B, Cmt = lpeg.P, lpeg.V, lpeg.C, lpeg.Ct, lpeg.R, lpeg.S, lpeg.B, lpeg.Cmt -- for lpeg
local T = lpeg.T -- lpeglabel
local space = lpeg.space

local terror = {}
local vars = {}

local function newError(s)
  table.insert(terror, s)
  return #terror
end
-- error definitions

local errSemicolon = newError("Unexpected semicolon")
local errMissingSemicolon = newError("Missing semicolon")
local errInvalidStatement= newError("Invalid statement")
local errIfMissingThen= newError("Missing keyword 'then' in If statement")
local errIfMissingEnd= newError("Missing keyword 'end' in If statement")
local errRepeatMissingUntil= newError("Missing keyword 'until' in Repeat statement")
local errAssMissingExp= newError("Missing expression on RHS of assignment")
local errReadMissingId= newError("Missing Identifier for read operation")
local errWriteMissingExp= newError("Missing Expression for write operation")
local errCompMissingSExp= newError("Missing Simple Expression for comparison operation")
local errAddopMissingTerm= newError("Missing Term for add operation")
local errMulopMissingFactor= newError("Missing Factor for mul operation")
local errMissingClosingBracket= newError("Missing closing bracket")



function token (patt)
	return patt * V "Skip"
end
function sym (str)
	return token(P(str))
end
function kw (str)
	return token(P(str))
end

function try (patt, err)
	return patt + T(err)
end


--[[  todo
function expect (rule)
	return V(rule) + T(getLabel(rule))
end
-]]--


local gram = P {
	"program",
	program = V "Skip" * V "stmtsequence",
	stmtsequence = try(V "statement",errInvalidStatement) * (sym(";") * try(V "statement",errSemicolon) + #V "firsttokens" * T(errMissingSemicolon))^0,
	
	
	firsttokens = kw("if") + kw("then") + kw("else") + kw("end") + kw("repeat") + kw("until") + kw("read") + kw("write") + V "Number" + V "Identifier", -- for the missing semicolon test
	
	
	statement = V "ifstmt" + V "repeatstmt" + V "assignstmt" + V "readstmt" + V "writestmt",
	
	ifstmt = kw("if") * V "exp" * try(kw("then"),errIfMissingThen) * V "stmtsequence" * (kw("else") * V "stmtsequence")^-1 * try(kw("end"),errIfMissingEnd), -- error for else?
	repeatstmt = kw("repeat") * V "stmtsequence" * try(kw("until"),errRepeatMissingUntil) * V "exp",
	assignstmt = V "Identifier" * sym(":=") * try(V "exp",errAssMissingExp),
	readstmt = kw("read") * try(V "Identifier",errReadMissingId),
	writestmt = kw("write") * try(V "exp",errWriteMissingExp),
	
	exp = V "simpleexp" * (V "comparisonop" * try(V "simpleexp",errCompMissingSExp))^0,
	comparisonop = sym("<") + sym("="),
	
	simpleexp = V "term" * (V "addop" * try(V "term",errAddopMissingTerm))^0,
	addop = sym("+") + sym("-"),
	
	term = V "factor" * (V "mulop" * try(V "factor",errMulopMissingFactor))^0,
	mulop = sym("*") + sym("/"),
	
	factor = sym("(") * V "exp" * try(sym(")"),errMissingClosingBracket) + V "Number" + V "Identifier",
	
	Number = token(P"-"^-1 * R("09")^1),
	Identifier = token(R("az","AZ")^1),
	Skip = (space)^0,
} * -1



function mymatch(s,g)
  local r, e, sfail = g:match(s)
  if not r then
    local line, col = relabel.calcline(s, #s - #sfail)
    local msg = "Error at line " .. line .. " (col " .. col .. "): "
	if e == 0 then
		return r, msg .. "Syntax error before '" .. sfail .. "'"
	else
		return r, msg .. terror[e] .. " before '" .. sfail .. "'"
	end
  end
  return r
end

		
if not arg[1] then	
	while true do
		print("What is the string we want to interpret?")
		str = io.read()
		print(mymatch(str,gram));
	end
else
	-- argument must be in quotes if it contains spaces
	print(mymatch(arg[1],gram));
end