// Copyright 2008 Anton Leykin and Mike Stillman

// Anton Leykin's code in this file is in the public domain.

#ifndef _nag_
#define _nag_

#include "matrix.hpp"
#include "CCC.hpp"

// Simple complex number class                                                                                                                                                                          
class complex
{
private:
  double real;  // Real Part
  double imag;      //  Imaginary Part                                                                                                       
public:
  complex();
  complex(double);
  complex(double,double);
  complex(const complex&);
  complex(gmp_CC);
  complex operator +(complex);
  complex operator -(complex);
  complex operator -() const;
  complex operator *(complex);
  complex operator /(complex);
  complex& operator +=(const complex);
  complex getconjugate() const;
  complex getreciprocal();
  double getmodulus();
  double getreal();
  double getimaginary();
  bool operator ==(complex);
  void operator =(complex);
  void sprint(char*);
};

//                                        CONSTRUCTOR
inline  complex::complex() { }

inline complex::complex(double r)
{
  real=r;
  imag=0;
}

inline complex::complex(double r, double im)
{
  real=r;
  imag=im;
}
 
//                                 COPY CONSTRUCTOR
inline complex::complex(const complex &c)
{
  this->real=c.real;
  this->imag=c.imag;
}
 
inline complex::complex(gmp_CC mpfrCC)
{
  real = mpfr_get_d(mpfrCC->re,GMP_RNDN);
  imag = mpfr_get_d(mpfrCC->im,GMP_RNDN);
}
 
inline void complex::operator =(complex c)
{
  real=c.real;
  imag=c.imag;
}
 
 
inline complex complex::operator +(complex c)
{
  complex tmp;
  tmp.real=this->real+c.real;
  tmp.imag=this->imag+c.imag;
  return tmp;
}

inline complex& complex::operator +=(const complex c)
{
  this->real+=c.real;
  this->imag+=c.imag;
  return *this;
}
 
inline complex complex::operator -(complex c)
{
  complex tmp;
  tmp.real=this->real - c.real;
  tmp.imag=this->imag - c.imag;
  return tmp;
}

inline complex complex::operator -() const
{
  complex tmp;
  tmp.real=-this->real;
  tmp.imag=-this->imag;
  return tmp;
}
 
inline complex complex::operator *(complex c)
{
  complex tmp;
  tmp.real=(real*c.real)-(imag*c.imag);
  tmp.imag=(real*c.imag)+(imag*c.real);
  return tmp;
}
 
inline complex complex::operator /(complex c)
{
  double div=(c.real*c.real) + (c.imag*c.imag);
  complex tmp;
  tmp.real=(real*c.real)+(imag*c.imag);
  tmp.real/=div;
  tmp.imag=(imag*c.real)-(real*c.imag);
  tmp.imag/=div;
  return tmp;
}
 
inline complex complex::getconjugate() const
{
  complex tmp;
  tmp.real=this->real;
  tmp.imag=this->imag * -1;
  return tmp;
}
 
inline complex complex::getreciprocal()
{
  complex t;
  t.real=real;
  t.imag=imag * -1;
  double div;
  div=(real*real)+(imag*imag);
  t.real/=div;
  t.imag/=div;
  return t;
}
 
inline double complex::getmodulus()
{
  double z;
  z=(real*real)+(imag*imag);
  z=sqrt(z);
  return z;
}
 
inline double complex::getreal()
{
  return real;
}
 
inline double complex::getimaginary()
{
  return imag;
}
 
inline bool complex::operator ==(complex c)
{
  return (real==c.real)&&(imag==c.imag) ? 1 : 0;
}

inline void complex::sprint(char* s)
{
  sprintf(s, "(%lf) + i*(%lf)", real, imag);
}


template <class Field>
void zero_complex_array(int n, typename Field::element_type* a)
{
  for (int i=0; i<n; i++,a++)
    *a=0.;
}

template <class Field>
void copy_complex_array(int n, const typename Field::element_type* a, typename Field::element_type* b)
{
  for (int i=0; i<n; i++,a++,b++)
    *b = *a;
}

template <class Field>
typename Field::element_type* make_copy_complex_array(int n, const typename Field::element_type* a)
{
  typename Field::element_type* b = newarray_atomic(typename Field::element_type, n);
  for (int i=0; i<n; i++,a++)
    b[i] = *a;
  return b;
}


template <class Field>
void multiply_complex_array_scalar(int n, typename Field::element_type* a, const typename Field::element_type b)
{
  for (int i=0; i<n; i++,a++)
    *a = *a * b; 
} 

