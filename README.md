# Calibration Data Analysis Script - README 

## Purpose
These scripts compile calibration data from multiple SI-121 radiometer calibration runs and produce figures showing the relationship between measurement variability (Chub SD) and water bath temperature.

## Required R Packages
```r
install.packages(c("readxl", "dplyr", "ggplot2", "tidyr", "stringr", "patchwork"))
```

## Usage

### 1. Set Root Directory
Edit line 17 in the script:
```r
root_dir <- "/path/to/calibration/data"  # MODIFY THIS PATH
```

### 2. Run Script
```r
source("analyze_calibration_data_CORRECTED.R")
```

### 3. Output Files
- `Figure_5_calibration_analysis.pdf` - Publication-quality figure
- `Figure_5_calibration_analysis.png` - High-resolution PNG (300 dpi)
- `compiled_calibration_data.csv` - Full dataset for additional analysis
- Console output includes suggested figure caption with actual temperature ranges

## Directory Structure Expected

```
root_directory/
├── 20170901_calval/
│   ├── rad518_cal_HRH-v0.0.xlsm
│   └── rad518_cal_HRL-v0.0.xlsm
├── 20171015_calval/
│   ├── subfolder/
│   │   ├── rad518_cal_HRH-v0.0.xlsm
│   │   └── rad518_cal_HRL-v0.0.xlsm
└── 20180203_calval/
    └── ...
```

**Notes:**
- Folder names must match pattern: `yyyymmdd_calval` (e.g., `20170901_calval`)
- Calibration files must contain "cal" in filename and have `.xlsm` extension
- Files must contain either "HRH" or "HRL" in filename to identify calibration type
- Script searches recursively through all subfolders

## Excel File Structure (VERIFIED)

Each `.xlsm` file has a "results" tab with:
- **Column G (7th column)**: Chubb Mean in centi-degrees C (divide by 100 to get °C)
- **Column H (8th column)**: Chub SD (standard deviation in °C)
- **Data starting at row 18**

## Chamber Temperatures (VERIFIED)

- **HRH calibrations**: 30°C chamber temperature
- **HRL calibrations**: 4°C chamber temperature

These are determined automatically from the filename (HRH vs HRL).

## Figure Description

**Figure 5a (HRH Calibrations):**
- **X-axis**: Chub SD (°C) - measurement variability
- **Y-axis**: Water bath temperature (°C)
- Gray points: Individual measurements
- Black points: Binned means (binned by Chub SD)
- Error bars: ±1 SD of temperature within each Chub SD bin
- Red line: Linear least-squares fit to binned data
- Title indicates chamber temperature (30°C)

**Figure 5b (HRL Calibrations):**
- **X-axis**: Chub SD (°C) - measurement variability
- **Y-axis**: Water bath temperature (°C)
- Gray points: Individual measurements
- Black points: Binned means (binned by Chub SD)
- Gray shaded region: ±1 SD of temperature from binned means
- Red line: Linear least-squares fit to binned data
- Title indicates chamber temperature (4°C)

**Figure 5c (Data Coverage):**
- Bar chart showing number of measurements per Chub SD bin
- Separate bars for HRH (orange) and HRL (blue)
- Helps assess data density across the Chub SD range

## Data Processing Details

### Key Transformation
Column G values are divided by 100 to convert from centi-degrees C to degrees C:
```r
temp_c = Column_G / 100
```

### Binning Strategy
Data is binned by Chub SD (X-axis) rather than by temperature. The default bin width is 0.001°C, but this can be adjusted in the script (line 32).

### Statistics Calculated
For each Chub SD bin:
- Mean temperature
- Standard deviation of temperature
- Number of measurements

## Adjustable Parameters

### Chub SD Bin Width
Line 32:
```r
bin_width <- 0.001  # Bin width in °C for Chub SD
```
You may need to adjust this based on the actual range of Chub SD values in your data. After the first run, check the console output showing "Chub SD range" to determine an appropriate bin width.

### Data Start Row
Line 29:
```r
data_start_row <- 18  # Row where data begins in results tab
```

## Verification Checklist

Before running, verify your files have:
- ✓ Column G = Chubb Mean (in centi-°C, needs division by 100)
- ✓ Column H = Chub SD (in °C)
- ✓ Data starts at row 18 in "results" tab
- ✓ "HRH" or "HRL" appears in filename
- ✓ Folder names match `yyyymmdd_calval` pattern

## Output Interpretation

### Console Output
The script provides:
1. Summary of files processed
2. Temperature and Chub SD ranges for HRH and HRL
3. Linear regression statistics
4. **Suggested figure caption** with actual temperature ranges

### Figure Interpretation
- **Positive slope**: Higher Chub SD associated with higher temperatures
- **Negative slope**: Higher Chub SD associated with lower temperatures
- **Scatter around trend line**: Indicates measurement variability
- **Error bars/shaded regions**: Show uncertainty within each Chub SD bin

## Troubleshooting

### "No calibration data found"
- Verify `root_dir` path is correct
- Check folder names match `yyyymmdd_calval` pattern
- Ensure .xlsm files exist with "cal" in filename

### Unexpected axis ranges
- Check if Column G needs division by 100 (values should be reasonable temperatures)
- Verify Column H values are in degrees C (typically 0.001 to 0.1 range)

### Too many/too few bins
- Adjust `bin_width` parameter based on Chub SD range
- Check console output for Chub SD range
- Typical values might be 0.001°C, but adjust as needed

### Missing data points
- Some bins may have zero measurements (normal if Chub SD distribution is sparse)
- Figure 5c helps identify which bins have sufficient data

## Expected Results

Based on typical calibration data:
- **HRH temperature range**: ~15-63°C
- **HRL temperature range**: ~-8-26°C  
- **Chub SD range**: Typically 0.01-0.05°C (but verify with your data)

## Figure Caption Template

After running the script, check the console output for a suggested figure caption with your actual temperature ranges filled in. Example format:

```
Figure 5. (a),(b) Dependence of water bath temperature on heating
variability (Chub SD) computed from a large range of calibration runs over
a temperature range of XXX-YYY K (ZZZ-WWW°C) with chamber temperatures
at 277.15 K (4°C) for HRL (b) and 303.15 K (30°C) for HRH (a) calibrations.
The fitted line is a least squares linear fit to the binned data.
The horizontal lines in (a) and the gray area in (b) are the uncertainty
estimates computed as the standard deviation from the mean of all calibration
data obtained within a given Chub SD bin (dots). (c) Number of data points
used per Chub SD bin.
```

## Modifications

### Change figure aesthetics
Lines 238-311 contain ggplot2 code for customizing:
- Point sizes (`size = 1`)
- Transparency (`alpha = 0.3`)
- Colors
- Line widths (`linewidth = 0.8`)

### Export additional formats
Add to lines 319-324:
```r
ggsave("Figure_5_calibration_analysis.tiff", 
       fig5_combined, 
       width = 7, height = 10, units = "in", dpi = 600)
```

### Subset by date range
After line 201, add:
```r
all_cal_data <- all_cal_data %>%
  filter(date >= as.Date("2020-01-01"))
```

## Version History

**v2.0** (2025-01-27) - CORRECTED VERSION
- Fixed axes: X = Chub SD, Y = Temperature
- Corrected unit conversion: Column G ÷ 100 = °C
- Removed mK conversion (keep everything in °C)
- Added chamber temperature column
- Fixed bin width for Chub SD axis
- Updated figure caption generation

**v1.0** (2025-01-27)
- Initial version (had axes reversed - DO NOT USE)
