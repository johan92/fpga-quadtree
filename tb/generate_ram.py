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

    def __init__(self, stages, d_cnt, segments):
        self.stages = stages
        self.d_cnt = d_cnt
        self.segments = segments

        self.LAST_TABLE_ADDR_CNT = pow(4, self.stages) 
        self.MAX_HOLD_DATA_CNT   = self.LAST_TABLE_ADDR_CNT * self.d_cnt

        self.check_segments()
        self.create_match_ram()
        self.create_stages_ram()
    
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
    
    def prepare_stages_ram(self):
        self.stages_ram = []

        for i in xrange(self.stages):
            self.stages_ram.append(list())

            for j in xrange(pow(4,i)):
                self.stages_l.append( [self.MAX_VALUE, self.MAX_VALUE, self.MAX_VALUE])

    def create_stages_ram(self):
        self.prepare_stages_ram()


    def prepare_match_ram(self):
        self.match_ram = []

        for i in xrange( self.LAST_TABLE_ADDR_CNT ):
            self.match_ram.append(list())

            for j in xrange(self.d_cnt):
                s = Segment(self.MAX_VALUE, self.MIN_VALUE)
                self.match_ram.append( s )

    def create_match_ram(self):
        self.prepare_match_ram()

        for (i, s) in enumerate(self.segments.array):
            addr = i / self.d_cnt
            pos  = i % self.d_cnt
            self.match_ram[addr][pos] = s


if __name__ == "__main__":
    in_fname = sys.argv[1]

    in_data = InSegments(in_fname)
