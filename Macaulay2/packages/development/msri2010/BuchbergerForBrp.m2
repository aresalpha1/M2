-- -*- coding: utf-8 -*-
load "BitwiseRepresentationPolynomials.m2"
newPackage(
	"BuchbergerForBrp",
    	Version => "0.0", 
    	Date => "January 11,2010",
    	Authors => {
	     {Name => "Franziska Hinkelmann", Email => "fhinkel@vt.edu"}
	     },
    	HomePage => "http://www.math.vt.edu/people/fhinkel",
    	Headline => "compute a Boolean Groebner Basis using a bit-wise representation",
      AuxiliaryFiles => false, -- set to true if package comes with auxiliary files
    	DebuggingMode => true		 -- set to true only during development
    	)

needsPackage "BitwiseRepresentationPolynomials"

-- Any symbols or functions that the user is to have access to
-- must be placed in one of the following two lists
export {makePairsFromLists, 
      gbBrp, 
      gbComputation,
      isReducible,
      minimalGbBrp,
      reduce,
      reduceGbBrp,
      reduceLtBrp,
      reduceOneStep, 
      SPolynomial, 
      updatePairs
      }
exportMutable {}

-- keys should start with 0
gbComputation = new Type of MutableHashTable; 

-- generate the unit vectors representing x_i
unitvector = memoize((i,n) -> ( apply(n,j -> if i === j then 1 else 0)));

-- wrapper script for debugging purposes, creates a Groebner basis from the
-- input list - all with Brps
gbBrp = method()
gbBrp (gbComputation, ZZ) := gbComputation => (F,n) -> ( 
  listOfIndexPairs := makePairsFromLists( keys F, keys F) | makePairsFromLists( keys F, toList(-n..-1) );
  listOfIndexPairs = updatePairs( listOfIndexPairs, F, n );
  while #listOfIndexPairs > 0 do (
    pair := first listOfIndexPairs;
    listOfIndexPairs = delete(pair, listOfIndexPairs); -- very slow, order n^2
    S := SPolynomial(pair, F, n);
    reducedS := reduce (S,F);
    if reducedS != 0 then (
      -- add reducedS to intermediate basis
      listOfIndexPairs = listOfIndexPairs | toList((-n,#F)..(-1, #F)) | apply( keys F, i-> (i,#F) ) ;
      F##F = reducedS;
      listOfIndexPairs = updatePairs( listOfIndexPairs,F,n )
    );
  );
  F = minimalGbBrp(F);
  reduceGbBrp(F)
)

-- delete elements where the leading term is divisible by another leading term
minimalGbBrp = method()
minimalGbBrp( gbComputation ) := gbComputation => (F) -> (
  -- Todo remove extra looping, we want to scan over the "changing" values F
  scan( values F, f -> scan( pairs F, (gKey, g) -> if f != g and isReducible( g, f) then remove(F,gKey) ));
  F
)

--Reduce lower terms of the first polynomial with the leading term of the second
reduceLtBrp = method()
reduceLtBrp(Brp, Brp) := Brp => (f,g) -> (
  while ( l := select(f, m ->  isReducible(new Brp from {m}, leading g) ); #l != 0) do (
      assert isDivisible( new Brp from {first l}, leading g );
   	  f = f + g*divide( new Brp from {first l}, leading g)
  );
  f
)

-- Reduce lower terms of intermediate GB by leading terms of other polynomials
reduceGbBrp = method()
reduceGbBrp( gbComputation ) := gbComputation => F -> (
  changesHappened := true;
  while changesHappened do (
    changesHappened = false;
    scan( pairs F, (fKey,f) ->  
      scan(values F, g ->
        if f!=g then (
          tmpF := reduceLtBrp(f,g);
          if f !=  tmpF then (
            F#fKey = tmpF;
            changesHappened = true;
            break
          )
        )
      )
    )
  );
  F
)

-- remove all relatively prime pairs
updatePairs = method()
updatePairs(List, gbComputation, ZZ) := List => ( l, F, n) -> (
  select( l, (i,j) -> (
    if i < 0 then (
      i = - i;
      f := F#j;
      g := new Brp from {unitvector( i-1,n)}
    ) 
    else (
      f = F#i;
      g = F#j
    );
    not isRelativelyPrime(leading f, leading g)
  )
  )
)

  
-- from pair of indices get corresponding polynomials, then compute their S
-- polynomial
-- assume that the pairs are good (i.e., leading terms not relatively prime)
SPolynomial = method()
SPolynomial( Sequence, gbComputation, ZZ ) := Brp => (pair,G,n) -> (
  (i,j) := pair;
  if i < 0 then ( -- we are working with an FP
    i = - i;
    f := G#j;
    xx := new Brp from {unitvector( i-1,n)};
    g := new Brp from select( f, mono -> isDivisible( new Brp from {mono}, xx) == false );
    g*xx+g
  )
  else (
    f = G#i;
    g = G#j;
    leadingLcm := lcmBrps(leading(f), leading(g));
    f* (divide( leadingLcm, leading f)) + g* (divide( leadingLcm, leading g)) 
  )
)

-- Reduce the polynomial until the leading term is not divisible by the
-- leading element of any element in G
reduce = method()
reduce (Brp, gbComputation) := Brp => (f,G) -> (
  while (newF := reduceOneStep(f,G); newF != f and newF != 0) do 
    f = newF;
  newF
)

-- 
reduce (Brp, Brp) := Brp => (f,g) -> (
  reduce ( f, new gbComputation from { 1=> g} )
)

-- Reduce the leading term of a polynomial one step using a polynomial
reduceOneStep = method()
reduceOneStep(Brp, Brp) := Brp => (f,g) -> (
  if f != 0 then (
    assert( isReducible(f, g));
    leadingLcm :=  lcmBrps(leading(f), leading(g));
    f + g * divide(leadingLcm, leading g) 
  ) else new Brp from {} -- TODO make 0 automatically turn into 0
)

-- reduce the leading term of a polynomial f one step by the first polynomial
-- g_i in the intermediate basis that satisfies isReducible(f,g_i)
reduceOneStep(Brp, gbComputation) := Brp => (f,G) -> (
  if f != 0 then (
    scan( (values G), p -> if isReducible(f, p) then (break f = reduceOneStep(f,p)));
    f
  ) else new Brp from {} 
)

-- Make a list with all possible pairs of elements of the separate lists, but
-- remove self-pairs 
makePairsFromLists = method()
makePairsFromLists (List,List) := List => (a,b) -> (
  ll := (apply( a, i-> apply(b, j-> if i != j then toSequence sort {i,j} else 0 ) ));
  unique delete(0, flatten ll)
)

-- check if the leading term of one polynomial can be reduced by another polynomial
isReducible = method()
isReducible (Brp, Brp) := Boolean => (f,g) -> (
  assert (f != 0 );
  isDivisible(leading f, leading g)
)

doc ///
Key 
  BuchbergerForBrp
Headline
  BuchbergerForBrp making use of bit-wise representation
///

doc ///
Key 
  (updatePairs,List, gbComputation, ZZ) 
  updatePairs
Headline
  update a list of indices for good indices
///

doc ///
Key 
  (reduceLtBrp,Brp,Brp)
  reduceLtBrp
Headline
  reduce polynomial by the leading term of another
///

doc ///
Key 
  gbComputation
Headline
  MutableHashTable for an intermediate Groebner basis
///

doc ///
Key 
  (minimalGbBrp,gbComputation)
  minimalGbBrp
Headline
  delete elements where the leading term is divisible by another leading term
///

doc ///
Key 
  (isReducible,Brp,Brp)
  isReducible
Headline
  check if the leading term of one polynomial can be reduced by another polynomial
///

doc ///
Key 
  (SPolynomial, Sequence, gbComputation, ZZ)
  SPolynomial
Headline
  from pair of indices get corresponding polynomials, then compute their S polynomial assume that the pairs are good (i.e., leading terms not relatively prime)
///

doc ///
Key
  (makePairsFromLists,List,List)
  makePairsFromLists
Headline
  Make a list with all possible pairs of elements of the separate lists, but remove self-pairs 
///

doc ///
Key
  (reduceOneStep,Brp,gbComputation)
  (reduceOneStep,Brp,Brp)
  reduceOneStep
Headline
  Reduce the leading term of a polynomial one step using a polynomial
///

doc ///
Key
  (gbBrp,gbComputation,ZZ)
  gbBrp
Headline
  wrapper script for debugging purposes, creates a Groebner basis from the input list - all with Brps
///

doc ///
Key 
  (reduce,Brp,gbComputation)
  (reduce,Brp,Brp)
  reduce
Headline
  Reduce the polynomial until the leading term is not divisible by the leading element of any element in G
Usage
  g=reduce(f,F)
Inputs 
  f:Brp
    a polynomial
  F:gbComputation
    a list of polynomials
Outputs
  g:Brp
    f reduced by F 
///

TEST ///
  assert( makePairsFromLists( {1,2,3,4,5}, {1,2,3,4,5}) ==  {(1, 2), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5), (3, 4), (3, 5), (4, 5)})
  assert(  makePairsFromLists( {1,2,3}, {10,100,1000}) == {(1, 10), (1, 100), (1, 1000), (2, 10), (2, 100), (2, 1000), (3, 10), (3, 100), (3, 1000)})
  assert ( makePairsFromLists( {-1,-3,-2}, {100, 10}) == {(-1, 100), (-1, 10), (-3, 100), (-3, 10), (-2, 100), (-2, 10)} )
  assert ( makePairsFromLists ( {0,1,2}, {22} ) == {(0, 22), (1, 22), (2, 22)})
  
  R = ZZ[x,y,z]
  myPoly1 = convert( x*y + z)
  myPoly2 = convert( x )
  myPoly3 = convert( y*z + z)
  myPoly4 = convert( x*y*z + x*y + x)
  myPoly5 = convert( x*y + y*z)
  F = new gbComputation from { 1 => myPoly1,
                           2 => myPoly2,
                           3 => myPoly3,
                           4 => myPoly4,
                           5 => myPoly5
                           }
  FOnePoly = new gbComputation from { 1 => convert(x+y+z) } 

  S = SPolynomial((-1,1), F, numgens R)
  assert (S == convert( x*z + z) )
  S = SPolynomial((-1,2), F, numgens R)
  assert (S == 0 )
  S = SPolynomial((1,3), F, numgens R)
  assert (S == convert( x*z+z) ) 
  S = SPolynomial((4,5), F, numgens R)
  assert (S == convert( x*y + x + y*z) ) 

  assert ( reduceOneStep( convert(x*y*z + y*z + z), convert(x+y+z) ) == convert( y*z+z))
  assert ( reduce( convert(x*y*z + y*z + z), convert(x+y+z) ) == convert( y*z+z))
  assert ( reduce( convert(x*y*z + y*z + z), FOnePoly ) == convert( y*z+z))
  assert ( reduceOneStep( convert(y+z), F) == convert( y+z) )
  assert ( reduceOneStep( convert(x*y*z + y*z + z), F ) == convert( y*z))
  assert ( reduce( convert(x*y*z + y*z + z), F ) == convert( z))

  l = makePairsFromLists( keys F, keys F) 
  assert( l == {(1, 2), (1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5), (3, 4), (3, 5), (4,5)})
  assert ( updatePairs (l, F, numgens R) == {(1, 2), (1, 3), (1, 4), (1, 5), (2, 4), (2, 5), (3, 4), (3, 5), (4, 5)})
  ll = makePairsFromLists( keys F, {-1} )
  assert ( updatePairs( ll, F, numgens R) ==  {(-1, 1), (-1, 2), (-1, 4), (-1, 5)} )
  lll = makePairsFromLists( keys F, {-3} )
  assert ( updatePairs( lll, F, numgens R) == {(-3, 3), (-3, 4)} )
  
  R = ZZ/2[x,y,z];
  F = new gbComputation from { 0 => convert x }
  assert ( first values gbBrp(F,numgens R) == new Brp from {{1, 0, 0}} )
  F = new gbComputation from { 0 => convert x,
                                  1 => convert y}
  gbBrp(F,numgens R)                                
  assert ( first values gbBrp(F,numgens R) == new Brp from {{1, 0, 0}} )
  F = new gbComputation from { 0 => convert (x*y),
                                  1 => convert y}
  gbBrp(F,numgens R)                                

  R = ZZ/2[x,y,z];
  F = new gbComputation from { 0 => convert (x*y+z) }
  assert(flatten flatten values gbBrp(F, numgens R) == {1, 1, 0, 0, 0, 1, 0, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 1})


