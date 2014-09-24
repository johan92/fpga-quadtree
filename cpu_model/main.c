#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <time.h>
#include <assert.h>

#define FLT_CNT (8192) 

uint32_t *left;
uint32_t *right;
uint32_t *keys;

#define MAX_RAND_VAL ( 1000000000 )
#define GET_RAND ( rand() % ( MAX_RAND_VAL + 1 ) )
#define GET_RAND_DIAP(l, r) ( l + rand() % ( r - l ) )

#define KEYS_CNT ( 15000000 )

int compare (const void * a, const void * b)
{
    return ( *(uint32_t*)a - *(uint32_t*)b );
}

void fill_left( ) {
  int i;
  int len = 0;
  printf("%s started.\n", __func__);
  while( len < FLT_CNT ){
    uint32_t r;
    r = GET_RAND;
    
    uint8_t got_match_flag = 0;
    for( i = 0; i < len; i++ ){
      if( left[i] == r ){
        got_match_flag = 1;
        break;
      }
    }
    
    if( got_match_flag == 0){
      left[len] = r;
      len++;
    }
  }
  printf("%s done.\n", __func__);
}

void fill_right( ) {
  int i;
  printf("%s started.\n", __func__);
  for( i = 0; i < FLT_CNT; i++ ){

    if( i == ( FLT_CNT - 1 ) ){
      right[i] = left[i];
    } else {
      
      if( left[i+1] == ( left[i] + 1 ) ){
        right[i] = left[i];
      } else {
        right[i] = GET_RAND_DIAP(left[i], left[i+1]);
      }
    }

  }
  printf("%s done.\n", __func__);
}

void fill_keys( ){
  printf("%s started.\n", __func__);
  int i;
  for( i = 0; i < KEYS_CNT; i++ ){
    keys[i] = GET_RAND;
  }

  printf("%s done.\n", __func__);
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

int fast_test_key( uint32_t key ){
  int idx;
  idx = binary_search( left, key, 0, ( FLT_CNT - 1 ) );

  if( ( key >= left[idx] ) && ( key <= right[idx] ) ){
    return idx;
  } else {
    return -1;
  }
}

int slow_test_key( uint32_t key ){
  int i;
  for( i = 0; i < FLT_CNT; i++ ){
    if( ( key >= left[i] ) && ( key <= right[i] ) ){
      //printf(">>>> %d %d %d\n", i, left[i], right[i]);
      return i;
    }

    if( key < left[i] ){
      return -1;
    }
  }
}

int main( ){

  printf("Initing all data...\n");
  left = malloc( sizeof(uint32_t) * FLT_CNT );

  if( !left ){
    fprintf(stderr, "no mem!");
    exit(1);
  }

  right = malloc( sizeof(uint32_t) * FLT_CNT );
  if( !right ){
    fprintf(stderr, "no mem!");
    exit(1);
  }
  
  keys = malloc( sizeof(uint32_t) * KEYS_CNT );
  if( !keys ){
    fprintf(stderr, "no mem!");
    exit(1);
  }

  int i;
  srand(time(NULL));
  
  fill_left();
  qsort( left, FLT_CNT, sizeof(uint32_t), compare );
  
  fill_right();
  fill_keys();

  volatile int r1;
  volatile int r2;
  uint32_t k;
  printf("Data is inited.\nStarting test...\n");

  struct timespec tstart={0,0}, tend={0,0};
  clock_gettime(CLOCK_MONOTONIC, &tstart);

  for( i = 0; i < KEYS_CNT; i++ ){
    k  = keys[i];
    r1 = fast_test_key( k ); 
    //r2 = slow_test_key( k ); 
    //printf(">>> %u %d %d\n", k, r1, r2);
    //assert( (r1 == r2) );
  }
  clock_gettime(CLOCK_MONOTONIC, &tend);

  printf("Test took about %.5f seconds\n",
      ((double)tend.tv_sec + 1.0e-9*tend.tv_nsec) - 
      ((double)tstart.tv_sec + 1.0e-9*tstart.tv_nsec));

  return 0;
}

