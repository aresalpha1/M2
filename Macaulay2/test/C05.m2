-- test min
assert( infinity === min {} )
assert( 2 === min { 3,2,4 } )
assert( 2 === min ( 3,2,4 ) )

-- test max
assert( -infinity === max {} )
assert( 4 === max (3,4,2) )
assert( 4 === max {3,4,2} )

-- test unique
assert( unique {4,4,5,5,3,3} === {4, 5, 3} )
assert( unique {3,4,4,5,5,3,3} === {3, 4, 5} )

-- Local Variables:
-- compile-command: "make C05.okay"
-- End:
