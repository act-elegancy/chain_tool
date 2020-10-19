Release date: 19/10/2020

Release purpose: Faciliatate design evaluations of hydrogen and CCS chains depending on user inputs.

*****Excel Files*****
1) Availability_Gridded - Operating asset availability in an indexed location.
2) Chain_LCA_Scores - Data on the life-cycle impacts of various production/ conversion technologies.
3) chain_tool_lca_scores - Full Excel workbook on the LCA impacts of all system components. This file is not necessary for optimisation and serves as a reference.
4) CO2_Stores_Gridded - The total CO2 storage capacity in an indexed location, reported in Mt. 
5) Demand_Gridded_# - Files denoting the demand for the various resources in the modelling tool.
6) Emission_Factor_Gridded - Described as the reduction in the CO2 emissions intensity on a location-by-location basis relative to the default assumptions. 
7) Emissions_Gridded - Spatially-indexed account of process emissions in a given region.
8) H2_Stores_Gridded - Spatially-indexed account of hydrogen storage availability. 
9) IEA-Hydrogen_cost_and_performance_data - self explanatory.
10) Linear_Distances_Gridded - File describing the linear distances between each of the indexed grids. 
11) Location_Factor_Gridded - Describes the variations in the cost of CO2 capture based on the asset in a given location. 
12) Network_LCA_Scores - Data on the life-cycle impacts of network options on the basis of each individual pipeline of 1 km length.
13) Onshore_grids - Defines the cells that are onshore using a binary.
14) Strg_LCA_scores - Defines the overall life-cycle impacts due to storing a unit of resource r. 
15) Import_Locations_Gridded - Identifies locations where importing resources is possible.

*****Python Scripts*****
1) RTN_implementation.py - Script containing the model with a focus on cost-optimisation.
2) RTN_implementation_min_LCA.py - Script with a focus on optimisation over LCA metrics under cost-constraints for Pareto-efficienct curves.
3) infeasible.py - Module to help users debug their models to identify constraint violations and infeasibilities.
4) key_performance_metrics - Post-processing script to evaluate the KPIs.
5) output_files.py - Core post-processing script with a range of output files.
6) variable_values.py - Optional post-processing script to use in the output evaluation process.

*****Other*****
1) RTN_implementation.dat - Core model dataset written in an AMPL data format.
2) results.yml - High-level simulation summary and output file printed with each run.
3) run_glpk_command_example - Command line submission for the use of glpk to run the model.
4) run_gurobi_command_example - Command line submission for the use of gurobi to run the model.

README.md - Script containing a one-line summary of key data files within the design toolkit directory. 