template <class Field>
void add_to_complex_array(int n, typename Field::element_type* a, const typename Field::element_type* b)
{
  for (int i=0; i<n; i++,a++)
    *a = *a + b[i]; 
} 

template <class Field>
void negate_complex_array(int n, typename Field::element_type* a)
{
  for (int i=0; i<n; i++,a++)
    *a = -*a; 
} 

template <class Field>
double norm2_complex_array(int n, typename Field::element_type* a) // square of 2-norm
{
  double t = 0;
  for (int i=0; i<n; i++,a++)
    t += a->getreal()*a->getreal()+a->getimaginary()*a->getimaginary();
  return t;
}

// see ../packages/NAG.m2 for the description of the structure of SLPs

#define libPREFIX "/tmp/slpFN."
#define slpCOMPILED 100
#define slpPREDICTOR 101
#define slpCORRECTOR 102
#define slpEND 0
#define slpCOPY 1
#define slpMULTIsum 2
#define slpPRODUCT 3

#define ZERO_CONST -1
#define ONE_CONST -2

// types of predictors
#define RUNGE_KUTTA 1
#define TANGENT 2
#define EULER 3
#define PROJECTIVE_NEWTON 4

#define MAX_NUM_SLPs 100
#define CONST_OFFSET 0x1000
#define SLP_HEADER_LEN 4

#define MAX_NUM_PATH_TRACKERS 10

/* Conventions in relative_position SLPs:
   nodes are refered via negative integers;
   i-th input --> i;
   i-th constant --> i + CONST_OFFSET. */

class ComplexField 
{
public:
  typedef complex element_type;
};


#if 0
class StraightLineProgram : public mutable_object {
public:
  StraightLineProgram(const Ring *R) : R_(R) {}

  static StraightLineProgram /* or null */ *make(const PolyRing* R, ring_elem e);
  static StraightLineProgram /* or null */ *make(const Matrix *consts, M2_arrayint program);
  
  virtual StraightLineProgram /* or null */ *concatenate(const StraightLineProgram* slp) = 0;

  virtual StraightLineProgram /* or null */ *jacobian(bool makeHxH, 
						      StraightLineProgram *&slpHxH, 
						      bool makeHxtH, 
						      StraightLineProgram *&slpHxtH) = 0;

  virtual StraightLineProgram /* or null */ *copy() = 0;

  virtual void text_out(buffer& o) const = 0;

  //void stats_out(buffer& o) const;

  virtual void evaluate(int n, const element_type* values, element_type* out) = 0;

  virtual Matrix* evaluate(const Matrix *vals) = 0;
protected:
  const Ring *R_;
};
#endif

template <class Field>
class SLP : public object
{
  Field F; // F->add(a,b,c)
public:
  typedef typename Field::element_type element_type;
private:
  friend class PathTracker;

  static SLP<Field>* catalog[MAX_NUM_SLPs];
  static int num_slps;

  bool is_relative_position; // can use relative or absolute addressing
  M2_arrayint program;
  element_type* nodes; // array of CCs
  intarray node_index; // points to position in program (rel. to start) of operation correspoding to a node
  int num_consts, num_inputs, num_operations, rows_out, cols_out;

  void *handle; //dynamic library handle
  void (*compiled_fn)(element_type*,element_type*);
  clock_t eval_time; // accumulates time spent in evaluation 
  int n_calls; // number of times called   

  SLP();

  int poly_to_horner_slp(int n, intarray& prog, array<element_type>& consts, Nterm *&f); // used by make

  int diffNodeInput(int n, int v, intarray& prog); // used by jacobian
  int diffPartReference(int n, int ref, int v, intarray& prog); // used by diffNodeInput

  /* obsolete!!!
  void predictor(); // evaluates a predictor
  void corrector(); // evaluates a corrector
  */

  void relative_to_absolute(int& aa, int cur_node) // used by convert_to_absolute_position     
  { 
    if (aa<0) aa = cur_node + aa;
    else if (aa<CONST_OFFSET) aa = num_consts+aa; // an input
    else aa -= CONST_OFFSET; // a constant
  }
  void convert_to_absolute_position();

public:
  SLP<Field> /* or null */ *copy();
  SLP<Field> /* or null */ *jacobian(bool makeHxH, SLP<Field> *&slpHxH, bool makeHxtH, SLP<Field> *&slpHxtH);
  SLP<Field> /* or null */ *concatenate(const SLP<Field>* slp);
  static SLP<Field> /* or null */ *make(const PolyRing*, ring_elem);
  static SLP<Field> /* or null */ *make(const Matrix *consts, M2_arrayint program);
  virtual ~SLP();

  void text_out(buffer& o) const;
  void stats_out(buffer& o) const;
  void evaluate(int n, const element_type* values, element_type* out);
  Matrix* evaluate(const Matrix *vals);
};

class StraightLineProgram : public SLP<ComplexField> {
public:
  static StraightLineProgram /* or null */ *make(const PolyRing* R, ring_elem e);
  static StraightLineProgram /* or null */ *make(const Matrix *consts, M2_arrayint program);
  
  StraightLineProgram /* or null */ *concatenate(const StraightLineProgram* slp) { return static_cast<StraightLineProgram*>(SLP<ComplexField>::concatenate(slp)); }

  StraightLineProgram /* or null */ *jacobian(bool makeHxH, StraightLineProgram *&slpHxH, bool makeHxtH, StraightLineProgram *&slpHxtH) {
    SLP<ComplexField> *SLP1, *SLP2;  
    StraightLineProgram* ret =  static_cast<StraightLineProgram*>(SLP<ComplexField>::jacobian(makeHxH, SLP1, makeHxtH, SLP2));
    slpHxH = static_cast<StraightLineProgram*> (SLP1);
    slpHxtH = static_cast<StraightLineProgram*> (SLP2);
    return ret;
  }

  StraightLineProgram /* or null */ *copy() { return static_cast<StraightLineProgram*>(SLP<ComplexField>::copy()); }

  void text_out(buffer& o) const;
  //void stats_out(buffer& o) const;
  void evaluate(int n, const element_type* values, element_type* out);
  Matrix* evaluate(const Matrix *vals);
};
			    
//typedef SLP<ComplexField> StraightLineProgram; 

enum SolutionStatus {UNDETERMINED, PROCESSING, REGULAR, SINGULAR, INFINITY_FAILED, MIN_STEP_FAILED};
struct Solution
{
  int n; // number of coordinates
  complex* x; // array of n coordinates
  double t; // last value of parameter t used
  complex* start_x; // start of the path that produced x 
  double cond; // reverse condition number of Hx
  SolutionStatus status;
  int num_steps; // number of steps taken along the path
  
  Solution() { status = UNDETERMINED; }
  void make(int m, const complex* s_s);
  ~Solution() { release(); }
  void release() { deletearray(x); deletearray(start_x); } 
};

class PathTracker : public object
{
  static PathTracker* catalog[MAX_NUM_PATH_TRACKERS];
  static int num_path_trackers;

  int number; // trackers are enumerated

  Matrix *target;
  const Matrix *H, *S, *T; // homotopy, start, target
  StraightLineProgram *slpH, *slpHxt, *slpHxtH, *slpHxH, // slps for evaluating H, H_{x,t}, H_{x,t}|H, H_{x}|H 
    *slpS, *slpSx, *slpSxS, *slpT, *slpTx, *slpTxT; // slps for S and T, needed if is_projective 
  double productST, // real part of the Bombieri-Weyl (hermitian) product <S,T>
    bigT; // length of arc between S and T 
  double* DMforPN; // multipliers used in ProjectiveNewton
  double maxDegreeTo3halves; // max(degree of equation)^{3/2}
  // inline functions needed by track
  void evaluate_slpHxt(int n, const complex* x0t0, complex* Hxt) {
    if (is_projective) {
      complex* SxS = newarray_atomic(complex, (n+1)*(n-1));
      complex* TxT = newarray_atomic(complex, (n+1)*(n-1));
      const complex *x0 = x0t0, *t0 = x0t0+n;
      const double t = (*(double *)t0)*bigT; //t0 should be real 
      slpSxS->evaluate(n,x0,SxS);
      slpTxT->evaluate(n,x0,TxT);
      double c = cos(t), s = sin(t), sqrt_one_minus_productST_2 = sqrt(1-productST*productST);
      double mS = c - productST*s/sqrt_one_minus_productST_2;
      double mT = s/sqrt_one_minus_productST_2;
      int j,i;
      for (j=0; j<n-1; j++) 
	for (i=0; i<n; i++) 
	  *(Hxt+i*n+j) = *(SxS+i*(n-1)+j) * mS + *(TxT+i*(n-1)+j) * mT;
      j = n-1; // last column
      for (i=0; i<n; i++)
	*(Hxt+i*n+j) = (x0+i)->getconjugate();
      i = n; // last row = H_t
      mS = -s - productST*c/sqrt_one_minus_productST_2;
      mT = c/sqrt_one_minus_productST_2;
      for (j=0; j<n-1; j++) {
	complex tt = *(SxS+i*(n-1)+j) * mS + *(TxT+i*(n-1)+j) * mT;
	*(Hxt+i*n+j) = tt;
      }
      *(Hxt+n*n+n-1) = complex(0.); // last row and column
      deletearray(SxS);
      deletearray(TxT);
    } else slpHxt->evaluate(n+1,x0t0, Hxt);
  }
  void evaluate_slpHxtH(int n, const complex* x0t0, complex* HxtH) {
    if (is_projective) ERROR("not implemented");
    else slpHxtH->evaluate(n+1,x0t0, HxtH);
  }
  void evaluate_slpHxH(int n, const complex* x0t0, complex* HxH) {
    if (is_projective) {
      complex* SxS = newarray_atomic(complex, (n+1)*(n-1));
      complex* TxT = newarray_atomic(complex, (n+1)*(n-1));
      const complex *x0 = x0t0, *t0 = x0t0+n;
      const double t = (*(double *)t0)*bigT; //t0 should be real 
      slpSxS->evaluate(n,x0,SxS);
      slpTxT->evaluate(n,x0,TxT);
      double c = cos(t), s = sin(t), sqrt_one_minus_productST_2 = sqrt(1-productST*productST);
      double mS = c - productST*s/sqrt_one_minus_productST_2;
      double mT = s/sqrt_one_minus_productST_2;
      int j,i;
      for (j=0; j<n-1; j++) 
	for (i=0; i<=n; i++) 
	  *(HxH+i*n+j) = *(SxS+i*(n-1)+j) * mS + *(TxT+i*(n-1)+j) * mT;
      j = n-1; // last column
      for (i=0; i<n; i++)
	*(HxH+i*n+j) = (x0+i)->getconjugate();
      *(HxH+n*n+n-1) = complex(0.); // last row and column
    } else slpHxH->evaluate(n+1,x0t0, HxH);
  }

