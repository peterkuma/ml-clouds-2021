# Code for the paper "Machine learning of cloud types shows higher climate sensitivity is associated with lower cloud biases"

Peter Kuma<sup>1</sup>, Frida A.-M. Bender<sup>1</sup>, Alex Schuddeboom<sup>2</sup>, Adrian J. McDonald<sup>2</sup>, Øyvind Seland<sup>3</sup>

<sup>1</sup>Department of Meteorology (MISU), Stockholm University, Stockholm, Sweden\
<sup>2</sup>School of Physical and Chemical Sciences, Christchurch, Aotearoa New Zealand\
<sup>3</sup>Norwegian Meteorological Institute, Oslo, Norway

This repository contains code for the paper "Machine learning of cloud types
shows higher climate sensitivity is associated with lower cloud biases".

If you have any questions about the code you can contact the authors or submit
an Issue on GitHub.

## Requirements

The code can be run on a Linux distribution with the following software
(exact versions are listed for reproducibility, but newer version may work
equally well):

- Python 3.7.3
- Cython 0.29.2
- aria2 1.34.0

and Python packages:

- tensorflow 1.14.0
- scipy 1.7.0
- numpy 1.21.1
- matplotlib 3.5.1
- pymc3 3.11.2
- pst-format 1.1.1
- aquarius-time 0.1.1
- ds-format 1.2.0
- pyproj 2.6.1
- pandas 1.3.0

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
prepare_samples
  plot_idd_stations [Figure 1a]
  tf
    plot_sample [Figure 1b, c]
    plot_training_history [Figure 3]
    merge_samples
      calc_dtau_pct
        plot_dtau_pct [Figure 6]
      calc_geo_cto
        plot_geo_cto [Figure 4, 5]
        plot_geo_cto_rmse [Figure 11b, c, d]
      calc_cto
        plot_cto [Figure 10]
        calc_cto_ecs
          plot_cto_ecs [Figure 11a]
plot_tf_scheme [Figure 2]
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
`input/idd/synop` and `input/idd/buoy` for the synop and buoy files,
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
in `input/cmip5/<experiment>/<frequency/` and
`input/cmip6/<experiment>/<frequency/`, respectively, where `<experiment>`
is either `historical` (for both `historical` and `hist-1950`) or
`abrupt-4xCO2` and `<frequency>` is `day` or `mon`.

### GISS Surface Temperature Analysis (GISTEMP)

The GISTEMP dataset is in `data/gistemp` available as the original file
(CSV) and converted to NetCDF with `gistemp_to_nc` (required by the main
commands). The original dataset has been downloaded from [NASA
GISS](https://data.giss.nasa.gov/gistemp/), and the original terms of use of
this dataset apply.

### CERES

SYN1deg Level 3 daily means can be downloaded from the [CERES website](https://ceres.larc.nasa.gov).
They have to be converted to NetCDF with h4toh5 and stored in `input/ceres`.

### ERA5

ERA5 hourly data on pressure levels from 1979 to present can be downloaded
from the [Copernicus website](https://cds.climate.copernicus.eu/#!/search?text=ERA5&type=dataset).
They have to be converted to daily mean files with cdo and stored in
`input/era5`.

### MERRA-2

The M2T1NXRAD MERRA-2 product can be downloaded from [NASA EarthData](https://disc.gsfc.nasa.gov/datasets?project=MERRA-2).
Daily means can be downloaded with the GES DISC Subsetter. They have to
be stored in `input/merra-2`.

## Input directory

The input should contain the necessary input files. If not provided in this
repository, the files need to be downloaded from the CERES projet website,
the CMIP5 and CMIP6 archives, and RDA and placed in the respective directories.
NorESM is optional. Below is a description of the structure of the input
directory:

```
input
  ceres: CERES SYN1deg daily mean NetCDF files.
  noresm:
    historical
      day
        <variable>: Daily mean NorESM NetCDF files in the historical experiment for variables FLNT, FLNTC, FLUT, FLUTC, FSNTOA, FSNTOAC, SOLIN.
    abrupt-4xCO2
      day
        <variable>: Daily mean NorESM NetCDF files in the abrupt-4xCO2 experiment for variabes FLNT, FLNTC, FLUT, FLUTC, FSNTOA, FSNTOAC, SOLIN.
  cmip5
    abrupt-4xCO2
      day: Daily mean CMIP5 files in the abrupt-4xCO2 experiment (rlut, rlutcs, rsdt, rsut, rsutcs).
        by-model: Directory created by create_by_model.
      mon: Daily mean CMIP5 files in the abrupt-4xCO2 experiment (tas).
  cmip6
    abrupt-4xCO2
      day: Daily mean CMIP6 files in the abrupt-4xCO2 experiment (rlut, rlutcs, rsdt, rsut, rsutcs).
        by-model: Directory created by create_by_model.
      mon: Daily mean CMIP6 files in the abrupt-4xCO2 experiment (tas).
    hist-1950
      day: Daily mean CMIP6 EC-Earth3P files in the hist-1950 experiment (rlut, rlutcs, rsdt, rsut, rsutcs).
    historical
      day: Daily mean CMIP6 files in the historical experiment (rlut, rlutcs, rsdt, rsut, rsutcs).
        by-model: Directory created by create_by_model.
        by-model: Directory created by create_by_model.
  ecs
    ecs.csv: ECS, TCR and CLD values for CMIP5 and CMIP6 models.
  era5: Daily mean ERA5 NetCDF files with all variables in each file: tisr, tsr, tsrc, ttr, ttrc.
  idd
    buoy: IDD buoy NetCDF files.
    syop: IDD synop NetCDF files.
  landmask
    ne_110m_land.nc: Land-sea mask derived from Natural Earth data.
  merra-2: Daily mean MERRA-2 NetCDF files of the M2T1NXRAD product with all variables in each file: LWTUP, LWTUPCLR, SWTDN, SWTNT, SWTNTCLR.
  models_*: Lists of models available in the historical and abrupt-4xCO experiments.
```

## Data directory

The data directory should the output from the main commands. Below is a
description of its structure:

```
data
  ann
    ceres.h5: NetCDF file of ANN model generated by tf train from CERES data.
    history.nc: ANN model training history file.
  cto
    abrupt-4xCO2
      cto.nc: Cloud type occurrence calculated by calc_cto for the abrupt-4xCO2 experiment.
    historical
      cto.nc: Cloud type occurrence calculated by calc_cto for the historical experiment.
  cto_ecs
    cto_ecs.nc: Cloud type occurrence vs. ECS calculated by calc_cto_ecs.
  dtau_pct
    dtau_pct.nc: Histogram calculated by calc_dtau_pct.
  geo_cto
    abrupt-4xCO2
      all
      part_1
      part_2
    historical
      all
      part_1
      part_2
  idd_sample: Sample IDD files for plotting stations.
  samples
    ceres
      <year>: CERES samples generated by prepare_samples.
      <year>.nc: Merged samples wth merge_samples for a given year.
    ceres_training
      <year>: CERES samples generated by prepare_samples for training.
      <year>.nc: Merged samples wth merge_samples for a given year.
    historical
      <model>/<year>: Samples generated by prepare_samples for a model/year in the historical experiment.
      <year>.nc: Merged samples wth merge_samples for a given year.
    abrupt-4xCO2
      <model>/<year>: Samples generated by prepare_samples for a model/year in the abrupt-4xCO2 experiment.
      <year>.nc: Merged samples wth merge_samples for a given year.
  samples_tf
    ceres
      <year>.nc: CERES samples labelled with tf apply for a year.
    historical
      <model>/<year>.nc: Samples labelled with tf apply for a model/year in the historical experiment.
    abrupt-4xCO2
      <model>/<year>.nc: Samples labelled with tf apply for a model/year in the abrupt-4xCO2 experiment.
```

## How to run

The `input` directory should be populated with the required input files.
The CMIP input files should be indexed with `create_by_model`. The space
requirement in the data directory are about 8 TB.

```sh
# Optional configuration:
export JOBS=12 # Number of concurrent jobs
export INPUT=input # Input directory
export DATA=data # Data directory
export PLOT=plot # Plot directory

./run prepare_ceres_training
./run train_ann
./run plot_idd_stations
./run plot_training_history
./run prepare_ceres
./run prepare_historical
./run prepare_abrupt-4xCO2
./run label_ceres
./run label_historical
./run label_abrupt-4xCO2
./run calc_dtau_pct
./run plot_dtau_pct
./run calc_geo_cto_historical
./run calc_geo_cto_abrupt-4xCO2
./run plot_geo_cto_historical
./run plot_geo_cto_abrupt-4xCO2
./run plot_geo_cto_rmse
./run calc_cto_historical
./run calc_cto_abrupt-4xCO2
./run plot_cto_historical
./run plot_cto_abrupt-4xCO2
./run plot_tf_scheme
```

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

Examples:

prepare_samples ceres input/ceres data/idd/synop input/idd/buoy data/landmask/ne_110m_land.nc both 2009-01-01 2009-12-31 data/samples/ceres_training/2009
prepare_samples cmip input/cmip6/historical/daily/by-model/AWI-ESM-1-1-LR none none none 2003-01-01 2003-12-31 data/samples/historical/AWI-ESM-1-1-LR/2003
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
- output: Output samples directory (NetCDF).

Examples:

bin/tf train data/samples/ceres_training data/ann/ceres.h5 data/ann/history.nc
bin/tf apply data/ann/ceres.h5 data/samples/ceres 2003 2020 data/samples_tf/ceres
bin/tf apply data/ann/ceres.h5 data/samples/historical/AWI-ESM-1-1-LR 2003 2014 data/samples_tf/historical/AWI-ESM-1-1-LR
```


### plot\_idd\_stations [Figure 1a]


```
Plot IDD stations on a map.

Usage: plot_idd_stations <input> <sample> <n> <output> <title>

Depends on: tf

Arguments:

- input: IDD input directory (NetCDF).
- sample: CERES sample - the output of tf apply (NetCDF).
- n: Sample number.
- output: Output plot (PDF).
- title: Plot title.

Examples:

bin/plot_idd_stations data/idd_sample/ data/samples/ceres/2010/2010-01-01T00\:00\:00.nc 0 plot/idd_stations.pdf '2010-01-01'
```


### plot\_sample [Figure 1b, c]


```
Plot sample.

Usage: plot_samples <input> <n> <output>

Depends on: tf

Arguments:

- input: Input sample (NetCDF) - the output of tf.
- n: Sample number.
- output: Output plot (PDF).

bin/plot_sample data/samples/ceres_training/2010/2010-01-01T00\:00\:00.nc 0 plot/sample.pdf
```


### plot\_training\_history [Figure 3]


```
Plot training history loss function.

Usage: plot_history <input> <output>

Depends on: tf

Arguments:

- input: Input history file - the output of tf (NetCDF).
- output: Output plot (PDF).

Examples:

bin/plot_training_history data/ann/history.nc plot/training_history.pdf
```


### merge\_samples


```
Merge daily sample files produced by tf into yearly files. Filter samples by
number of stations greater or equal to 100.

Usage: merge_samples <input> <output>

Depends on: tf

Arguments:

- input: Input directory - the output of tf.
- output: Output file.

Examples:

bin/merge_samples data/samples/ceres/2003{,.nc}
bin/merge_samples data/samples/historical/AWI-ESM-1-1-LR/2003{,.nc}
```


### calc\_dtau\_pct


```
Calculate cloud optical depth - cloud top press histogram.

Usage: calc_dtau_pct <samples> <ceres> <output>

Depends on: merge_samples

Arguments:

- samples: Directory with samples - the output of merge_samples (NetCDF).
- ceres: Directory with CERES SYN1deg (NetCDF).
- output: Output file (NetCDF).

Examples:

bin/calc_dtau_pct data/samples_tf/ceres input/ceres data/dtau_pct/dtau_pct.nc
```


### plot\_dtau\_pct [Figure 6]


```
Plot cloud optical depth - cloud top pressure histogram.

Usage: plot_dtau_pct <input> <output>

Depends on: calc_dtau_pct

Arguments:

- input: Input file - the output of calc_dtau_pct (NetCDF).
- output: Output plot (PDF).

Example:

bin/plot_dtau_pct data/dtau_pct/dtau_pct.nc plot/dtau_pct.pdf
```


### calc\_geo\_cto


```
Calculate geographical distribution of cloud type occurrence distribution.

Usage: calc_geo_cto <input> <tas> <output>

Depends on: merge_samples gistemp_to_nc

Arguments:

- input: Input file or directory - the output of merge_samples (NetCDF).
- tas: Input directory with tas - the output of gistemp_to_nc (NetCDF).
- output: Output file (NetCDF).

Examples:

bin/calc_geo_cto data/samples_tf/ceres data/tas/historical/CERES.nc data/geo_cto/historical/all/CERES.nc
bin/calc_geo_cto data/samples_tf/historical/AWI-ESM-1-1-LR data/tas/historical/AWI-ESM-1-1-LR data/geo_cto/historical/all/AWI-ESM-1-1-LR.nc
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

Examples:

bin/plot_geo_cto 0 true data/geo_cto/historical/part_1 data/ecs/ecs.csv plot/geo_cto_historical_1.pdf
bin/plot_geo_cto 0 true data/geo_cto/historical/part_2 data/ecs/ecs.csv plot/geo_cto_historical_2.pdf
```


### plot\_geo\_cto\_rmse [Figure 11b, c, d]


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

bin/plot_geo_cto_rmse ecs data/geo_cto/historical/all data/ecs/ecs.csv plot/geo_cto_rmse_ecs_historical.pdf
bin/plot_geo_cto_rmse tcr data/geo_cto/historical/all data/ecs/ecs.csv plot/geo_cto_rmse_tcr_historical.pdf
bin/plot_geo_cto_rmse cld data/geo_cto/historical/all data/ecs/ecs.csv plot/geo_cto_rmse_cld_historical.pdf
```


### calc\_cto


```
Calculate global mean cloud type occurrence.

Usage: calc_cto <input> <tas> <output>

Depends on: merge_samples gittemp_to_nc

Arguments:

- input: Input directory - the output of merge_samples (NetCDF).
- tas: Input directory with tas - the output of gittemp_to_nc (NetCDF).
- output: Output file (NetCDF).

Examples:

bin/calc_cto data/samples_tf/historical data/tas/historical data/cto/historical/cto.nc
bin/calc_cto data/samples_tf/abrupt-4xCO2 data/tas/abrupt-4xCO2 data/cto/abrupt-4xCO2/cto.nc
```


### plot\_cto [Figure 10]


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

Examples:

bin/plot_cto ecs 0 relative false data/cto/historical/cto.nc data/ecs/ecs.csv plot/cto_historical.pdf 'CMIP6 historical (2003-2014) and reanalyses (2003-2020) relative to CERES (2003-2020)'
bin/plot_cto ecs 1-tas absolute false data/cto/abrupt-4xCO2/cto.nc data/ecs/ecs.csv plot/cto_abrupt-4xCO2.pdf 'CMIP abrupt-4xCO2 (1850-1949) and CERES (2003-2020)'
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

Examples:

bin/calc_cto_ecs data/cto/abrupt-4xCO2/cto.nc data/ecs/ecs.csv data/cto_ecs/cto_ecs.nc
```


### plot\_cto\_ecs [Figure 11a]


```
Plot cloud type occurrence vs. ECS regression.

Usage: plot_cto_ecs <varname> <input> <summary> <output>

Depends on: calc_cto calc_cto_ecs

Arguments:

- varname: Variable name. One of: "ecs" (ECS), "tcr" (TCR), "cld" (cloud
  feedback).
- input: Input file - the output of calc_cto (NetCDF).
- summary: Input file - the output of calc_cto_ecs (NetCDF).
- output: Output plot (PDF).

Examples:

bin/plot_cto_ecs ecs data/cto/abrupt-4xCO2/cto.nc data/cto_ecs/cto_ecs.nc plot/cto_ecs.pdf
```


### plot\_tf\_scheme [Figure 2]


```
Plot a TensorFlow model scheme.

Usage: plot_tf_scheme <output>

Arguments:

- output: Output file (PNG).

Examples:

plot_tf_scheme plot/tf_scheme.pdf
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

Copyright (C) 2020-2022 Peter Kuma

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
