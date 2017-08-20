/**
 *  MIT License
 *
 *  Copyright (c) 2017 Richard Moore <me@ricmoo.com>
 *
 *  Permission is hereby granted, free of charge, to any person obtaining
 *  a copy of this software and associated documentation files (the
 *  "Software"), to deal in the Software without restriction, including
 *  without limitation the rights to use, copy, modify, merge, publish,
 *  distribute, sublicense, and/or sell copies of the Software, and to
 *  permit persons to whom the Software is furnished to do so, subject to
 *  the following conditions:
 *
 *  The above copyright notice and this permission notice shall be included
 *  in all copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 *  OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 *  THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 *  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 *  DEALINGS IN THE SOFTWARE.
 */

#import "ethers.h"


/**
 *  The following functions and utilities are from ENT, which is in the public domain.
 *  Thanks to John Walker.
 *
 *  See: http://www.fourmilab.ch/random/
 *   <ENT>
 */

// @TODO: Wrap this up in some nice Objective-C class

#define FALSE 0
#define TRUE  1

#ifdef M_PI
#define PI	 M_PI
#else
#define PI	 3.14159265358979323846
#endif


#pragma mark -
#pragma mark - iso8859.h


/* ISO 8859/1 Latin-1 "ctype" macro replacements. */

extern unsigned char isoalpha[32], isoupper[32], isolower[32];

#define isISOspace(x)	((isascii(((unsigned char) (x))) && isspace(((unsigned char) (x)))) || ((x) == 0xA0))
#define isISOalpha(x)	((isoalpha[(((unsigned char) (x))) / 8] & (0x80 >> ((((unsigned char) (x))) % 8))) != 0)
#define isISOupper(x)	((isoupper[(((unsigned char) (x))) / 8] & (0x80 >> ((((unsigned char) (x))) % 8))) != 0)
#define isISOlower(x)	((isolower[(((unsigned char) (x))) / 8] & (0x80 >> ((((unsigned char) (x))) % 8))) != 0)
#define isISOprint(x)   ((((x) >= ' ') && ((x) <= '~')) || ((x) >= 0xA0))
#define toISOupper(x)   (isISOlower(x) ? (isascii(((unsigned char) (x))) ?  \
toupper(x) : (((((unsigned char) (x)) != 0xDF) && \
(((unsigned char) (x)) != 0xFF)) ? \
(((unsigned char) (x)) - 0x20) : (x))) : (x))
#define toISOlower(x)   (isISOupper(x) ? (isascii(((unsigned char) (x))) ?  \
tolower(x) : (((unsigned char) (x)) + 0x20)) \
: (x))


#pragma mark -
#pragma mark - iso8859.c

///////////////////////////////////
// iso8859.c

/* ISO 8859/1 Latin-1 alphabetic and upper and lower case bit vector tables. */

/* LINTLIBRARY */

unsigned char isoalpha[32] = {
    0,0,0,0,0,0,0,0,127,255,255,224,127,255,255,224,0,0,0,0,0,0,0,0,255,255,
    254,255,255,255,254,255
};

unsigned char isoupper[32] = {
    0,0,0,0,0,0,0,0,127,255,255,224,0,0,0,0,0,0,0,0,0,0,0,0,255,255,254,254,
    0,0,0,0
};

unsigned char isolower[32] = {
    0,0,0,0,0,0,0,0,0,0,0,0,127,255,255,224,0,0,0,0,0,0,0,0,0,0,0,1,255,255,
    254,255
};


#pragma mark -
#pragma mark - chisq.c

///////////////////////////////////
// chisq.c

/*
 
 Compute probability of measured Chi Square value.
 
 This code was developed by Gary Perlman of the Wang
 Institute (full citation below) and has been minimally
 modified for use in this program.
 
 */

#include <math.h>

/** HEADER
	Module:       z.c
	Purpose:      compute approximations to normal z distribution probabilities
	Programmer:   Gary Perlman
	Organization: Wang Institute, Tyngsboro, MA 01879
	Copyright:    none
	Tabstops:     4
 */

#define	Z_MAX          6.0            /* maximum meaningful z value */

/*FUNCTION poz: probability of normal z value */
/*ALGORITHM
	Adapted from a polynomial approximation in:
 Ibbetson D, Algorithm 209
 Collected Algorithms of the CACM 1963 p. 616
	Note:
 This routine has six digit accuracy, so it is only useful for absolute
 z values < 6.  For z values >= to 6.0, poz() returns 0.0.
 */
