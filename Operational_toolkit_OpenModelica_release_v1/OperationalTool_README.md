# ELEGANCY_D4.5.2
This document provides a brief description of the files submitted as part of D4.5.2 of the ELEGANCY project. 
The files within this folder consist of the necessary models/ information for users to implement 
the ***dynamic simulation*** tool developed as part of the ELEGANCY project. 

## Distribution chain ***simulation*** tool


### "ELEGANCY_deliberable_4.5.2 - Block Diagram Implementation.pdf"
Schematic describing the workflow between different parts of the ELEGANCY project:
- The design tool
- The operational tool
- The reduced order modelling tool (CONSUMET)

### "ELEGANCY_deliverable_4.5.2 - User manual and model documentation for the dynamic operational tool.pdf"
Document detailing whole chain dynamic simulation tool:
- Equations used for various components in the chain
- User guide for running the OpenModelica implementation of the tool, along with some specific examples.

###"Operational_Toolkit_v2.mo"
Modelica model for the final dynamic operational tool, consisting of:
- Models for various units (pipes, compressors, storage, production, etc.)
- Specific examples with connections which can be run.

###"domestic_demand_normalized.txt"
Table read by some classes within the operational toolkit, consiting of a hydrogen demand signal for domestic heating as a function of time. 

###"CONSUMET_to_Modelica.py"
Example Python function to generate the modelica code for the regression output of the CONSUMET tool.

###"regression.csv"
Output of CONSUMET regression consisting of coefficients of a Taylor Expansion


