local t = require "tiny"
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

assert(not r and e == t.errSemicolon)

-- errMissingSemicolon:
s = "a:=1b:=5"
r, e = tiny(s)

assert(not r and e == t.errMissingSemicolon)
-- errInvalidStatement:
s = "if:=3"
r, e = tiny(s)

assert(not r and e == t.errInvalidStatement)

-- errIfMissingThen:
s = "if a=1 c:=3 end"
r, e = tiny(s)

assert(not r and e == t.errIfMissingThen)

-- errIfMissingEnd:
s = "if a=1 then c:=3"
r, e = tiny(s)

assert(not r and e == t.errIfMissingEnd)

-- errRepeatMissingUntil:
s = "repeat a:=1"
r, e = tiny(s)

assert(not r and e == t.errRepeatMissingUntil)

-- errAssMissingExp:
s = "d:="
r, e = tiny(s)

assert(not r and e == t.errAssMissingExp)

-- errReadMissingId:
s = "read "
r, e = tiny(s)

assert(not r and e == t.errReadMissingId)

-- errWriteMissingExp:
s = "write "
r, e = tiny(s)

assert(not r and e == t.errWriteMissingExp)
-- errCompMissingSExp:
s = "if a< then c:=4 end"
r, e = tiny(s)

assert(not r and e == t.errCompMissingSExp)

-- errAddopMissingTerm:
s = "a:=b+"
r, e = tiny(s)

assert(not r and e == t.errAddopMissingTerm)

-- errMulopMissingFactor:
s = "a:=1*"
r, e = tiny(s)

assert(not r and e == t.errMulopMissingFactor)

-- errMissingClosingBracket:
s = "a:=(1"
r, e = tiny(s)

assert(not r and e == t.errMissingClosingBracket)

print("Tests successful!")
