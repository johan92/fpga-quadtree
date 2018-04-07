#!/usr/bin/python
import random

class Segment():

    def __init__(self):
        self.l = None
        self.r = None

    def __str__(self):
        return str((self.l,self.r))

class SegmentGenerator():
    def __init__(self, min_value, max_value, level_cnt, cell_cnt):
        self.min_value = min_value
        self.max_value = max_value
        self.level_cnt = level_cnt
        self.cell_cnt  = cell_cnt

        self.max_segments = pow(2, (self.level_cnt + 1)*2) * self.cell_cnt
        self.segments = []

    def generate(self, segments_cnt):
        assert(segments_cnt <= self.max_segments)
        assert(segments_cnt <= (self.max_value - self.min_value + 1))

        left_points = set()

        while len(left_points) != segments_cnt:
            left_points.add(random.randrange(self.min_value, self.max_value + 1))

        left_points = sorted(list(left_points))
        print left_points

        assert(len(left_points) == segments_cnt)

        for (i,p) in enumerate(left_points):
            s = Segment()
            s.l = p

            max_r = self.max_value

            # not last point
            if i != segments_cnt - 1:
                max_r = left_points[i+1]

            s.r = random.randrange(s.l, max_r + 1)

            self.segments.append(s)

    def print_segments(self):
        for s in self.segments:
            print s

    def write(self, fname):            
        f = open(fname, "w")

        for s in self.segments:
            wr_str = "%d %d\n" % (s.l, s.r)
            f.write(wr_str)

        f.close()

class LookupDataGenerator():

    def __init__(self, min_value, max_value):
        self.min_value = min_value
        self.max_value = max_value

        self.lookup_data = []

    def generate(self, cnt):
        for i in xrange(cnt):
            self.lookup_data.append(random.randrange(self.min_value, self.max_value + 1))

    def write(self, fname):
        f = open(fname, "w")

        for d in self.lookup_data:
            wr_str = "%d\n" % (d)
            f.write(wr_str)

        f.close()

if __name__ == "__main__":
    sg = SegmentGenerator(0, 255, level_cnt = 5, cell_cnt = 4)
    lg = LookupDataGenerator(0, 255)
    
    sg.generate(100)
    lg.generate(20)

    sg.write("test_02_segments")
    lg.write("test_02_lookup_data")
