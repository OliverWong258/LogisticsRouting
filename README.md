# Project Description

This project aims to solve the warehouse and transportation route optimization problem using various optimization algorithms (such as Two-Stage Simplex Method, Genetic Algorithm, and Simulated Annealing). The project also incorporates data visualization to display the results. Below is the file structure and functionality description.

## File Structure

### `data` Folder
Contains `.mat` files with experimental data and the optimal solutions obtained from different algorithms. The data includes:
- Number of warehouses
- Number of customers
- Coordinates
- Transportation capacity limits
- Optimal solutions from various algorithms

### `figures` Folder
Contains `.jpg` files with various visual results:
- Transportation route map
- Transportation matrix heatmap
- Fitness curve
- Supply balance bar chart

### `methods` Folder
Contains Matlab function code for the following three algorithms:
- Two-Stage Simplex Method
- Genetic Algorithm
- Simulated Annealing Algorithm

### `visualization` Folder
Contains Matlab function code for generating and outputting the visual results in the `figures` folder.

## Script Descriptions

### `main.m`
Main program script. When run, the user will be prompted to choose the corresponding optimization algorithm to find the optimal solution.

### `set_data.m`
Script for setting up and saving experimental data, including warehouse and customer parameters.

### `data_visual.m`
Script for visualizing the warehouse and customer locations, mainly for displaying the coordinate distribution.

### `transportation_flow.m`
Script for drawing transportation paths and transportation matrix heatmaps. The user will be prompted to select the corresponding algorithm when running the script.

### `balance_error.m` and `ub_violation.m`
Scripts to check constraint satisfaction. After running, users can choose an algorithm and verify whether the constraints are met.

## Usage Instructions

1. Run the `main.m` script in Matlab.
2. Follow the prompts to choose the optimization algorithm (Two-Stage Simplex Method, Genetic Algorithm, or Simulated Annealing).
3. Use other related scripts for data visualization or constraint checks.
