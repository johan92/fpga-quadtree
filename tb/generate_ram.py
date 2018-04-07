#!/usr/bin/python
import sys

class Segment():

    def __init__(self, l, r, do_check = True):
        assert(isinstance(l, int))
        assert(isinstance(r, int))

        self.l = l
        self.r = r

        if do_check:
            assert(self.l <= self.r)

    def __str__(self):
        a = (self.l, self.r)
        return str(a)

class SegmentArray():

    def __init__(self):
        self.array = []

    def add(self, s):
        last_segment = None

        if self.array:
            last_segment = self.array[-1]

        if last_segment is not None:
            assert(last_segment.r < s.l)

        self.array.append(s)

class InSegments():

    def __init__(self, fname):
        self.segments = SegmentArray()
        self.parse(fname)

    def parse(self, fname):

        with open(fname) as f:
            for line in f:
                l_split = line.rsplit()
                print l_split
                s = Segment(int(l_split[0]), int(l_split[1]))

                self.segments.add(s)

class QTreeRamGenerator():
    MIN_VALUE = 0
    MAX_VALUE = pow(2,8) - 1

    def __init__(self, levels, cell_cnt, segments):
        self.levels = levels
        self.cell_cnt = cell_cnt
        self.segments = segments

        self.LAST_TABLE_ADDR_CNT = pow(4, self.levels) 
        self.MAX_HOLD_DATA_CNT   = self.LAST_TABLE_ADDR_CNT * self.cell_cnt

        self.check_segments()
        self.create_match_ram()
        self.create_levels_ram()
    
    def check_value(self, v):
        good = True
        good &= self.MIN_VALUE <= v
        good &= v <= self.MAX_VALUE
        return good

    def check_segments(self):
        for s in self.segments.array:
            assert(self.check_value(s.l))
            assert(self.check_value(s.r))

        assert(len(self.segments.array) <= self.MAX_HOLD_DATA_CNT)
    
    def prepare_levels_ram(self):
        self.levels_ram = []

        for i in xrange(self.levels):
            self.levels_ram.append(list())

            for j in xrange(pow(4,i)):
                self.levels_ram[i].append( [self.MAX_VALUE, self.MAX_VALUE, self.MAX_VALUE])

    def create_levels_ram(self):
        self.prepare_levels_ram()

        for level_num in reversed(xrange(self.levels)):
          if level_num == (self.levels-1):
            for (i, row) in enumerate(self.match_ram):
              if i % 4 != 3:
                # max value in last bucket
                s = row[self.cell_cnt-1]
                print level_num, i/4, i%4
                self.levels_ram[ level_num ][i/4][i%4] = s.l
          else:
            for (i, row) in enumerate(self.levels_ram[ level_num + 1 ]):
              if i % 4 != 3:
                m = row[2]
                self.levels_ram[ level_num ][ i / 4 ][ i % 4 ] = m

    def prepare_match_ram(self):
        self.match_ram = []

        for i in xrange( self.LAST_TABLE_ADDR_CNT ):
            self.match_ram.append(list())

            for j in xrange(self.cell_cnt):
                s = Segment(self.MAX_VALUE, self.MIN_VALUE, do_check = False)
                self.match_ram[i].append( s )

    def create_match_ram(self):
        self.prepare_match_ram()

        for (i, s) in enumerate(self.segments.array):
            addr = i / self.cell_cnt
            pos  = i % self.cell_cnt
            print addr, pos
            self.match_ram[addr][pos] = s

    def write_level_ram(self, fname):
      f = open( fname, "w" )

      for (i, level) in enumerate(self.levels_ram):
          for (addr, data) in enumerate( level ):
              wr_str = str(i) + " " + str( addr )
              for d in data:
                  wr_str = wr_str + " " + str( d )
              f.write("%s\n" % wr_str)

      f.close()

    def write_match_ram(self, fname):
      f = open( fname, "w" )
      
      for (addr, row) in enumerate(self.match_ram):
          for (i, s) in enumerate( row ):
              wr_str = str(addr) + " " + str(i) + " " + str(s.l) + " " + str(s.r)
              f.write("%s\n" % wr_str)

      f.close()

if __name__ == "__main__":
    in_fname = sys.argv[1]

    in_data = InSegments(in_fname)
    ram_gen = QTreeRamGenerator(levels = 5, cell_cnt = 4, segments = in_data.segments)
    ram_gen.write_level_ram(in_fname + "_level_ram")
    ram_gen.write_match_ram(in_fname + "_match_ram")
