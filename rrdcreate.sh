#!/bin/bash

name="AABBCCDDEEFF"
path="/tmp"

rrdfile_temp="${path}/${name}_temp.rrd"
rrdfile_tdew="${path}/${name}_tdew.rrd"
rrdfile_rh="${path}/${name}_rh.rrd"
rrdfile_bat="${path}/${name}_bat.rrd"

# 5-minute interval for 30 days
# 15-minute interval for 1 year
# 1-hour interval for 3 years

rrdtool create $rrdfile_temp \
--start "now - 25h" \
--step 300 \
DS:value:GAUGE:600:-273:5000 \
RRA:AVERAGE:0.5:1:8640 \
RRA:MIN:0.5:3:35040 \
RRA:MAX:0.5:3:35040 \
RRA:AVERAGE:0.5:3:35040 \
RRA:MIN:0.5:12:26280 \
RRA:MAX:0.5:12:26280 \
RRA:AVERAGE:0.5:12:26280

rrdtool create $rrdfile_tdew \
--start "now - 25h" \
--step 300 \
DS:value:GAUGE:600:-273:5000 \
RRA:AVERAGE:0.5:1:8640 \
RRA:MIN:0.5:3:35040 \
RRA:MAX:0.5:3:35040 \
RRA:AVERAGE:0.5:3:35040 \
RRA:MIN:0.5:12:26280 \
RRA:MAX:0.5:12:26280 \
RRA:AVERAGE:0.5:12:26280

rrdtool create $rrdfile_rh \
--start "now - 25h" \
--step 300 \
DS:value:GAUGE:600:0:100 \
RRA:AVERAGE:0.5:1:8640 \
RRA:MIN:0.5:3:35040 \
RRA:MAX:0.5:3:35040 \
RRA:AVERAGE:0.5:3:35040 \
RRA:MIN:0.5:12:26280 \
RRA:MAX:0.5:12:26280 \
RRA:AVERAGE:0.5:12:26280

# 15-minute interval for 1 year
# 1-hour interval for 3 years

rrdtool create $rrdfile_bat \
--step 900 \
DS:value:GAUGE:1800:0:100 \
RRA:AVERAGE:0.5:1:35040 \
RRA:MIN:0.5:4:26280 \
RRA:MAX:0.5:4:26280 \
RRA:AVERAGE:0.5:4:26280

