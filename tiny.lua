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
	stmtsequence = try(V "statement",errInvalidStatement) * (sym(";") * try(V "statement",errSemicolon) + #V "statement" * T(errMissingSemicolon))^0,
	statement = V "ifstmt" + V "repeatstmt" + V "assignstmt" + V "readstmt" + V "writestmt" ,
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

		
	
while true do
	print("What is the string we want to interpret?")
	str = io.read()
	print(mymatch(str,gram));
end
--[[--


function print_r ( t ) 
    local print_r_cache={}
    local function sub_print_r(t,indent)
        if (print_r_cache[tostring(t)]) then
            print(indent.."*"..tostring(t))
        else
            print_r_cache[tostring(t)]=true
            if (type(t)=="table") then
                for pos,val in pairs(t) do
                    if (type(val)=="table") then
                        print(indent.."["..pos.."] => "..tostring(t).." {")
                        sub_print_r(val,indent..string.rep(" ",string.len(pos)+8))
                        print(indent..string.rep(" ",string.len(pos)+6).."}")
                    else
                        print(indent.."["..pos.."] => "..tostring(val))
                    end
                end
            else
                print(indent..tostring(t))
            end
        end
    end
    sub_print_r(t,"  ")
end

local terror = {}
local vars = {}

local function newError(s)
  table.insert(terror, s)
  return #terror
end
-- error definitions
local errVar = newError("Expecting a Variable, but found an Expression")
local errExp = newError("Expecting an Expression, but found a Command or an invalid operator")
local errAssignment = newError("Unidentified assignment")
local errBracketClose = newError("Missing closing bracket ')'")
local errBracketOpen = newError("Missing opening bracket '('")

local Space = S(" \n\t")^0
local FactorOp = C (S("*/"))
local TermOp = C (S("+-"))
local Open = P "("
local Close = P ")" -- brackets are not captured
local Number = C(P"-"^-1 * R("09")^1)
local Variable = C(R("az","AZ")^1)

gramwitherrors = lpeg.P {
  "Program",   -- initial rule name
  Program = Ct((V "Cmd" + V"Exp" + #Close * T(errBracketOpen) + #(P "=") * T(errAssignment))^0), -- looks for unmatched closing brackets and unidentified assignments
  Cmd = Space * Ct(Variable * C(P "=") * (V "Exp" + T(errExp))) * Space, -- checks if the assignment is not to another command
  Exp = Space * Ct( V "Term" * ((TermOp * V "Term")^0)) * Space,
  Term = Ct( V "Factor" * ((FactorOp * V "Factor")^0)),
  Factor = Space * (Number + Variable + Open * (V "Cmd" * T(errExp) + V "Exp") * (Close + T(errBracketClose))) * Space, -- checks if all opening brackets have their closing brackets and all bracketed input is expressions
} * -1

function interpret(x) -- top level is always programs so we output the result of each program
	for i=1,#x do
		print("Program "..i.." output: " ..interpret_aux(x[i]))
	end
end

function interpret_aux(x) -- here we return true for commands and results for expressions
	if type(x) == "string" then
		return getValue(x)
	else
		if #x == 1 then -- if its a single table then traverse down
			return interpret_aux(x[1])
		else
			if x[2] == "=" then
				return assign(x[1],interpret_aux(x[3]))
			else
				local op1 = interpret_aux(x[1])
				for i=2,#x, 2 do -- perform arithmetic from left to right
					local op = interpret_aux(x[i])
					local op2 = interpret_aux(x[i+1])
					op1 = evaluate(op1,op,op2)
				end
				return op1
			end
		end
	end
end
function getValue(x)
	if lpeg.match(Number,x) then
		return tonumber(x) 
	elseif lpeg.match(FactorOp,x) or lpeg.match(TermOp,x) then
		return tostring(x)
	elseif vars[x] == nil then
		return 0  -- variable not set so assume it is 0
	else
		return vars[x] -- all variables stored dynamically in global array
	end
end
function evaluate(op1, op, op2)
	if op == "+" then
		return op1 + op2
	elseif op == "-" then
		return op1 - op2
	elseif op == "*" then
		return op1 * op2
	elseif op == "/" then
		return op1 / op2
	else
		return getValue(op1)
	end
end
function assign(var,value)
	if lpeg.match(Number,value) then
		vars[var]=tonumber(value)  -- all variables stored dynamically in global table
		return "OK"
	else
		vars[var]=vars[value]
	end
end


print("Program interpreter (with error labels) by Ben")
print("Programs can be separated using spaces and contain variables and expressions")
print("Variable names contain only letters, and are set to 0 by default")
print("Example input: \"a=3 b a=a*(1+1) b=-1 a+b\"")
print("Variables stay in memory until program termination(ctrl+Z)")
while true do
	print("What is the string we want to interpret?")
	str = io.read()
	local r, lab, sfail = gramwitherrors:match(str)
	if not r then
		throwError(str,lab,sfail)
	else
		interpret(r)
	end
end

--]]--

