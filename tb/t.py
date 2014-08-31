import random

def write_stages( stages_l, fname ):
  f = open( fname, "w" )
  for (i, stage) in enumerate( stages_l ):
    for (addr, data) in enumerate( stage ):
      wr_str = str(i) + " " + str( addr )
      for d in data:
        wr_str = wr_str + " " + str( d )
      f.write("%s\n" % wr_str)

  f.close()

def write_table( table_l, fname ):
  f = open( fname, "w" )
  
  for (addr, row) in enumerate( table_l ):
    for (i, d) in enumerate( row ):
      (val, en) = d
      if en == True:
        wr_str = str(addr) + " " + str(i) + " " + str(val)
        f.write("%s\n" % wr_str)

  f.close()


if __name__ == "__main__":
  STAGES              = 4 
  D_CNT               = 4
  MAX_NUM             = 255 
  TOTAL_NUMS          = 101
  LAST_TABLE_ADDR_CNT = pow(4, STAGES) 
  MAX_HOLD_DATA_CNT   = LAST_TABLE_ADDR_CNT * 4

  print "maximum data %d" % ( MAX_HOLD_DATA_CNT )

  all_nums_s          = set()
  all_nums_l          = list()

  while ( len( all_nums_s ) < TOTAL_NUMS ) and ( len( all_nums_s ) < MAX_HOLD_DATA_CNT ):
    r = random.randint(0, MAX_NUM)
    all_nums_s.add( r )

  all_nums_l = list( sorted( all_nums_s ) )

  print all_nums_l
  
  match_table = list()
  for i in xrange( LAST_TABLE_ADDR_CNT ):
    match_table.append( list() )
    for j in xrange( D_CNT ):
      match_table[i].append( ( MAX_NUM, False ) ) 
  
  for (i, n) in enumerate( all_nums_l ):
    addr = i / D_CNT
    pos  = i % D_CNT
    match_table[addr][pos] = ( n, True )

  for i in match_table:
    print i
  
  stages_l = list()
  for i in xrange( STAGES ):
    stages_l.append( list() )
    for j in xrange( pow(4, i ) ):
      stages_l[i].append( [MAX_NUM, MAX_NUM, MAX_NUM] )
  
  print stages_l

  for stage in reversed( xrange( STAGES ) ):
    if stage == ( STAGES - 1 ):
      for (i, row) in enumerate( match_table ):
        if i % 4 != 3:
          # max value in last bucket
          (m, en) = row[D_CNT-1]
          #print stage, i/4, i%4
          stages_l[ stage ][i/4][i%4] = m
    else:
      for (i, row) in enumerate( stages_l[ stage + 1 ] ):
        if i % 4 != 3:
          m = row[2]
          stages_l[ stage ][ i / 4 ][ i % 4 ] = m
 
  write_stages( stages_l, "tree" )
  write_table( match_table, "table" )