static double        /*VAR returns cumulative probability from -oo to z */
poz(const double z)  /*VAR normal z value */
{
    double y, x, w;
    
    if (z == 0.0) {
        x = 0.0;
    } else {
        y = 0.5 * fabs(z);
        if (y >= (Z_MAX * 0.5)) {
            x = 1.0;
        } else if (y < 1.0) {
            w = y * y;
            x = ((((((((0.000124818987 * w
                        -0.001075204047) * w +0.005198775019) * w
                      -0.019198292004) * w +0.059054035642) * w
                    -0.151968751364) * w +0.319152932694) * w
                  -0.531923007300) * w +0.797884560593) * y * 2.0;
        } else {
            y -= 2.0;
            x = (((((((((((((-0.000045255659 * y
                             +0.000152529290) * y -0.000019538132) * y
                           -0.000676904986) * y +0.001390604284) * y
                         -0.000794620820) * y -0.002034254874) * y
                       +0.006549791214) * y -0.010557625006) * y
                     +0.011630447319) * y -0.009279453341) * y
                   +0.005353579108) * y -0.002141268741) * y
                 +0.000535310849) * y +0.999936657524;
        }
    }
    return (z > 0.0 ? ((x + 1.0) * 0.5) : ((1.0 - x) * 0.5));
}

/*
	Module:       chisq.c
	Purpose:      compute approximations to chisquare distribution probabilities
	Contents:     pochisq()
	Uses:         poz() in z.c (Algorithm 209)
	Programmer:   Gary Perlman
	Organization: Wang Institute, Tyngsboro, MA 01879
	Copyright:    none
	Tabstops:     4
 */

#define	LOG_SQRT_PI     0.5723649429247000870717135 /* log (sqrt (pi)) */
#define	I_SQRT_PI       0.5641895835477562869480795 /* 1 / sqrt (pi) */
#define	BIGX           20.0         /* max value to represent exp (x) */
#define	ex(x)             (((x) < -BIGX) ? 0.0 : exp(x))

/*FUNCTION pochisq: probability of chi sqaure value */
/*ALGORITHM Compute probability of chi square value.
	Adapted from:
 Hill, I. D. and Pike, M. C.  Algorithm 299
 Collected Algorithms for the CACM 1967 p. 243
	Updated for rounding errors based on remark in
 ACM TOMS June 1985, page 185
 */

double pochisq(
               const double ax,    /* obtained chi-square value */
               const int df	    /* degrees of freedom */
)
{
    double x = ax;
    double a, y, s;
    double e, c, z;
    int even;	    	    /* true if df is an even number */
    
    if (x <= 0.0 || df < 1) {
        return 1.0;
    }
    
    a = 0.5 * x;
    even = (2 * (df / 2)) == df;
    if (df > 1) {
        y = ex(-a);
    }
    s = (even ? y : (2.0 * poz(-sqrt(x))));
    if (df > 2) {
        x = 0.5 * (df - 1.0);
        z = (even ? 1.0 : 0.5);
        if (a > BIGX) {
            e = (even ? 0.0 : LOG_SQRT_PI);
            c = log(a);
            while (z <= x) {
                e = log(z) + e;
                s += ex(c * z - a - e);
                z += 1.0;
            }
            return (s);
        } else {
            e = (even ? 1.0 : (I_SQRT_PI / sqrt(a)));
            c = 0.0;
            while (z <= x) {
                e = e * (a / z);
                c = c + e;
                z += 1.0;
            }
            return (c * y + s);
        }
    } else {
        return s;
    }
}


#pragma mark -
#pragma mark - randtest.c

///////////////////////////////////
// randtest.c

/*
 
 Apply various randomness tests to a stream of bytes
 
 by John Walker  --  September 1996
 http://www.fourmilab.ch/
 
 */

#include <math.h>

#define FALSE 0
#define TRUE  1

#define log2of10 3.32192809488736234787

static int randtest_binary = FALSE;	   /* Treat input as a bitstream */

static long randtest_ccount[256],	   /* Bins to count occurrences of values */
            randtest_totalc = 0; 	   /* Total bytes counted */
static double randtest_prob[256];	   /* Probabilities per bin for entropy */

/*  RT_LOG2  --  Calculate log to the base 2  */

static double rt_log2(double x)
{
    return log2of10 * log10(x);
}

#define MONTEN	6		      /* Bytes used as Monte Carlo
co-ordinates.	This should be no more
bits than the mantissa of your
"double" floating point type. */

static int randtest_mp, randtest_sccfirst;
static unsigned int randtest_monte[MONTEN];
static long randtest_inmont, randtest_mcount;
static double randtest_cexp, randtest_incirc, randtest_montex, randtest_montey, randtest_montepi,
randtest_scc, randtest_sccun, randtest_sccu0, randtest_scclast, randtest_scct1, randtest_scct2, randtest_scct3,
randtest_ent, randtest_chisq, randtest_datasum;

/*  RT_INIT  --  Initialise random test counters.  */

void rt_init(int binmode)
{
    int i;
    
    randtest_binary = binmode;	       /* Set binary / byte mode */
    
    /* Initialise for calculations */
    
    randtest_ent = 0.0;		       /* Clear entropy accumulator */
    randtest_chisq = 0.0;	       /* Clear Chi-Square */
    randtest_datasum = 0.0;	       /* Clear sum of bytes for arithmetic mean */
    
    randtest_mp = 0;		       /* Reset Monte Carlo accumulator pointer */
    randtest_mcount = 0; 	       /* Clear Monte Carlo tries */
    randtest_inmont = 0; 	       /* Clear Monte Carlo inside count */
    randtest_incirc = 65535.0 * 65535.0;/* In-circle distance for Monte Carlo */
    
    randtest_sccfirst = TRUE;	       /* Mark first time for serial correlation */
    randtest_scct1 = randtest_scct2 = randtest_scct3 = 0.0; /* Clear serial correlation terms */
    
    randtest_incirc = pow(pow(256.0, (double) (MONTEN / 2)) - 1, 2.0);
    
    for (i = 0; i < 256; i++) {
        randtest_ccount[i] = 0;
    }
    randtest_totalc = 0;
}

/*  RT_ADD  --	Add one or more bytes to accumulation.	*/

void rt_add(void *buf, int bufl)
{
    unsigned char *bp = buf;
    int oc, c, bean;
    
    while (bean = 0, (bufl-- > 0)) {
        oc = *bp++;
        
        do {
            if (randtest_binary) {
                c = !!(oc & 0x80);
            } else {
                c = oc;
            }
            randtest_ccount[c]++;		  /* Update counter for this bin */
            randtest_totalc++;
            
            /* Update inside / outside circle counts for Monte Carlo
             computation of PI */
            
            if (bean == 0) {
                randtest_monte[randtest_mp++] = oc;       /* Save character for Monte Carlo */
                if (randtest_mp >= MONTEN) {     /* Calculate every MONTEN character */
                    int mj;
                    
                    randtest_mp = 0;
                    randtest_mcount++;
                    randtest_montex = randtest_montey = 0;
                    for (mj = 0; mj < MONTEN / 2; mj++) {
                        randtest_montex = (randtest_montex * 256.0) + randtest_monte[mj];
                        randtest_montey = (randtest_montey * 256.0) + randtest_monte[(MONTEN / 2) + mj];
                    }
                    if ((randtest_montex * randtest_montex + randtest_montey *  randtest_montey) <= randtest_incirc) {
                        randtest_inmont++;
                    }
                }
            }
            
            /* Update calculation of serial correlation coefficient */
            
            randtest_sccun = c;
            if (randtest_sccfirst) {
                randtest_sccfirst = FALSE;
                randtest_scclast = 0;
                randtest_sccu0 = randtest_sccun;
            } else {
                randtest_scct1 = randtest_scct1 + randtest_scclast * randtest_sccun;
            }
            randtest_scct2 = randtest_scct2 + randtest_sccun;
            randtest_scct3 = randtest_scct3 + (randtest_sccun * randtest_sccun);
            randtest_scclast = randtest_sccun;
            oc <<= 1;
        } while (randtest_binary && (++bean < 8));
    }
}

/*  RT_END  --	Complete calculation and return results.  */

