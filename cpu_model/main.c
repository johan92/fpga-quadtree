#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <time.h>
#include <assert.h>
#include <unistd.h>

#define FLT_CNT (8192) 

uint32_t *left;
uint32_t *right;
uint32_t *keys;

uint32_t gl_verbose = 0;

#define MAX_RAND_VAL ( 1000000000 )

#define PRINT_STARTED()\
   do { \
    if(gl_verbose) { \
      printf("%s: started\n", __func__); \
    } \
  } while(0) \

#define PRINT_FINISHED()\
   do { \
    if(gl_verbose) { \
      printf("%s: finished\n", __func__); \
    } \
  } while(0) \

uint32_t get_rand()
{
  return rand() % ( MAX_RAND_VAL + 1 );
}

uint32_t get_rand_diap(uint32_t l, uint32_t r)
{
  return l + rand() % ( r - l );
}

int compare (const void * a, const void * b)
{
    return ( *(uint32_t*)a - *(uint32_t*)b );
}

void fill_left( uint32_t segments_cnt ) 
{
  PRINT_STARTED();

  int len = 0;
  
  while( len < segments_cnt ) {
    uint32_t r;
    r = get_rand();
    
    uint8_t got_match_flag = 0;
    for( int i = 0; i < len; i++ ) {
      if( left[i] == r ) {
        got_match_flag = 1;
        break;
      }
    }
    
    if( got_match_flag == 0 ) {
      left[len] = r;
      len++;
    }
  }
  
  PRINT_FINISHED();
}

void fill_right( uint32_t segments_cnt ) 
{
  PRINT_STARTED();

  for( uint32_t i = 0; i < segments_cnt; i++ ) {

    if( i == ( segments_cnt - 1 ) ) {
      right[i] = left[i];
    } else {
      
      if( left[i+1] == ( left[i] + 1 ) ) {
        right[i] = left[i];
      } else {
        right[i] = get_rand_diap(left[i], left[i+1]);
      }
    }

  }

  PRINT_FINISHED();
}

void fill_keys( uint32_t keys_cnt ) 
{
  PRINT_STARTED();

  for( uint32_t i = 0; i < keys_cnt; i++ ) {
    keys[i] = get_rand();
  }
  
  PRINT_FINISHED();
}

int binary_search( uint32_t *A, uint32_t key, int imin, int imax)
{
  int imid;
  // continue searching while [imin,imax] is not empty
  while (imax >= imin)
  {
    // calculate the midpoint for roughly equal partition
    imid = imin + (imax - imin)/2;
    //printf("%u %u %u\n", imin, imid, imax);
    if(A[imid] == key)
      // key found at index imid
      return imid; 
    // determine which subarray to search
    else if (A[imid] < key)
      // change min index to search upper subarray
      imin = imid + 1;
    else         
      // change max index to search lower subarray
      imax = imid - 1;
  }
  
  if( imid != 0 ){
    if( ( A[ imid - 1 ] < key ) && ( A[imid] > key ) ){
      imid = imid - 1;
    }
  }
  // key was not found
  return imid;
}

int32_t fast_search_key( uint32_t key, uint32_t segments_cnt )
{
  int idx;
  idx = binary_search( left, key, 0, ( segments_cnt - 1 ) );

  if( ( key >= left[idx] ) && ( key <= right[idx] ) ){
    return idx;
  } else {
    return -1;
  }
}

int32_t slow_search_key( uint32_t key, uint32_t segments_cnt )
{
  for( uint32_t i = 0; i < segments_cnt; i++ ) {
    if( ( key >= left[i] ) && ( key <= right[i] ) ) {
      return i;
    }
  }

  return -1;
}

void do_test_pre( uint32_t segments_cnt, uint32_t keys_cnt )
{
  PRINT_STARTED();

  srand(time(NULL));
  
  left = malloc( sizeof(uint32_t) * segments_cnt );

  if( !left ){
    fprintf(stderr, "no mem!");
    exit(1);
  }

  right = malloc( sizeof(uint32_t) * segments_cnt );
  if( !right ){
    fprintf(stderr, "no mem!");
    exit(1);
  }
  
  keys = malloc( sizeof(uint32_t) * keys_cnt );
  if( !keys ){
    fprintf(stderr, "no mem!");
    exit(1);
  }
  
  fill_left(segments_cnt);
  qsort( left, segments_cnt, sizeof(uint32_t), compare );
  
  fill_right(segments_cnt);
  fill_keys(keys_cnt);
  
  PRINT_FINISHED();
}

void do_test_post()
{
  free(left);
  free(right);
  free(keys);
}

double do_test( uint32_t segments_cnt, uint32_t keys_cnt, uint32_t do_check )
{
  PRINT_STARTED(); 
  
  do_test_pre(segments_cnt, keys_cnt);

  volatile int32_t r1;
  volatile int32_t r2;
  
  struct timespec tstart={0,0}, tend={0,0};
  clock_gettime(CLOCK_MONOTONIC, &tstart);

  for( uint32_t i = 0; i < keys_cnt; i++ ) {
    uint32_t k  = keys[i];
    r1 = fast_search_key( k, segments_cnt );

    if(do_check) {
      r2 = slow_search_key( k, segments_cnt ); 
      if(r1 != r2) {
        printf("Check failed: i = %u k = %u r1 = %d r2 = %d\n", i, k, r1, r2);
      }
    }
  }
  clock_gettime(CLOCK_MONOTONIC, &tend);
  
  double test_time_sec;
  test_time_sec = ((double)tend.tv_sec   + 1.0e-9*tend.tv_nsec  ) - 
                  ((double)tstart.tv_sec + 1.0e-9*tstart.tv_nsec);

  
  do_test_post();
  
  PRINT_FINISHED(); 

  return test_time_sec;
}

int main(int argc, char** argv)
{
  left  = NULL;
  right = NULL;
  keys  = NULL;
  
  // set default values
  uint32_t segments_cnt = 8192;
  uint32_t keys_cnt     = 10000000;
  uint32_t tests_cnt    = 3;
  uint32_t do_check     = 0;

  const char *help_str = "-s segments_cnt -k keys_cnt -t tests_cnt [-h] [-v] [-c]";

  char c;
  while ((c = getopt(argc, argv, "s:k:t:hvc")) != -1) {
    switch(c) {
      case 's': segments_cnt = atoi(optarg); break;      
      case 'k': keys_cnt     = atoi(optarg); break;      
      case 't': tests_cnt    = atoi(optarg); break;      
      case 'h': printf("Usage: %s %s\n", argv[0], help_str); return 0;
      case 'v': gl_verbose = 1; break;
      case 'c': do_check   = 1; break; 
      default : abort();
    }
  }
  
  printf("Parameters: segments_cnt = %u keys_cnt = %u tests_cnt = %u gl_verbose = %u do_check = %u\n", 
                      segments_cnt,     keys_cnt,     tests_cnt,     gl_verbose,     do_check );

  for( uint32_t t = 0; t < tests_cnt; t++ ) {
    double test_time_sec = do_test(segments_cnt, keys_cnt, do_check);
    printf("Test %3d: time %.5f seconds\n", t, test_time_sec );
  }

  return 0;
}

