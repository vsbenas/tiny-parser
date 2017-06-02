local t = require "tinyrec"
local tiny = t.tiny

-- correct examples
s1 = "a:=4"

r, e = tiny(s1)

assert(r == #s1 + 1)

s2 = "if a<4 then c:=4 end"

r, e = tiny(s2)

assert(r == #s2 + 1)

s3 = "if a<4 then c:=4 else d:=5 end"

r, e = tiny(s3)

assert(r == #s3 + 1)

s4 = "repeat c:=5 until d=4"

r, e = tiny(s4)

assert(r == #s4 + 1)

s5 = "read d"

r, e = tiny(s5)

assert(r == #s5 + 1)

s6 = "write x=5"

r, e = tiny(s6)

assert(r == #s6 + 1)

-- combine all of these

s = s1.." ; "..s2.." ; "..s3.." ; "..s4.." ; "..s5.." ; "..s6
r, e = tiny(s)

assert(r == #s + 1)

-- complex expression
e = "(3*(4+2)/-1)"
s = "write "..e

r, e = tiny(s)

assert(r == #s + 1)

-- identifier containing keyword
s = "ifa := 1"

r, e = tiny(s)

assert(r == #s + 1)

-- error section

-- errSemicolon:
s = "a:=1;"
r, e = tiny(s)
assert(r and e[1].label ==t.errSemicolon)

-- errMissingSemicolon:
s = "a:=1b:=5"
r, e = tiny(s)

assert(r and e[1].label ==t.errMissingSemicolon)
-- errInvalidStatement:
s = "abc 3"
r, e = tiny(s)
assert(r and e[1].label ==t.errInvalidStatement)

-- errIfMissingThen:
s = "if a=1 c:=3 end"
r, e = tiny(s)

assert(r and e[1].label ==t.errIfMissingThen)

-- errIfMissingEnd:
s = "if a=1 then c:=3"
r, e = tiny(s)

assert(r and e[1].label ==t.errIfMissingEnd)

-- errRepeatMissingUntil:
s = "repeat a:=1"
r, e = tiny(s)



assert(r and e[1].label ==t.errRepeatMissingUntil)
-- FAILS! returns Invalid statement


-- errAssMissingExp:
s = "d:="
r, e = tiny(s)

assert(r and e[1].label ==t.errAssMissingExp)

-- errReadMissingId:
s = "read "
r, e = tiny(s)

assert(r and e[1].label ==t.errReadMissingId)

-- errWriteMissingExp:
s = "write "
r, e = tiny(s)

assert(r and e[1].label ==t.errWriteMissingExp)
-- errCompMissingSExp:
s = "if a< then c:=4 end"
r, e = tiny(s)

assert(r and e[1].label ==t.errCompMissingSExp)

-- errAddopMissingTerm:
s = "a:=b+"
r, e = tiny(s)

assert(r and e[1].label ==t.errAddopMissingTerm)

-- errMulopMissingFactor:
s = "a:=1*"
r, e = tiny(s)

assert(r and e[1].label ==t.errMulopMissingFactor)

-- errMissingClosingBracket:
s = "a:=(1"
r, e = tiny(s)

assert(r and e[1].label ==t.errMissingClosingBracket)


--errExtra
s = "a:=1 )"
r, e = tiny(s)

assert(r and e[1].label ==t.errExtra)

--errMissingExp
s = "if then c:=1 end"
r, e = tiny(s)

assert(r and e[1].label ==t.errMissingExp)

-- multiple errors
-- errMissingClosingBracket + errMulopMissingFactor + errAddopMissingTerm + errReadMissingId + errSemicolon
s = "a:=(1;a:=1*;a:=1+;read;"

r, e = tiny(s)
assert(r 
	and e[1].label ==t.errMissingClosingBracket 
	and e[2].label ==t.errMulopMissingFactor 
	and e[3].label ==t.errAddopMissingTerm 
	and e[4].label ==t.errReadMissingId 
	and e[5].label ==t.errSemicolon)


print("Tests successful!")