void rt_end(double *r_ent, double *r_chisq, double *r_mean,
            double *r_montepicalc, double *r_scc)
{
    int i;
    
    /* Complete calculation of serial correlation coefficient */
    
    randtest_scct1 = randtest_scct1 + randtest_scclast * randtest_sccu0;
    randtest_scct2 = randtest_scct2 * randtest_scct2;
    randtest_scc = randtest_totalc * randtest_scct3 - randtest_scct2;
    if (randtest_scc == 0.0) {
        randtest_scc = -100000;
    } else {
        randtest_scc = (randtest_totalc * randtest_scct1 - randtest_scct2) / randtest_scc;
    }
    
    /* Scan bins and calculate probability for each bin and
     Chi-Square distribution.  The probability will be reused
     in the entropy calculation below.  While we're at it,
     we sum of all the data which will be used to compute the
     mean. */
    
    randtest_cexp = randtest_totalc / (randtest_binary ? 2.0 : 256.0);  /* Expected count per bin */
    for (i = 0; i < (randtest_binary ? 2 : 256); i++) {
        double a = randtest_ccount[i] - randtest_cexp;;
        
        randtest_prob[i] = ((double) randtest_ccount[i]) / randtest_totalc;
        randtest_chisq += (a * a) / randtest_cexp;
        randtest_datasum += ((double) i) * randtest_ccount[i];
    }
    
    /* Calculate entropy */
    
    for (i = 0; i < (randtest_binary ? 2 : 256); i++) {
        if (randtest_prob[i] > 0.0) {
            randtest_ent += randtest_prob[i] * rt_log2(1 / randtest_prob[i]);
        }
    }
    
    /* Calculate Monte Carlo value for PI from percentage of hits
     within the circle */
    
    randtest_montepi = 4.0 * (((double) randtest_inmont) / randtest_mcount);
    
    /* Return results through arguments */
    
    *r_ent = randtest_ent;
    *r_chisq = randtest_chisq;
    *r_mean = randtest_datasum / randtest_totalc;
    *r_montepicalc = randtest_montepi;
    *r_scc = randtest_scc;
}


/**
 *   </ENT>
 */


#pragma mark -
#pragma mark - test_entropy

#import <XCTest/XCTest.h>

@interface test_entropy : XCTestCase

@end

@implementation test_entropy

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

