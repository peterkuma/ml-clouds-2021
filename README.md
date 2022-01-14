# Code for the paper "Cloud type machine learning shows better present-day cloud representation in climate models is associated with higher climate sensitivity"

Peter Kuma<sup>1</sup>, Frida Bender<sup>1</sup>, Alex Schuddeboom<sup>2</sup>, Adrian McDonald<sup>2</sup>, Øyvind Seland<sup>3</sup>

<sup>1</sup>Department of Meteorology (MISU), Stockholm University, Stockholm, Sweden\
<sup>2</sup>School of Physical and Chemical Sciences, Christchurch, Aotearoa New Zealand\
<sup>3</sup>Norwegian Meteorological Institute, Oslo, Norway

This repository contains code for the paper "Cloud type machine learning shows
better present-day cloud representation in climate models is associated with
higher climate sensitivity".

If you have any questions about the code you can contact the authors or submit
an Issue on GitHub.

## Requirements

The code can be run on a Linux distribution with the following software:

- Python 3
- Cython
- aria2

and Python packages:

- tensorflow
- scipy
- numpy
- matplotlib
- pymc3
- pst-format
- aquarius-time
- ds-format
- pyproj
- pandas

On Debian-based Linux distributions (Ubuntu, Debian, Devuan, ...), the required
software can be installed with:

```sh
apt install python3 cython3 aria2
```

We recommend installing the Python packages in a virtual environment (venv):

```sh
python3 -m venv venv
. venv/bin/activate
```

To install the Python packages:

```sh
pip3 install -r requirements.txt
```

## Overview

Below is an overview of the available commands showing their dependencies
and the paper figures they produce.

```
prepare_samples -> tf -> plot_idd_stations [Figure 1a]
                      -> plot_sample [Figure 1b, c]
                      -> plot_training_history [Figure 3]
                      -> calc_dtau_pct -> plot_dtau_pct [Figure 6]

prepare_samples -> tf -> calc_geo_co -> plot_geo_cto [Figure 4, 5]
                                     -> plot_geo_cto_rmse [Figure 8b, c, d]
                      -> calc_cto -> plot_cto [Figure 7]
                                  -> calc_cto_ecs -> plot_cto_ecs [Figure 8a]
```

## Input datasets

### Historical Unidata Internet Data Distribution (IDD) Global Observational Data

The IDD dataset contains ship and buoy records from the Global Telecommunication
System. It can be downloaded from [Research Data
Archive](https://rda.ucar.edu/datasets/ds336.0/). The relevant files are
the SYNOP and BUOY NetCDF files (2008-present), and the HISTSURFACEOBS tar
files (2003-2008). The HISTSURFACEOBS files have to be unpacked after
downloading.

In the examples below it is assumed that the IDD files are stored under
`data/idd/synop` and `data/idd/buoy` for the synop and buoy files,
respectively.

### Climate Model Intercomparison Project (CMIP)

CMIP5 and CMIP6 model output can be downloaded from the
[CMIP5](https://esgf-node.llnl.gov/projects/cmip5/) and
[CMIP6](https://esgf-node.llnl.gov/projects/cmip6/) data archives.  The
relevant experiments are `historical` (`hist-1950` in the case of EC-Earth3P)
and `abrupt-4xCO2`. The required variables are `tas` in the monthly (`mon`)
frequency, and `rlut`, `rlutcs`, `rsdt`, `rsut`, `rsutcs` in the daily (`day`)
frequency.

The command `download_cmip` can be used to create a list of CMIP files
to download from a JSON catalog file, which can be created on the archive site
above (`return results as JSON` on the search page). `limit=` in the URL to the
JSON file should be changed to 10000, and `Show All Replicas` should be
selected when searching. The resulting file list can be used with the program
aria2c as `aria2c -i <file>` to download to files. Afterwards, use
the commands `create_by_model` and `create_by_var` to create an index of
symlinks in the directory where the downloaded files are stored. This index is
required by the main commands.

In the examples below it is assumed that the CMIP5 and CMIP6 files are stored
in `data/cmip5/<experiment>/<frequency/` and
`data/cmip6/<experiment>/<frequency/`, respectively.

### GISS Surface Temperature Analysis (GISTEMP)

The GISTEMP dataset is in `data/gistemp` available as the original file
(CSV) and converted to NetCDF with `gistemp_to_nc` (required by the main
commands). The original dataset has been downloaded from [NASA
GISS](https://data.giss.nasa.gov/gistemp/), and the original terms of use of
this dataset apply.

## Main commands

Below is description of the available commands. They should be run in the Linux
terminal. The commands are located in the `bin` directory as should be run from
the main repository directory with `bin/<command> [<arguments>...]`.

### prepare\_samples


```
Prepare samples of clouds for CNN training.

Usage: prepare_samples <type> <input> <synop> <buoy> <landmask> <landsea> <start> <end> <output> [seed: <seed>]

Arguments:

- type: Input type. One of: "ceres" (CERES SYN 1deg), "cmip" (CMIP5/6),
  "cloud_cci" (Cloud_cci), "era5" (ERA5), "merra2" (MERRA-2), "noresm" (NorESM).
- input: Input directory with input files (NetCDF).
- synop: Input directory with IDD synoptic fies or "none" (NetCDF).
- buoy: Input directory with IDD buoy files or "none" (NetCDF).
- landmask: Land-sea mask file or "none" (NetCDF).
- landsea: Land or sea only. One of: "both", "land", "sea".
- start: Start time (ISO).
- end: End time (ISO).
- output: Output directory.

Options:

- seed: Random seed.
```


### tf


```
Train or apply a TensorFlow CNN.

Usage: tf train <input> <output> <output_history>
       tf apply <model> <input> <y1> <y2> <output>

Depends on: prepare_samples

Arguments (train):

- input: Input directory with samples - the output of prepare_samples (NetCDF).
- output: Output model (HDF5).
- output_history: History output (NetCDF).

Arguments (apply):

- model: TensorFlow model (HDF5).
- input: Input directory with samples - the output of prepare_samples (NetCDF).
- y1: Start year.
- y2: End year.
- output: Output statistics directory (NetCDF).
```


### calc\_geo\_cto


```
Calculate geographical distribution of cloud type occurrence distribution.

Usage: calc_geo_cto <input> <tas> <output>

Depends on: tf gistemp_to_nc

Arguments:

- input: Input file or directory - the output of tf apply (NetCDF).
- tas: Input directory with tas - the output of gistemp_to_nc (NetCDF).
- output: Output file (NetCDF).
```


### calc\_cto


```
Calculate global mean cloud type occurrence.

Usage: calc_cto <input> <tas> <output>

Depends on: tf gittemp_to_nc

Arguments:

- input: Input directory - the output of tf apply (NetCDF).
- tas: Input directory with tas - the output of gittemp_to_nc (NetCDF).
- output: Output file (NetCDF).
```


### calc\_cto\_ecs


```
Calculate cloud type occurrence vs. ECS regression.

Usage: calc_cto_ecs <input> <ecs> <output>

Depends on: calc_cto

Arguments:

- input: Input file - the output of calc_cto (NetCDF).
- ecs: ECS, TCR and CLD input (CSV).
- output: Output files (NetCDF).
```


### calc\_dtau\_pct


```
Calculate cloud optical depth - cloud top press histogram.

Usage: calc_dtau_pct <samples> <ceres> <output>

Depends on: tf

Arguments:

- samples: Directory with samples - the output of tf apply (NetCDF).
- ceres: Directory with CERES SYN1deg (NetCDF).
- output: Output file (NetCDF).
```


### plot\_idd\_stations [Figure 1a]


```
Plot IDD stations on a map.

Usage: plot_idd_stations <input> <sample> <n> <output> <title>

Depends on: tf

Arguments:

- input: IDD data directory (NetCDF).
- sample: CERES sample - the output of tf apply (NetCDF).
- n: Sample number.
- output: Output plot (PDF).
- title: Plot title.
```


### plot\_sample [Figure 1b, c]


```
Plot sample.

Usage: plot_samples <input> <n> <output>

Arguments:

- input: Input sample (NetCDF).
- n: Sample number.
- output: Output plot (PDF).
```


### plot\_training\_history [Figure 3]


```
Plot training history loss function.

Usage: plot_history <input> <output>

Depends on: tf

Arguments:

- input: Input history file - the output of tf (NetCDF).
- output: Output plot (PDF).
```


### plot\_geo\_cto [Figure 4, 5]


```
Plot geographical distribution of cloud type occurrence.

Usage: plot_geo_cto <deg> <relative> <input> <ecs> <output>

Depends on: calc_geo_cto

Arguments:

- deg: Degree. One of: 0 (absolute value) or 1 (trend).
- relative: Plot relative to CERES. One of: true or false.
- input: Input directory - the output of calc_geo_cto (NetCDF).
- ecs: ECS file (CSV).
- output: Output plot (PDF).
```


### plot\_dtau\_pct [Figure 6]


```
Plot cloud optical depth - cloud top pressure histogram.

Usage: plot_dtau_pct <input> <output>

Depends on: calc_dtau_pct

Arguments:

- input: Input file - the output of calc_dtau_pct (NetCDF).
- output: Output plot (PDF).
```


### plot\_cto [Figure 7]


```
Plot global mean cloud type occurrence.

Usage: plot_cto <varname> <degree> <absrel> <regression> <input> <ecs> <output> <title> [legend: <legend>]

Depends on: calc_cto

Arguments:

- varname: Variable name. One of: "ecs" (ECS), "tcr" (TCR), "cld" (cloud
  feedback).
- degree: One of: "0" (mean), "1-time" (trend in time), "1-tas" (trend in tas).
- absrel: One of "absolute" (absolute value), "relative" (relative to CERES).
- regression: Plot regression. One of: true or false.
- input: Input file - the output of calc_cto (NetCDF).
- ecs: ECS file (CSV).
- output: Output plot (PDF).
- title: Plot title.

Options:

- legend: Show legend ("true" or "false"). Default: "true".
```


### plot\_cto\_ecs [Figure 8a]


```
Plot cloud type occurrence vs. ECS regression.

Usage: plot_cto_ecs <varname> <input> <summary> <output> <title>

Depends on: calc_cto calc_cto_ecs

Arguments:

- varname: Variable name. One of: "ecs" (ECS), "tcr" (TCR), "cld" (cloud
  feedback).
- input: Input file - the output of calc_cto (NetCDF).
- summary: Input file - the output of calc_cto_ecs (NetCDF).
- output: Output plot (PDF).
- title: Plot title.
```


### plot\_geo\_cto\_rmse [Figure 8b, c, d]


```
Plot scatter plot of RMSE of the geographical distribution of cloud type
occurrence and sensitivity indicators (ECS, TCR and cloud feedback).

Usage: plot_geo_cto_rmse <var> <input> <ecs> <output> [legend: <legend>]

Depends on: calc_geo_cto

Arguments:

- var: One of: "ecs" (ECS), "tcr" (TCR), "cld" (CLD).
- input: Input directory - the output of calc_geo_cto (NetCDF).
- ecs: ECS file (CSV).
- output: Output plot (PDF).

Options:

- legend: Plot legend ("true" or "false"). Default: "true".

Examples:

bin/plot_geo_cto_rmse ecs data/models/historical/stats_geo_2003-2014_summary/ data/cmip.csv plot/geo_cto_rmse_ecs_historical_2003-2014.pdf
bin/plot_geo_cto_rmse tcr data/models/historical/stats_geo_2003-2014_summary/ data/cmip.csv plot/geo_cto_rmse_tcr_historical_2003-2014.pdf
bin/plot_geo_cto_rmse cld data/models/historical/stats_geo_2003-2014_summary/ data/cmip.csv plot/geo_cto_rmse_cld_historical_2003-2014.pdf
```


## Auxiliary commands

### build\_readme


```

Build the README document from a template.

Usage: build_readme <input> <bindir> <output>

Arguments:

- input: Input file.
- bindir: Directory with scripts.
- output: Output file.

Example:

bin/build_readme README.md.in bin README.md
```


### download\_cmip


```
Download CMIP data based on a JSON catalogue downloaded from the CMIP
archive search page.

Usage: download_cmip <filename> <var> <start> <end>

Arguments:

- filename: Input file (JSON).
- var: Variable name.
- start: Start time (ISO).
- end: End time (ISO).

Example:

bin/download_cmip catalog.json tas 1850-01-01 2014-01-01 > files
```


### create\_by\_model

```
Create a by-model index of CMIP data. This command should be run in the
directory with CMIP data.

Usage: create_by_model

Example:

cd data/cmip5/historical/day
./create_by_model
```

### create\_by\_var

```
Create a by-var index of CMIP data. This command should be run in the
directory with CMIP data.

Usage: create_by_var

Example:

cd data/cmip5/historical/day
./create_by_var
```

### gistemp\_to\_nc


```
Convert GISTEMP yearly temperature data to NetCDF.

Usage: gistemp_to_nc <input> <output>

Arguments:

- input: Input file "totalCI_ERA.csv" (CSV).
- output: Output file (NetCDF).

Example:

bin/gistemp_to_nc data/gistemp/totalCI_ERA.csv data/gistemp/gistemp.nc
```


## License

MIT License

Copyright (C) 2020, 2021 Peter Kuma

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
