# Change Trajectories of Couples Therapy
Different couples can exhibit unique change patterns over the course of a couples therapy.
This project explores the linear and nonlinear trajectories in couples therapy by leveraging
`changepoint` package by Killick et al. (2014). You can compare the goodness-of-fit 
for linear and nonlinear modeling of the change trajectories for couples.

This project includes following functions:  

1) Find the critical change points in the routine outcome monitoring of each partner  
2) Compare the goodness-of-fit for linear, loglinear, quadratic, cubic, and changepoint models
using the McFadden's pseudo R-squared  
3) Examine the similarity of the change patterns between the partners to see if they change
in synchrony. Considering the lead-lag effects, you can also specify the time delay for up 
to 2 time points (see `config.R` for more details)

## Copy the repository
```bash
git clone https://github.com/XinY-Z/chg_traj_couple
```

## Installation
```r
install.packages("data.table")
install.packages("changepoint")
```

## Usage
First, open the `config.R` file and specify `'coupleid`, `partnerid`, and `outcome`
variables. These variables should match the couple id, partner id, and outcome variable
in your dataset. Save it and run the following command in R console.

```r
source("run.R")
# When you run the script, you will be prompted to enter the file path of your data.
```

## Data
The data should be in a long format with the following columns:  
- `coupleid`: Unique couple identifier  
- `partnerid`: Unique partner identifier  
- `time`: Time point of the measurement  
- `outcome`: Outcome variable of interest  

## Example
```r
# Customize configuration
source("config.R")
config$coupleid <- <your couple id variable>
config$partnerid <- <your partner id variable>
config$outcome <- <your outcome variable>
# save to config.R

# Run the script
source("run.R")

# Enter the file path of the data
> data/example_data.csv

# This will return three dataframes

# Critical Change Points
   coupleid partnerid change_point
1         1         1          3,5
2         1         2          2,3
3         2         1           
4         2         2      6,12,16

# McFadden's Pseudo R-squared
   coupleid partnerid changepoint linear loglinear  quad  cube
1         1         1       0.000  0.031     0.099 0.016 0.013
2         1         2       0.000  0.109     0.203 0.074 0.059
3         2         1       0.196  0.107     0.080 0.097 0.075
4         2         2       0.145  0.018     0.054 0.005 0.002

# Similarity of Change Patterns
   coupleid similarity    type
1         1      0.000 jaccard
2         2      0.000 jaccard
3         3      0.167 jaccard

```

## License
This project is licensed under the Apache 2.0 License - see the LICENSE.md file for details.

## Acknowledgements
- Killick, R., & Eckley, I. A. (2014). *changepoint*: An R package for changepoint analysis. *Journal of Statistical Software, 58*(3). https://doi.org/10.18637/jss.v058.i03

## Citation
If you use this project in your research, please cite the following paper:  
```bibtex
@unpublished{zhang2023,
  title={Comparing Change Trajectories in Couples Therapy: A Data-Driven Approach},
  author={Zhang, Xinyao and Baucom, Brian R. W.},
  year={2023}
}
```