// This test case fails too often and doesn't represent actual problems.
// The purpose is to convince ourselves the random number entropy is sound.
- (void)_deactivate_testEntropy {
    int i, oc, opt;
    long ccount[256];	      /* Bins to count occurrences of values */
    long totalc = 0;	      /* Total character count */
    char *samp;
    double montepi, chip,
    scc, ent, mean, chisq;
    //FILE *fp = stdin;
    int counts = FALSE,	      /* Print character counts */
    fold = FALSE,	      /* Fold upper to lower */
    binary = FALSE;	      /* Treat input as a bitstream */

    samp = binary ? "bit" : "byte";

    memset(ccount, 0, sizeof ccount);
    rt_init(binary);

    const NSInteger testCaseCount = 8192;

    NSMutableSet<NSData*> *entropies = [NSMutableSet setWithCapacity:testCaseCount];
    NSMutableSet<Address*> *addresses = [NSMutableSet setWithCapacity:testCaseCount];
    while (entropies.count < testCaseCount) {
        Account *account = [Account randomMnemonicAccount];

        // Make sure we never generate the same wallet twice
        XCTAssertTrue(![entropies containsObject:account.mnemonicData], @"Entropy ERROR: created same random account twice");
        [entropies addObject:account.mnemonicData];
        
        XCTAssertTrue(![addresses containsObject:account.address], @"Mnemonic ERROR: generated same wallet twice");
        [addresses addObject:account.address];
    }
    
    for (NSData *entropy in entropies) {
        const char* bytes = entropy.bytes;
        for (int bi = 0; bi < entropy.length; bi++) {
            oc = bytes[bi];

            unsigned char ocb;
            
            if (fold && isISOalpha(oc) && isISOupper(oc)) {
                oc = toISOlower(oc);
            }
            ocb = (unsigned char) oc;
            totalc += binary ? 8 : 1;
            if (binary) {
                int b;
                unsigned char ob = ocb;
                
                for (b = 0; b < 8; b++) {
                    ccount[ob & 1]++;
                    ob >>= 1;
                }
            } else {
                ccount[ocb]++;	      /* Update counter for this bin */
            }
            rt_add(&ocb, 1);
        }
    }

    /* Complete calculation and return sequence metrics */
    
    rt_end(&ent, &chisq, &mean, &montepi, &scc);
    
    /* Calculate probability of observed distribution occurring from
     the results of the Chi-Square test */
    
    chip = pochisq(chisq, (binary ? 1 : 255));
    
    /* Print bin counts if requested */
    
    if (counts) {
        printf("Value Char Occurrences Fraction\n");
        for (i = 0; i < (binary ? 2 : 256); i++) {
            if (ccount[i] > 0) {
                printf("%3d   %c   %10ld   %f\n", i,
                       /* The following expression shows ISO 8859-1
                        Latin1 characters and blanks out other codes.
                        The test for ISO space replaces the ISO
                        non-blanking space (0xA0) with a regular
                        ASCII space, guaranteeing it's rendered
                        properly even when the font doesn't contain
                        that character, which is the case with many
                        X fonts. */
                       (!isISOprint(i) || isISOspace(i)) ? ' ' : i,
                       ccount[i], ((double) ccount[i] / totalc));
            }
        }
        printf("\nTotal:    %10ld   %f\n\n", totalc, 1.0);
    }
    
    /* Print calculated results */
    NSLog(@"===========================");
    NSLog(@"ENTROPY ANALYSIS");
    NSLog(@"===========================");
    
    NSLog(@"Entropy: %f bits per %s.", ent, samp);
    NSLog(@"  - Ideal is 8.0");
    XCTAssertTrue(ent >= 7.98, @"Entropy Warning: low entropy");
    
    short compressPercent = (short)((100 * ((binary ? 1 : 8) - ent) / (binary ? 1.0 : 8.0)));
    NSLog(@"Optimum compression would reduce the size of this %ld %s file by %d percent.", totalc, samp, compressPercent);
    NSLog(@"  - Ideal is 0.0");
    XCTAssertTrue(compressPercent == 0, @"Entropy Warning: compressable");
    
    if (chip < 0.0001) {
        NSLog(@"Chi square distribution for %ld samples is %1.2f: less than 0.01%%", totalc, chisq);
        NSLog(@"  - Ideal is 50%% (Anything above 90%% or below 10%% is a problem)");
        XCTAssertTrue(NO, @"Entropy ERROR: bad chi square");
    } else if (chip > 0.9999) {
        NSLog(@"Chi square distribution for %ld samples is %1.2f: more than than 99.99%%", totalc, chisq);
        NSLog(@"  - Ideal is 50%% (Anything above 90%% or below 10%% is a problem)");
        XCTAssertTrue(NO, @"Entropy ERROR: bad chi square");
    } else {
        NSLog(@"Chi square distribution for %ld samples is %1.2f: %1.2f%%", totalc, chisq, chip * 100);
        NSLog(@"  - Ideal is 50%% (Anything above 90%% or below 10%% is a problem)");
        if (chip > 0.9f || chip < 0.1f) {
            XCTAssertTrue(NO, @"Entropy ERROR: Bad chi square");
        } else if (chip > 0.87f || chip < 0.13f) {
            XCTAssertTrue(NO, @"Entropy Warning: suspect chi square");
        }
    }
    
    NSLog(@"Arithmetic mean value of data %ss is %1.4f (%.1f = random).", samp, mean, binary ? 0.5 : 127.5);
    NSLog(@"  - Ideal is 127.5");
    XCTAssertTrue(fabs(mean - 127.5) < 1.0f, @"Entropy Warning: biased mean");
    
    double deltaPi = fabs(PI - montepi) / PI;
    NSLog(@"Monte Carlo value for Pi is %1.9f, error: %1.2f%%", montepi, 100.0 * deltaPi);
    NSLog(@"  - Ideal is 0.0%%");
    XCTAssertTrue(fabs(deltaPi) < 1.3f, @"Entropy Warning: biased Monte Carlo");
    
    if (scc >= -99999) {
        NSLog(@"Serial correlation coefficient: %1.6f (totally uncorrelated = 0.0)", scc);
        NSLog(@"  - Ideal is 0");
        XCTAssertTrue(fabs(scc) < 0.02f, @"Entropy Warning: serial correlation");
    } else {
        NSLog(@"Serial correlation coefficient: undefined (all values equal!)");
        NSLog(@"  - Ideal is 0");
    }

    NSLog(@"===========================");
}


@end