  const CCC *C; // coefficient field (complex numbers)
  const PolyRing *homotopy_R; // polynomial ring where homotopy lives (does not include t if is_projective)
  int n_coords;
  int n_sols;
  Solution* raw_solutions; // solutions + stats
  Matrix *solutions; // Matrix of solutions passed to top level

  // parameters
  M2_bool is_projective;
  gmp_RR init_dt, min_dt;
  gmp_RR dt_increase_factor, dt_decrease_factor;
  int num_successes_before_increase;
  gmp_RR epsilon;
  int max_corr_steps;
  gmp_RR end_zone_factor;
  gmp_RR infinity_threshold;
  int pred_type;

  void make_slps(); // creates slpHxt and alpHxH

  PathTracker();
public:
  static PathTracker /* or null */ *make(const Matrix*); // from homotopy
  static PathTracker /* or null */ *make(const Matrix *S, const Matrix *T, gmp_RR productST); // from start/target systems
  static PathTracker /* or null */ *make(StraightLineProgram* slp_pred, StraightLineProgram* slp_corr); // precookedSLPs
  virtual ~PathTracker();

  void text_out(buffer& o) const;
  int makeFromHomotopy(const Matrix*);
  Matrix /* or null */* getSolution(int);
  Matrix /* or null */* getAllSolutions();
  int getSolutionStatus(int);
  int getSolutionSteps(int);
  gmp_RRorNull getSolutionLastT(int);
  gmp_RRorNull getSolutionRcond(int);
  int track(const Matrix*); 
  Matrix /* or null */* refine(const Matrix *sols, gmp_RR tolerance, int max_corr_steps_refine = 100); // refine solutions such that (error estimate)/norm(solution) < tolerance

  // raw "friends"
  friend void rawSetParametersPT(PathTracker* PT, M2_bool is_projective,
				 gmp_RR init_dt, gmp_RR min_dt, 
				 gmp_RR dt_increase_factor, gmp_RR dt_decrease_factor, int num_successes_before_increase,
				 gmp_RR epsilon, int max_corr_steps, gmp_RR end_zone_factor, gmp_RR infinity_threshold,
				 int pred_type);    
  friend const Matrix /* or null */ *rawTrackPaths(StraightLineProgram* slp_pred, StraightLineProgram* slp_corr, const Matrix* start_sols , 
				    M2_bool is_projective,
				    gmp_RR init_dt, gmp_RR min_dt, gmp_RR max_dt, 
				    gmp_RR dt_increase_factor, gmp_RR dt_decrease_factor, int num_successes_before_increase,
				    gmp_RR epsilon, int max_corr_steps,
				    int pred_type);  
};

// ------------ service functions --------------------------------------------------
int degree_ring_elem(const PolyRing* R, ring_elem re);
void print_complex_matrix(int size, const double* A);

#endif

// Local Variables:
// compile-command: "make -C $M2BUILDDIR/Macaulay2/e "
// End:
