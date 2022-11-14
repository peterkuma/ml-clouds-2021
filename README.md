# Code for the paper "Machine learning of cloud types in satellite observations and climate models"

Peter Kuma<sup>1</sup>,
Frida A.-M. Bender<sup>1</sup>,
Alex Schuddeboom<sup>2</sup>,
Adrian J. McDonald<sup>2</sup>,
Øyvind Seland<sup>3</sup>

<sup>1</sup>Department of Meteorology (MISU), Stockholm University, Stockholm, Sweden\
<sup>2</sup>School of Physical and Chemical Sciences, Christchurch, Aotearoa New Zealand\
<sup>3</sup>Norwegian Meteorological Institute, Oslo, Norway

This repository contains code for the paper
[Machine learning of cloud types in satellite observations and climate models](https://doi.org/10.5281/zenodo.6184907).

## Introduction

The code contains scripts for training an artificial neural network (ANN) for
prediction of cloud types based on satellite and ground-based station data, and
related data processing and visualisation. The artificial neural network is
implemented in [TensorFlow](https://www.tensorflow.org/). The scripts use
Python and bash. They should be run on Linux, although it may be possible to
adapt them to other operating systems.

The scripts are divided into data processing scripts and plotting scripts.
The scripts are dependent on one another for data input and output. The script
`run` in the main directory runs the individual data processing and plotting
scripts located in the directory `bin` and takes care of the dependencies.

Storage requirements for running the code on all available climate models and
reanalyses are on the scale of 10 TB, and main memory requirements are on the
scale of 60 GB. Lower hardware requirements are possible if used with fewer
models or shorter training data time periods.

Please see the manuscript for more details about the ANN. If you have any
questions about the code you can contact the manuscript authors or submit an
Issue on GitHub.

## Requirements

The code can be run on a Linux distribution with the following software
(exact versions are listed for reproducibility, but newer version may work
equally well):

- Python 3.9.2
- Cython 0.29.2
- aria2 1.35.0
- GNU parallel 20161222
- cdo 1.9.10

and Python packages:

- tensorflow 2.8.0
- scipy 1.7.3
- numpy 1.22.3
- matplotlib 3.5.3
- pymc3 3.11.5
- pst-format 1.2.1
- aquarius-time 0.1.0
- ds-format 3.3.1
- pyproj 3.0.0
- pandas 1.1.5
- netCDF4 1.5.5.1
- Cartopy 0.18.0

On Debian-based Linux distributions (Ubuntu, Debian, Devuan, ...), the required
software can be installed with:

```sh
apt install python3 cython3 aria2 parallel cdo
```

Optionally, to install the Python packages in a virtual environment (venv)
instead of the user's home directory:

```sh
python3 -m venv venv
. venv/bin/activate
```

To install the Python packages:

```sh
pip3 install -r requirements.txt
```

Depending on the Linux distribution, python and pip might be available as
`python` or `python3`, and `pip` or `pip3`.

## Input datasets

The input datasets are not contained in this repository because of their large
size, except for surface temperature data and a table of model ECS, TCR and
cloud feedback. The rest of the datasets have to be downloaded from other
repositories as described below. It is possible to run the scripts with fewer
climate models and reanalyses and thus reduce the amount of data needed to
be downloaded. The `run` script expects a particular subdirectory structure of
the `input` directory, described [below](#input-directory).

### Historical Unidata Internet Data Distribution (IDD) Global Observational Data

The IDD dataset contains ship and buoy records from the Global Telecommunication
System. It can be downloaded from [Research Data
Archive](https://rda.ucar.edu/datasets/ds336.0/). The relevant files are
the SYNOP and BUOY NetCDF files (2008–present), and the HISTSURFACEOBS tar
files (2003–2008). The HISTSURFACEOBS files have to be unpacked after
downloading.

In the examples below it is assumed that the IDD NetCDF files are stored under
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
aria2c as `aria2c -i <file>` to download the files. Afterwards, use the
commands `create_by_model` and `create_by_var` to create an index of symlinks
in the directory where the downloaded files are stored. This index is required
by the `run` script.

In the examples below it is assumed that the CMIP5 and CMIP6 files are stored
in `input/cmip5/<experiment>/<frequency/` and
`input/cmip6/<experiment>/<frequency/`, respectively, where `<experiment>`
is either `historical` (for both `historical` and `hist-1950`) or
`abrupt-4xCO2` and `<frequency>` is `day` or `mon`.

After downloading, the data should be resambled to 2.5° resolution with
[cdo](https://code.mpimet.mpg.de/projects/cdo/embedded/index.html):

```sh
# To be run in the directory with the CMIP NetCDF files.
mkdir 2.5deg
parallel cdo -remapcon,r144x96 {} 2.5deg/{} ::: *.nc
```

### GISS Surface Temperature Analysis (GISTEMP)

The GISTEMP dataset is in `data/gistemp` available as the original file
(CSV) and converted to NetCDF with `gistemp_to_nc` (required by the main
commands). The original dataset was downloaded from [NASA
GISS](https://data.giss.nasa.gov/gistemp/). The original terms of use apply.

### CERES

SYN1deg Level 3 daily means can be downloaded from the [CERES
website](https://ceres.larc.nasa.gov). They have to be converted to NetCDF with
the tool
[h4toh5](https://portal.hdfgroup.org/display/support/Download+h4h5tools)
(provided by the HDF Group), and stored in `input/ceres`.

### ERA5

ERA5 hourly data on pressure levels from 1979 to present can be downloaded
from the [Copernicus
website](https://cds.climate.copernicus.eu/#!/search?text=ERA5&type=dataset).
They have to be converted to daily mean files with cdo and stored in
`input/era5`.

The data should be resampled to 2.5° resolution in the same way as the CMIP
data.

### MERRA-2

The M2T1NXRAD MERRA-2 product can be downloaded from [NASA
EarthData](https://disc.gsfc.nasa.gov/datasets?project=MERRA-2). Daily means
can be downloaded with the GES DISC Subsetter. They have to be stored in
`input/merra-2`.

The data should be resampled to 2.5° resolution in the same way as the CMIP
data.

### Global mean near-surface temperature

Global mean near-surface temperature datasets should be stored in `input/tas`.
They are present in this repository and need to be extracted from the
archive `input/tas.tar.xz`.

## Directories

### Input directory

The `input` directory should contain the necessary input files. Apart from the
datasets already contained in this repository, the files need to be downloaded
from the sources as described above. NorESM2 is optional. If the NorESM2 data
are not available, it should removed from the `input/models_*` files. Below is
a description of the structure of the input directory:

```
ceres               CERES SYN1deg daily mean files (NetCDF).
↳ 2.5deg            The same as above, but resampled to 2.5°.
cmip5               CMIP5 data files (NetCDF).
↳ abrupt-4xCO2      abrupt-4xCO2 experiment files.
  ↳ day             Daily mean files for rlut, rlutcs, rsdt, rsut and rsutcs.
    ↳ 2.5deg        The same as above, but resampled to 2.5°.
      ↳ by-model    Directory created by create_by_model.
    ↳ mon           Monthly mean files for tas.
cmip6               CMIP6 data files (NetCDF).
↳ abrupt-4xCO2      abrupt-4xCO2 experiment files.
  ↳ day             Daily mean files for rlut, rlutcs, rsdt, rsut and rsutcs.
    ↳ 2.5deg        The same as above, but resampled to 2.5°.
      ↳ by-model    Directory created by create_by_model.
  ↳ mon             Daily mean files for tas.
↳ hist-1950x        hist-1950 expriment files for the EC-Earth3P model.
  ↳ day             Daily mean files for rlut, rlutcs, rsdt, rsut and rsutcs.
    ↳ 2.5deg        The same as above, but resampled to 2.5°.
      ↳ by-model    Directory created by create_by_model.
  ↳ mon             Monthly mean files for tas.
↳ historical        historical experiment files.
  ↳ day             Daily mean files ofr rlut, rlutcs, rsdt, rsut and rsutcs.
    ↳ 2.5deg        The same as above, but resampled to 2.5°.
      ↳ by-model    Directory created by create_by_model.
  ↳ mon             Monthly mean files for tas.
ecs
↳ ecs.csv           ECS, TCR and CLD values for the CMIP5 and CMIP6 models.
era5                Daily mean ERA5 NetCDF files with the following variables in each file: tisr, tsr, tsrc, ttr and ttrc.
↳ 2.5deg            The same as above, but resampled to 2.5°.
idd
↳ buoy              IDD buoy files (NetCDF).
↳ synop             IDD synop files (NetCDF).
landmask
↳ ne_110m_land.nc   Land-sea mask derived from Natural Earth data.
merra2              Daily mean MERRA-2 NetCDF files of the M2T1NXRAD product with the following variables in each file: LWTUP, LWTUPCLR, SWTDN, SWTNT and SWTNTCLR.
↳ 2.5deg            The same as above, but resampled to 2.5°.
noresm2             NorESM2 files.
↳ historical
  ↳ day             Daily mean files.
    ↳ <variable>    Daily mean NorESM NetCDF files in the historical experiment for variables FLNT, FLNTC, FLUT, FLUTC, FSNTOA, FSNTOAC and SOLIN.
    ↳ 2.5deg        The same as above, but resampled to 2.5°.
      ↳ <variable>  The same as above, but resampled to 2.5°.
↳ abrupt-4xCO2
  ↳ day             Daily mean files.
    ↳ <variable>    Daily mean NorESM2 NetCDF files in the abrupt-4xCO2 experiment for variabes FLNT, FLNTC, FLUT, FLUTC, FSNTOA, FSNTOAC and SOLIN.
      ↳ 2.5deg      The same as above, but resampled to 2.5°.
tas                 Near-surface air temperature (to be extracted from tas.tar.xz).
↳ historical
  ↳ CERES.nc        Near-surface air temperature from observations (GISTEMP).
  ↳ <model>.nc      Near-surface air temperature of a model in the historical experiment.
↳ abrupt-4xCO2
  ↳ CERES.nc        Near-surface air temperature from observations (GISTEMP).
  ↳ <model>.nc      Near-surface air temperature of a model in the abrupt-4xCO2 experiment.
models_*            Files containing a list of models to be processed.
tas.tar.xz          Near-surface air temperature (compressed archive).
```

### Data directory

Output from the processing commands is written in the data directory
(`data_4`, `data_10` and `data_27` for 4, 10 and 27 cloud types). In addition,
a common data directory (`data`) stores data common to all cloud type sets.
Below is a description of its structure (this is created automatically by the
`run` script during the data processing):

```
ann
↳ ceres.h5           ANN model generated by tf train (HDF5).
↳ history.nc         ANN model training history file (NetCDF).
cto_ecs
↳ cto_ecs.nc         Cloud type occurrence vs. ECS calculated by calc_cto_ecs (NetCDF).
dtau_pct
↳ dtau_pct.nc        Histogram calculated by calc_dtau_pct (NetCDF).
geo_cto              Geographical distribution files for models and CERES calculated by calc_geo_cto.
↳ abrupt-4xCO2       CMIP5 and CMIP6 abrupt-4xCO2 experiment.
  ↳ all              All models.
  ↳ part_1           Models for the first figure.
  ↳ part_2           Models for the continued figure.
↳ historical         CMIP6 historical expeirment.
  ↳ all              All models.
  ↳ part_1           Models for the first figure.
  ↳ part_2           Models for the continued figure.
idd_geo              Geographical distribution files for IDD calculated by calc_idd_cto.
idd_sample           Sample IDD files for plotting stations.
samples              A symbolic link to data/samples.
↳ ceres
  ↳ <year>           CERES samples generated by prepare_samples.
  ↳ <year>.nc        Merged samples for a given year (NetCDF).
  ↳ training         Symbolic links to the training years in the parent directory.
  ↳ validation       Symbolic links to the validation years in the parent directory.
↳ abrupt-4xCO2       abrupt-4xCO2 CMIP5 and CMIP6 experiment.
  ↳ <model>
    ↳ <year>         Samples generated by prepare_samples for a model/year in the abrupt-4xCO2 experiment.
    ↳ <year>.nc      Merged samples for a given year (NetCDF).
↳ historical         historical CMIP6 experiment.
  ↳ <model>
    ↳ <year>         Samples generated by prepare_samples for a model/year in the historical experiment.
    ↳ <year>.nc      Merged samples for a given year (NetCDF).
samples_pred
↳ abrupt-4xCO2
  ↳ <model>
    ↳ <year>.nc      Samples predicted with tf apply for a model/year in the abrupt-4xCO2 experiment.
↳ historical
  ↳ ceres/<year>.nc  CERES samples predicted with tf apply for a year.
  ↳ <model>
    ↳ <year>.nc      Samples predicted with tf apply for a model/year in the historical experiment.
val_stats            Validation statistics calculated by calc_val_stats.
↳ all.nc
↳ regions.nc
xval
↳ <region>           Results for an ANN trained on station data excluding a region.
↳ geo_cto            Geographical distribution
  ↳ all              Input files for the geo_cto_xval plots.
    ↳ 0_xval_all.nc  Symbolic link to geo_cto/historical/validation/CERES.nc.
    ↳ 1_xval_NW.nc   Symbolic link to xval/nw/geo_cto/historical/all/CERES.nc.
    ↳ 2_xval_NE.nc   Symbolic link to xval/ne/geo_cto/historical/all/CERES.nc.
    ↳ 3_xval_SE.nc   Symbolic link to xval/se/geo_cto/historical/all/CERES.nc.
    ↳ 4_xval_SW.nc   Symbolic link to xval/sw/geo_cto/historical/all/CERES.nc.
  ↳ regions.nc       Merged regions (NA, EA, OC and SA) geographical distribution produced by merge_xval_geo_cto.
```

## How to run

The `input` directory should be populated with the required input files before
running the scripts.

The `run` bash script runs the Python scripts in `bin` for various tasks. The
tasks can be run in a sequence as below. Before running the `run` script,
configuration should be imported from one of `config_4`, `config_10` or
`config_27` for 4, 10 and 27 cloud types, respectively. The output directories
for data files (NetCDF) and plots (PDF and PNG) are `data_x` and `plot_x`,
where x is 4, 10, or 27, respectively. Data files common to all cloud type sets
are stored in `data`. Some of the tasks might take a significant amount of
time to complete (hours to days, depending on the CPU).  In general, the tasks
should be run in order because of data dependencies.

```sh
# Optional configuration:
export JOBS=24 # Number of concurrent jobs. Defaults to the number of CPU cores if not set.

. config_4 # Configuration for 4 cloud types
# . config_10 for 10 cloud types.
# . config_27 for 27 cloud types.

./run prepare_ceres              # Prepare CERES samples.
./run train_ann                  # Train the ANN.
./run plot_training_history      # Plot training history [Figure S1].
./run plot_idd_stations          # Plot IDD stations [Figure 1a].
./run predict_ceres              # Predict CERES samples using the ANN.
./run prepare_historical         # Prepare CMIP6 historical samples.
./run predict_historical         # Predict CMIP6 historical samples using the ANN.
./run calc_geo_cto_historical    # Calculate geographical distribution of cloud type occurrence from the CMIP6 historical samples.
./run plot_geo_cto_historical    # Plot geographical distribution of cloud type occurrence for the CMIP6 historical experiment [Figure 6, 7].
./run plot_cto_historical        # Plot cloud type occurrence bar chart for the CMIP6 historical experiment [Figure 9a].
./run prepare_abrupt-4xCO2       # Prepare CMIP5 and CMIP6 abrupt-4xCO2 samples.
./run predict_abrupt-4xCO2       # Predict CMIP5 and CMIP6 abrupt-4xCO2 samples using the ANN.
./run calc_geo_cto_abrupt-4xCO2  # Calculate geographical distribution of cloud type occurrence from the CMIP5 and CMIP6 abrupt-4xCO2 samples.
./run plot_geo_cto_abrupt-4xCO2  # Plot geographical distribution of cloud type occurrence for the CMIP5 and CMIP6 abrupt-4xCO2 experiment [Figure S7, S8].
./run plot_cto_abrupt-4xCO2      # Plot cloud type occurrence bar chart for the CMIP5 and CMIP6 abrupt-4xCO2 experiment [Figure 9b].
./run plot_cto_rmse_ecs          # Plot cloud type occurrence RMSE vs. ECS [Figure 12, S10, S11].
./run calc_cto_ecs               # Calculate cloud type occurrence vs. ECS regression in the CMIP5 and CMIP6 abrupt-4xCO2 experiment.
./run plot_cto_ecs               # Plot cloud type occurrence vs. ECS regression in the CMIP5 and CMIP6 abrupt-4xCO2 experiment [Figure 11].
./run calc_dtau_pct              # Calculate cloud optical depth - cloud top pressure histograms.
./run plot_dtau_pct              # Plot cloud optical depth - cloud top pressure histograms [Figure 8].
./run train_ann_xval             # Train ANNs for cross-validation.
./run calc_geo_cto_xval          # Calculate geographical distribution of cloud type occurrence for cross-validation.
./run plot_geo_cto_xval          # Plot geographical distribution of cloud type occurrence for cross-validation [Figure 3, S12].
./run calc_idd_geo               # Calculate geographical distribution of IDD cloud type occurrence.
./run plot_validation            # Plot validation results [Figure 4].
./run calc_val_stats             # Calculate validation statistics.
./run plot_roc                   # Plot ROC [Figure 5].
```

## Commands

### Overview

Below is an overview of the available commands showing their dependencies and
the paper figures they produce.

```
prepare_samples
↳ plot_idd_stations [Figure 1a]
↳ tf
  ↳ plot_sample [Figure 1b, c]
  ↳ plot_training_history [Figure S1]
  ↳ calc_dtau_pct
    ↳ plot_dtau_pct [Figure 8]
  ↳ calc_geo_cto
    ↳ plot_geo_cto [Figure 3, 6, 7, S7, S8, S12]
    ↳ plot_cto_rmse_ecs [Figure 12, S9–11]
    ↳ plot_cto [Figure 9, S4–6]
    ↳ calc_cto_ecs
      ↳ plot_cto_ecs [Figure 11]
    ↳ calc_cloud_props
      ↳ plot_cloud_props [Figure 10]
    ↳ plot_station_corr [Figure S3]
    ↳ calc_idd_geo
      ↳ plot_idd_n_obs [Figure S2]
      ↳ merge_xval_geo_cto
        ↳ plot_validation [Figure 4]
        ↳ calc_val_stats
          ↳ plot_roc [Figure 5]
```

### Main commands

Below is a description of the main commands. They can be run either
individually or with the `run` command as described above. They should be run
in a Linux terminal (bash). The commands are located in the `bin` directory as
should be run from the main repository directory with `bin/<command>
[<arguments>...]`.

Some of the commands use [PST](https://github.com/peterkuma/pst/) for command
line argument parsing, which allows passing of complex arguments such as
arrays, but may also require escaping special characters, for example in file
names.

#### prepare\_samples


```
Prepare samples of clouds for CNN training.

Usage: prepare_samples TYPE INPUT SYNOP BUOY START END OUTPUT [OPTIONS]

Arguments:

  TYPE    Input type. One of: "ceres" (CERES SYN 1deg), "cmip" (CMIP5/6), "cloud_cci" (Cloud_cci), "era5" (ERA5), "merra2" (MERRA-2), "noresm2" (NorESM).
  INPUT   Input directory with input files (NetCDF).
  SYNOP   Input directory with IDD synoptic files or "none" (NetCDF).
  BUOY    Input directory with IDD buoy files or "none" (NetCDF).
  START   Start time (ISO).
  END     End time (ISO).
  OUTPUT  Output directory.

Options:

  seed: VALUE           Random seed.
  keep_stations: VALUE  Keep station records in samples ("true" or "false").  Default: "false".
  nsamples: VALUE       Number of samples per day to generate. Default: 100.

Examples:

prepare_samples ceres input/ceres input/idd/synop input/idd/buoy 2009-01-01 2009-12-31 data/samples/ceres/2009
prepare_samples cmip input/cmip6/historical/day/by-model/AWI-ESM-1-1-LR none none 2003-01-01 2003-12-31 data/samples/historical/AWI-ESM-1-1-LR/2003
```


#### plot\_idd\_stations [Figure 1a]


```
Plot IDD stations on a map.

Usage: plot_idd_stations INPUT SAMPLE N OUTPUT TITLE

Arguments:

  INPUT   IDD input directory (NetCDF).
  SAMPLE  CERES sample. The output of tf apply (NetCDF).
  N       Sample number.
  OUTPUT  Output plot (PDF).
  TITLE   Plot title.

Examples:

bin/plot_idd_stations data/idd_sample/ data/samples/ceres/2010/2010-01-01T00\:00\:00.nc 0 plot/idd_stations.pdf '2010-01-01'
```


#### tf


```
Train or apply a TensorFlow CNN.

Usage: tf train INPUT INPUT_VAL OUTPUT OUTPUT_HISTORY [OPTIONS]
       tf apply MODEL INPUT OUTPUT [OPTIONS]

Arguments (tf train):

  INPUT           Input directory with samples. The output of prepare_samples (NetCDF).
  INPUT_VAL       Input directory with validation samples (NetCDF).
  OUTPUT          Output model (HDF5).
  OUTPUT_HISTORY  History output (NetCDF).

Arguments (tf apply):

  MODEL   TensorFlow model (HDF5).
  INPUT   Input directory with samples. The output of prepare_samples (NetCDF).
  OUTPUT  Output samples directory (NetCDF).

Options (tf train):

  night: VALUE          Train for nighttime only. One of: true or false. Default: false.
  exclude_night: VALUE  Exclude nighttime samples. One of: true or false. Default: true.
  classes: VALUE        Classification. One of: 0 (4 cloud types), 1 (10 cloud genera), 2 (27 cloud genera). Default: 0.
  exclude: { LAT1 LAT2 LON1 LON2 }
      Exclude samples with pixels in a region bounded by given latitude and longitude. Default: none.
  nsamples: VALUE       Maximum number of samples to use for the training per day. Default: 20.

Options (tf apply):

  classes: VALUE  Classification. One of: 0 (4 cloud types), 1 (10 cloud genera), 2 (27 cloud genera). Default: 0.

Examples:

bin/tf train data/samples/ceres_training/training data/samples/ceres_training/validation data/ann/ceres.h5 data/ann/history.nc
bin/tf apply data/ann/ceres.h5 data/samples/ceres data/samples_pred/ceres
bin/tf apply data/ann/ceres.h5 data/samples/historical/AWI-ESM-1-1-LR data/samples_pred/historical/AWI-ESM-1-1-LR
```


#### plot\_sample [Figure 1b, c]


```
Plot sample.

Usage: plot_samples INPUT N OUTPUT

Arguments:

  INPUT   Input sample (NetCDF). The output of tf.
  N       Sample number.
  OUTPUT  Output plot (PDF).

Examples:

bin/plot_sample data/samples/ceres_training/2010/2010-01-01T00\:00\:00.nc 0 plot/sample.pdf
```


#### plot\_training\_history [Figure S1]


```
Plot training history loss function.

Usage: plot_history INPUT OUTPUT

Arguments:

  INPUT   Input history file. The output of tf (NetCDF).
  OUTPUT  Output plot (PDF).

Examples:

bin/plot_training_history data/ann/history.nc plot/training_history.pdf
```


#### calc\_dtau\_pct


```
Calculate cloud optical depth - cloud top press histogram.

Usage: calc_dtau_pct SAMPLES CERES OUTPUT [OPTIONS]

Arguments:

  SAMPLES  Directory with samples. The output of merge_samples (NetCDF).
  CERES    Directory with CERES SYN1deg (NetCDF).
  OUTPUT   Output file (NetCDF).

Options:

  classes: VALUE  Classification. One of: 0 (4 cloud types), 1 (10 cloud genera), 2 (27 cloud genera). Default: 0.

Examples:

bin/calc_dtau_pct data/samples_pred/ceres input/ceres data/dtau_pct/dtau_pct.nc
```


#### plot\_dtau\_pct [Figure 8]


```
Plot cloud optical depth - cloud top pressure histogram.

Usage: plot_dtau_pct INPUT OUTPUT

Arguments:

  INPUT   Input file. The output of calc_dtau_pct (NetCDF).
  OUTPUT  Output plot (PDF).

Examples:

bin/plot_dtau_pct data/dtau_pct/dtau_pct.nc plot/dtau_pct.pdf
```


#### calc\_geo\_cto


```
Calculate geographical distribution of cloud type occurrence distribution.

Usage: calc_geo_cto INPUT [INPUT_NIGHT] TAS OUTPUT [OPTIONS]

Arguments:

  INPUT        Input file or directory (NetCDF). The output of tf.
  INPUT_NIGHT  Input directory daily files - nightime samples (NetCDF). The output of tf.
  TAS          Input file with tas. The output of gistemp_to_nc (NetCDF).
  OUTPUT       Output file (NetCDF).

Options:

  resolution: VALUE  Resolution (degrees). Default: 5. 180 must be divisible by <value>.

Examples:

bin/calc_geo_cto data/samples_pred/ceres input/tas/historical/CERES.nc data/geo_cto/historical/all/CERES.nc
bin/calc_geo_cto data/samples_pred/historical/AWI-ESM-1-1-LR input/tas/historical/AWI-ESM-1-1-LR data/geo_cto/historical/all/AWI-ESM-1-1-LR.nc
```


#### plot\_geo\_cto [Figure 3, 6, 7, S7, S8, S12]


```
Plot geographical distribution of cloud type occurrence.

Usage: plot_geo_cto INPUT ECS OUTPUT [OPTIONS]

Arguments:

  INPUT   Input directory. The output of calc_geo_cto (NetCDF).
  ECS     ECS file (CSV).
  OUTPUT  Output plot (PDF).

Options:

  degree: VALUE      Degree. One of: 0 (absolute value) or 1 (trend). Default: 0.
  relative: VALUE    Plot relative to CERES. One of: true or false. Default: true.
  normalized: VALUE  Plot normaized CERES. One of: true, false, only.  Default: false.
  with_ref: VALUE    Plot reference row. One of: true, false. Default: true.

Examples:

bin/plot_geo_cto data/geo_cto/historical/part_1 input/ecs/ecs.csv plot/geo_cto_historical_1.pdf
bin/plot_geo_cto data/geo_cto/historical/part_2 input/ecs/ecs.csv plot/geo_cto_historical_2.pdf
```


#### plot\_cto\_rmse\_ecs [Figure 12, S9–11]


```
Plot scatter plot of RMSE of the geographical distribution of cloud type occurrence and sensitivity indicators (ECS, TCR and cloud feedback).

Usage: plot_cto_rmse_ecs INPUT ECS OUTPUT [OPTIONS]

Arguments:

  INPUT   Input directory. The output of calc_geo_cto or calc_cto (NetCDF).
  ECS     ECS file (CSV).
  OUTPUT  Output plot (PDF).

Options:

  legend: VALUE  Plot legend ("true" or "false"). Default: "true".

Examples:

bin/plot_cto_rmse_ecs data/geo_cto/historical/all input/ecs/ecs.csv plot/geo_cto_rmse_ecs.pdf
```


#### plot\_cto [Figure 9, S4–6]


```
Plot global mean cloud type occurrence.

Usage: plot_cto VARNAME DEGREE ABSREL REGRESSION INPUT ECS OUTPUT TITLE [OPTIONS]

Arguments:

  VARNAME     Variable name. One of: "ecs" (ECS), "tcr" (TCR), "cld" (cloud feedback).
  DEGREE      One of: "0" (mean), "1-time" (trend in time), "1-tas" (trend in tas).
  ABSREL      One of "absolute" (absolute value), "relative" (relative to CERES).
  REGRESSION  Plot regression. One of: true or false.
  INPUT       Input directoy. The output of calc_geo_cto (NetCDF).
  ECS         ECS file (CSV).
  OUTPUT      Output plot (PDF).
  TITLE       Plot title.

Options:

  legend: VALUE  Show legend ("true" or "false"). Default: "true".

Examples:

bin/plot_cto ecs 0 relative false data/geo_cto/historical/ input/ecs/ecs.csv plot/cto_historical.pdf 'CMIP6 historical (2003-2014) and reanalyses (2003-2020) relative to CERES (2003-2020)'
bin/plot_cto ecs 1-tas absolute false data/geo_cto/abrupt-4xCO2/ input/ecs/ecs.csv plot/cto_abrupt-4xCO2.pdf 'CMIP abrupt-4xCO2 (first 100 years)'
```


#### calc\_cto\_ecs


```
Calculate cloud type occurrence vs. ECS regression.

Usage: calc_cto_ecs INPUT ECS OUTPUT

Arguments:

  INPUT   Input directory. The output of calc_geo_cto (NetCDF).
  ECS     ECS, TCR and CLD input (CSV).
  OUTPUT  Output file (NetCDF).

Examples:

bin/calc_cto_ecs data/geo_cto/abrupt-4xCO2/ input/ecs/ecs.csv data/cto_ecs/cto_ecs.nc
```


#### plot\_cto\_ecs [Figure 11]


```
Plot cloud type occurrence vs. ECS regression.

Usage: plot_cto_ecs VARNAME INPUT SUMMARY OUTPUT

Arguments:

  VARNAME  Variable name. One of: "ecs" (ECS), "tcr" (TCR), "cld" (cloud feedback).
  INPUT    Input file. The output of calc_cto_ecs (NetCDF).
  OUTPUT   Output plot (PDF).

Examples:

bin/plot_cto_ecs ecs data/cto_ecs/cto_ecs.nc plot/cto_ecs.pdf
```


#### calc\_cloud\_props


```
Calculate statistics of cloud properties by cloud type.

Usage: calc_cloud_props TYPE CTO INPUT OUTPUT [OPTIONS]

Arguments:

  TYPE    Type of input data. One of: "ceres" (CERES), "cmip" (CMIP), "era5" (ERA5), "noresm2" (NorESM2), "merra2" (MERRA-2).
  CTO     Cloud type occurrence. The output of calc_geo_cto (NetCDF).
  INPUT   CMIP cloud property (clt, cod or pctisccp) directory (NetCDF) or CERES SYN1deg (NetCDF).
  OUTPUT  Output file (NetCDF).

Options:

  classes: VALUE  Classification. One of: 0 (4 cloud types), 1 (10 cloud genera), 2 (27 cloud genera). Default: 0.

Examples:

bin/calc_cloud_props cmip data/geo_cto/historical/all/UKESM1-0-LL.nc input/cmip6/historical/day/by-model/UKESM1-0-LL/ data/cloud_props/UKESM1-0-LL.nc
```


#### plot\_cloud\_props [Figure 11]


```
Usage: plot_cloud_prop VAR INPUT ECS OUTPUT [OPTIONS]

Arguments:

  VAR     Variable. One of: "clt", "cod", "pct".
  INPUT   Input directory. The output of calc_cloud_props (NetCDF).
  ECS     ECS file (CSV).
  OUTPUT  Output plot (PDF).

Options:

  legend: VALUE  Plot legend ("true" or "false"). Default: "true".

Examples:

bin/plot_cloud_props clt data/cloud_props/ input/ecs/ecs.csv plot/cloud_props_clt.pdf
bin/plot_cloud_props cod data/cloud_props/ input/ecs/ecs.csv plot/cloud_props_cod.pdf
bin/plot_cloud_props pct data/cloud_props/ input/ecs/ecs.csv plot/cloud_props_pct.pdf
```


#### plot\_station\_corr [Figure S3]


```
Plot spatial and temporal correlation of stations.

Usage: bin/plot_station_corr TYPE INPUT1 INPUT2 OUTPUT

Arguments:

  TYPE    One of: "time" (time correlation), "space" (space correlation).
  INPUT1  Input file. The output of calc_idd_geo (NetCDF).
  INPUT2  Input file. The output of calc_geo_cto (NetCDF).
  OUTPUT  Output plot (PDF).
```


#### calc\_idd\_geo


```
Calculate geographical distribution of cloud types from IDD data.

Usage: calc_idd_geo SYNOP BUOY FROM TO OUTPUT

Arguments:

  SYNOP   Input synop directory (NetCDF).
  BUOY    Input buoy directory (NetCDF).
  FROM    From date (ISO).
  TO      To date (ISO).
  OUTPUT  Output file (NetCDF).

Options:

  classes: VALUE     Classification. One of: 0 (4 cloud types), 1 (10 cloud genera), 2 (27 cloud genera). Default: 0.
  resolution: VALUE  Resolution (degrees). Default: 5. 180 must be divisible by VALUE.

Examples:

bin/calc_idd_geo input/idd/{synop,buoy} 2007-01-01 2007-12-31 data/idd_geo/2007.nc classes: 1
```


#### plot\_idd\_n\_obs [Figure S2]


```
Plot a map showing the number of observations in IDD.

Usage: bin/plot_idd_n_obs INPUT OUTPUT

Arguments:

  INPUT   Input dataset. The output of calc_idd_geo (NetCDF).
  OUTPUT  Output plot (PDF).
```


#### merge\_xval\_geo\_cto


```

Merge cross validation geographical distribution of cloud type occurrence.

Usage: bin/merge_xval_geo_cto [INPUT...] [AREA...] OUTPUT

Arguments:

  INPUT   The output of calc_geo_cto (NetCDF).
  AREA    Area of input to merge the format { LAT1 LAT2 LON1 LON2 }. The number of area arguments must be the same as the number of input arguments.
  OUTPUT  Output file (NetCDF).
```


#### plot\_validation [Figure 4]


```
Calculate cross-validation statistics.

Usage: bin/plot_validation IDD_VAL IDD_TRAIN INPUT... OUTPUT [OPTIONS]

Arguments:

  IDD_VAL    Validation IDD dataset. The output of calc_idd_geo for validation years (NetCDF).
  IDD_TRAIN  Training IDD dataset. The output of calc_idd_geo for training years (NetCDF).
  INPUT      CERES dataset. The output of calc_geo_cto or merge_xval_geo_cto (NetCDF).
  OUTPUT     Output plot (PDF).

Options:

  --normalized  Plot normalized plots.

Examples:

bin/plot_validation data/idd_geo/{validation,training}.nc data/geo_cto/historical/all/CERES.nc data/xval/geo_cto/CERES_sectors.nc plot/validation.pdf
```


#### calc\_val\_stats


```
Calculate cross-validation statistics.

Usage: bin/calc_val_stats INPUT IDD OUTPUT [OPTIONS]

Arguments:

  INPUT   Validation CERES/ANN dataset. The output of calc_geo_cto for validation years (NetCDF).
  IDD     Validation IDD dataset. The output of calc_idd_geo for validation years (NetCDF).
  OUTPUT  Output file (NetCDF).

Options:

  area: { LAT1 LAT2 LON1 LON2 }  Area to validate on.
  train_idd: VALUE               Training IDD input. The output of calc_idd_geo for training years (NetCDF). If specified, the uninformative predictor is calculated from the training years.

Examples:

bin/calc_val_stats data/xval/na/geo_cto/historical/all/CERES.nc data/idd_geo/IDD.nc data/val_stats/NE.nc area: { 0 90 -180 0 }
```


#### plot\_roc [Figure 5]


```
Plot ROC validation curves.

Usage: bin/plot_roc INPUT OUTPUT TITLE

Arguments:

  INPUT   Input data. The output of calc_val_stats (NetCDF).
  OUTPUT  Output plot (PDF)
  TITLE   Plot title.
```


### Auxiliary commands

#### build\_readme


```
Build the README document from a template.

Usage: build_readme INPUT BINDIR OUTPUT

Arguments:

  INPUT   Input file.
  BINDIR  Directory with scripts.
  OUTPUT  Output file.

Examples:

bin/build_readme README.md.in bin README.md
```


#### download\_cmip


```
Download CMIP data based on a JSON catalogue downloaded from the CMIP archive search page.

Usage: download_cmip FILENAME VAR START END

Arguments:

  FILENAME  Input file (JSON).
  VAR       Variable name.
  START     Start time (ISO).
  END       End time (ISO).

Examples:

bin/download_cmip catalog.json tas 1850-01-01 2014-01-01 > files
```


#### create\_by\_model

```
Create a by-model index of CMIP data. This command should be run in the
directory with CMIP data.

Usage: create_by_model

Examples:

cd data/cmip5/historical/day
./create_by_model
```

#### create\_by\_var

```
Create a by-var index of CMIP data. This command should be run in the
directory with CMIP data.

Usage: create_by_var

Examples:

cd data/cmip5/historical/day
./create_by_var
```

#### gistemp\_to\_nc


```
Convert GISTEMP yearly temperature data to NetCDF.

Usage: gistemp_to_nc INPUT OUTPUT

Arguments:

  INPUT   Input file "totalCI_ERA.csv" (CSV).
  OUTPUT  Output file (NetCDF).

Examples:

bin/gistemp_to_nc data/gistemp/totalCI_ERA.csv data/gistemp/gistemp.nc
```


## License

The code in this repository is open source, and can be used and distributed
freely under the terms of an MIT license. Plase see [LICENSE.md](LICENSE.md)
for details.
