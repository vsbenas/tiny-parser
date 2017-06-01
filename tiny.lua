local lpeg = require "lpeglabel"
local relabel = require "relabel"
--local lpeglabel = require "lpeglabel"
lpeg.locale(lpeg)

local P, V, C, Ct, R, S, B, Cmt = lpeg.P, lpeg.V, lpeg.C, lpeg.Ct, lpeg.R, lpeg.S, lpeg.B, lpeg.Cmt -- for lpeg
local T = lpeg.T -- lpeglabel
local space = lpeg.space
local alpha = lpeg.alpha

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

local errExtra = newError("Extra")


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

function throws(patt,err) -- if pattern is matched throw error
	return patt * T(err)
end

--[[  todo
function expect (rule)
	return V(rule) + T(getLabel(rule))
end
-]]--


local gram = P {

	"program",
	
	program = V "Skip" * V "stmtsequence" * -1 + T(errExtra),
	
	stmtsequence = V "statement" * (sym(";") * (V "eossemicolon" + V "statement") + throws(#V "firstTokens",errMissingSemicolon))^0,
	
	eossemicolon = throws(-1,errSemicolon), -- semicolon at the end of the input
	
	firstTokens = V "keywordsStart" + V "Identifier", -- for the missing semicolon test
	
	keywords = V "keywordsStart" + V "keywordsRest",
	keywordsStart = P "if" + P "repeat" + P "read" + P "write", -- keywords that appear in the beginning of a statement, necessary to check for missing semicolons
	keywordsRest = P "then" + P "else" + P "end" + P "until",
	
	
	statement = try(V "assignstmt" +V "ifstmt" + V "repeatstmt" + V "readstmt" + V "writestmt",errInvalidStatement), -- assignstmt is moved first to match "ifa:=4" instead of "if a (expect:then).."
	
	ifstmt = kw("if") * V "exp" * try(kw("then"),errIfMissingThen) * V "stmtsequence" * (kw("else") * V "stmtsequence")^-1 * try(kw("end"),errIfMissingEnd),
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
	Identifier = token(alpha^1 - #V "Reserved"),
	
	Reserved = V "keywords" * -alpha, -- ifabc is a valid identifier; if, if3 if. are not
	
	Skip = (space)^0,
}



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

function tiny(str) -- to use from test file
	local r, e, sfail = gram:match(str)
	return r,e
end		


if arg[1] then	
	-- argument must be in quotes if it contains spaces
	print(mymatch(arg[1],gram));
end
	

local re = {
tiny = tiny,
errSemicolon = errSemicolon,
errMissingSemicolon = errMissingSemicolon,
errInvalidStatement = errInvalidStatement,
errIfMissingThen=errIfMissingThen,
errIfMissingEnd=errIfMissingEnd,
errRepeatMissingUntil=errRepeatMissingUntil,
errAssMissingExp=errAssMissingExp,
errReadMissingId=errReadMissingId,
errWriteMissingExp=errWriteMissingExp,
errCompMissingSExp=errCompMissingSExp,
errAddopMissingTerm=errAddopMissingTerm,
errMulopMissingFactor=errMulopMissingFactor,
errMissingClosingBracket=errMissingClosingBracket
}
return re