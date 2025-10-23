# Calibration Data Analysis Script - README

## Purpose
This R script compiles calibration data from multiple SI-121 radiometer calibration runs and produces Figure 5 (panels a, b, c) showing the relationship between water bath temperature and measurement variability.

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
source("analyze_calibration_data.R")
```

### 3. Output Files
- `Figure_5_calibration_analysis.pdf` - Publication-quality figure
- `Figure_5_calibration_analysis.png` - High-resolution PNG (300 dpi)
- `compiled_calibration_data.csv` - Full dataset for additional analysis

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

## Excel File Structure Expected

The script expects each `.xlsm` file to have a "results" tab with:
- **Column G (7th column)**: Chubb Mean (water bath temperature in °C)
- **Column H (8th column)**: Chub SD (standard deviation in °C)
- **Data starting at row 18** (configurable via `data_start_row` parameter)

## Figure Description

**Figure 5a (HRH Calibrations):**
- Gray points: Individual measurements
- Black points: Binned means (1-K bins)
- Error bars: ±1 SD within each temperature bin
- Red line: Linear least-squares fit to binned data
- Y-axis in milliKelvin (mK)

**Figure 5b (HRL Calibrations):**
- Gray points: Individual measurements
- Black points: Binned means (1-K bins)
- Gray shaded region: ±1 SD from binned means
- Red line: Linear least-squares fit to binned data
- Y-axis in milliKelvin (mK)

**Figure 5c (Data Coverage):**
- Bar chart showing number of measurements per temperature bin
- Separate bars for HRH (orange) and HRL (blue)
- Helps assess data density across temperature range

## ASSUMPTIONS AND CLARIFICATIONS NEEDED

### [CLARIFICATION NEEDED] Data Structure
1. **Column positions**: Verify that Column G = Chubb Mean and Column H = Chub SD consistently across ALL calibration files
2. **Data start row**: Script assumes data begins at row 18. Verify this is consistent across all files
3. **Sheet name**: Script assumes results are in a sheet named "results" (case-sensitive)

### [CLARIFICATION NEEDED] File Identification
4. **Filename patterns**: Verify that all calibration files contain "cal" in the filename
5. **HRH/HRL identification**: Confirm that "HRH" and "HRL" appear in filenames (case-insensitive matching is used)

### [CLARIFICATION NEEDED] Analysis Parameters
6. **Temperature bin width**: Currently set to 1.0 K. Confirm this matches your requirements
7. **Unit conversion**: Script converts SD from °C to mK (×1000). Verify if this is appropriate

### [CLARIFICATION NEEDED] Temperature Range
8. The figure caption mentions "temperature range of xxx-zzz K (-4 - 60C)" - after running the script, verify the actual temperature range and update the figure caption accordingly

### [CLARIFICATION NEEDED] Chamber Temperature Context
9. The figure caption mentions "chamber temperatures at 269.15-303.15 K (-4 C and 30 C)" but the script currently doesn't extract chamber temperature from the files. Is this information:
   - Documented elsewhere and just provided as context?
   - Should be extracted from the Excel files (if so, which column)?
   - Standard values that don't need to be verified for each run?

## Troubleshooting

### "No calibration data found"
- Check that `root_dir` path is correct
- Verify folder names match pattern `yyyymmdd_calval`
- Check that .xlsm files exist and contain "cal" in filename

### "File has fewer than 8 columns"
- Verify that the "results" tab has at least 8 columns
- Check if `data_start_row` parameter needs adjustment

### Missing or incorrect data
- Check for NA values in Chubb Mean or Chub SD columns
- Verify that numeric data is stored as numbers, not text
- Check if different files have different column structures

### Linear fit warnings
- If few data points in certain temperature ranges, the linear fit may be unstable
- Review Figure 5c to identify temperature ranges with sparse data

## Modifying the Script

### Change temperature bin width
Line 24:
```r
bin_width <- 1.0  # Change to desired bin width in K
```

### Change data start row
Line 30:
```r
data_start_row <- 18  # Adjust if data starts at different row
```

### Modify figure appearance
Lines 213-280 contain all ggplot2 code for customizing:
- Point sizes and transparency
- Colors
- Axis labels
- Figure dimensions

### Export different file formats
Lines 286-293: Add additional ggsave() calls for other formats (e.g., TIFF, EPS)

## Contact & Support

If the script encounters issues:
1. Check the console output for specific error messages
2. Review the assumptions above
3. Verify your Excel file structure matches expectations
4. Check that all required R packages are installed

## Version History

**v1.0** (2025-01-27)
- Initial version
- Compiles HRH and HRL calibration data from multiple runs
- Generates Figure 5 (a, b, c)
- Exports compiled dataset as CSV