-- R = ZZ/2[x,y,z]/ideal(x*y+z)
-- i11 : gens gb ideal(x*y+z)

-- o11 = | yz+z xz+z xy+z |

  myPoly1 = new Brp from {{1,0,0}};
  myPoly2 = new Brp from {{1,0,1}};
  myPoly3 = new Brp from {{1,1,0}, {0,0,1}};
  -- list of input polynomials
  F = new MutableHashTable from {0 => myPoly1,
                          1 => myPoly2,
                          2 => myPoly3};

  R = ZZ/2[a..j, MonomialOrder=>Lex]
 I = ideal (a^2+a,
            b^2+b,
            c^2+c,
            d^2+d,
            e^2+e,
            f^2+f,
            g^2+g,
            h^2+h,
            i^2+i,
            j^2+j)

  R = ZZ/2[a..j, MonomialOrder=>Lex]/(a^2+a,
                                    b^2+b,
                                    c^2+c,
                                    d^2+d,
                                    e^2+e,
                                    f^2+f,
                                    g^2+g,
                                    h^2+h,
                                    i^2+i,
                                    j^2+j)
  J = ideal(a*b*c*d*e, a+b*c+d*e+a+b+c+d, j*h+i+f, g+f, a+d, j+i+d*c)
  J = J + I
  gens gb J
  --g+hj+i f+hj+i ei+ej di+dj+i+j c+i+j bi+bj+b+de+d+i+j be bd+b a+d 
  
  R = ZZ/2[a..j]
  F = new gbComputation from { 0=> convert(a*b*c*d*e),
          1=> convert( a+b*c+d*e+a+b+c+d),
          2=> convert( j*h+i+f),
          3=> convert( g+f),
          4=> convert( a+d),
          5=> convert( j+i+d*c)
          }
  gbBasis = gbBrp( F, numgens R)
  sort apply (values gbBasis, poly -> convert(poly,R) )
  sort {g+h*j+i,f+h*j+i,e*i+e*j,d*i+d*j+i+j,c+i+j,b*i+b*j+b+d*e+d+i+j,b*e,b*d+b,a+d}

  R = ZZ/2[x,y,z,w]
  F = new gbComputation from { 0 => convert(x*y*w+w*x+z),
                              1 => convert (x*z+w*y) }
  gbBasis = gbBrp(F,numgens R)
  apply (values gbBasis, poly -> convert(poly,R) )
  assert( sort apply (values gbBasis, poly -> convert(poly,R) ) == sort {x*w, z, y*w})

  R = ZZ[x,y,z]
  F = new gbComputation from { 0 => convert( x*y + z),
                           1 => convert( x ) ,
                           2 => convert( y*z + z),
                           3 => convert( x*y*z + x*y + x) ,
                           4 => convert( x*y + y*z)
                           }
  R = ZZ[x,y,z]
  myPoly1 = convert( x*y + z)
  myPoly2 = convert( x )
  myPoly3 = convert( y*z + z)
  myPoly4 = convert( x*y*z + x*y + x)
  myPoly5 = convert( x*y + y*z)
  F = new gbComputation from { 1 => myPoly1,
                           2 => myPoly2,
                           3 => myPoly3,
                           4 => myPoly4,
                           5 => myPoly5
                           }
  FOnePoly = new gbComputation from { 1 => convert(x+y+z) } 
  minimalGbBrp(F)

  peek F
  assert ( #F == 2 ) 
  assert (F#2 == new Brp from {{1, 0, 0}} )
  assert (F#3 == new Brp from {{0, 1, 1}, {0, 0, 1}} )

  R = ZZ/2[x,y,z]
  a = convert(x*z + y*z + z)
  b = convert(y+z)
  assert( reduceLtBrp(a,b) == new Brp from {{1, 0, 1}} )
  a = convert(x*z + y*z + y)
  b = convert(y+z)
  assert( reduceLtBrp(a,b) == new Brp from {{1, 0, 1}} )
  a = convert(x*z + y*z + y + z)
  assert( reduceLtBrp(a,b) == new Brp from {{1, 0, 1}, {0,0,1}} )

  a = convert(x*y + y*z +z)
  b= convert(y*z +z)
  assert( reduceLtBrp(a,b)== new Brp from {{1, 1, 0}})

  R = ZZ/2[x,y,z]
  a = convert(x*y + y*z + z)
  b = convert(y*z + z)
  c = convert(x*z + z)
  F = new gbComputation from {0=>a, 1=>b, 2=>c}
  reduceGbBrp(F)
  assert( apply( values F, i -> convert(i,R) ) == {x*y, y*z + z, x*z + z} )

  R = ZZ/2[x,y,z,w]
  a = convert(x*y + y*w*z + w*z +w)
  b = convert(y*z + w*z)
  c = convert(w)
  F = new gbComputation from {0=>a, 1=>b, 2=>c}
  reduceGbBrp(F)
  assert( sort apply( values F, i -> convert(i,R) ) == sort{x*y, y*z, w} )


///
  
       
end

-- Here place M2 code that you find useful while developing this
-- package.  None of it will be executed when the file is loaded,
-- because loading stops when the symbol "end" is encountered.

restart
installPackage "BuchbergerForBrp"
installPackage("BuchbergerForBrp", RemakeAllDocumentation=>true)
check BuchbergerForBrp