from __future__ import division
import pyomo.environ 
from pyomo.core import *
from infeasible import log_infeasible_constraints, log_infeasible_bounds
from math import sqrt
from math import pow
from output_files import *
from key_performance_metrics import *

"""
Defines the abstract model entity in Pyomo for the H2-CCS chain tool
"""
model = AbstractModel()


"""
Define Scalars

"""
# Units: tons/year
NUM_GRIDS = 43
MAX_PROCESS_TECH_PER_CELL = 6
MAX_END_USE_TECH_PER_CELL = 100
MAX_STRG_TECH_PER_CELL = 35
MAX_DIST_TECH_PER_CELL = 2
INIT_CARBON_INTENSITY = 200 # Units: g/kWh
MINIMUM_ASSET_AVAILABILITY = 0.7
GWH_TO_MWH = 1000
MWH_TO_MJ = 3600
MWH_TO_KWH = 1000
TON_TO_GRAM = 1000000
KILOTON_TO_TON = 1000
MEGATON_TO_TON = TON_TO_GRAM 
CAPITAL_RECOVERY_FACTOR = 0.118740
BIG_M = 10000000000
BIO_AVAILABILITY_PER_YEAR = 80000000 # Units: tons/year
HHOUR_TO_SECONDS = 1800
HHOURS_IN_A_YEAR = 17520
NUM_YEARS_PER_TM = 1

OPTIMAL_COST = 4772729 
COST_PREMIUM = 1.15


""" 
Define relevant Strings 

"""
lca_objective_metric = 'CLIMATE_CHANGE_TOT'
name_for_hydrogen = 'CGAS_H2'
name_for_biomass = 'BIOMASS'
name_for_emitted_CO2 = 'EMITTED_CO2'
name_for_uncaptured_CO2 = 'GENERATED_CO2'
name_for_stored_offshore_CO2 = 'CLIQ_CO2_OFFSHORE'
name_for_stored_onshore_CO2 = 'CLIQ_CO2_ONSHORE'
captured_CO2 = name_for_stored_onshore_CO2
negative_emission_tech = 'NET'
geo_H2_storage = 'SALT_CAVERN'
demand_id_1 = 'DOMESTIC_HEAT'
demand_id_2 = 'INDUSTRIAL_HEAT'
demand_id_3 = 'ELECTRICITY'
demand_id_4 = 'MOBILITY_FUEL'


"""
Define Sets

"""

# Grid cells.
model.G = RangeSet(NUM_GRIDS)


# Minor time periods.
model.T = Set(ordered=True)


# Major time periods.
model.TM = Set(ordered=True)


# All resources.
model.R = Set(ordered=True)


# Importable resources.
model.IMP_R = Set(within=model.R)


# All resources that can be stored in this formulation.
model.STORAGE_R = Set(within=model.R)


# All H2 resources that can be stored in this formulation.
model.STORABLE_H2 = Set(within=model.STORAGE_R)


# All CO2 resources that can be stored in this formulation.
model.STORABLE_CO2 = Set(within=model.STORAGE_R)


# All technologies.
model.J = Set(ordered=True)


# Process technologies.
model.PROCESS_TECH = Set(within=model.J)


# End use technologies.
model.END_USE_TECH = Set(within=model.J)


# Incumbent end use technologies.
model.INCUMBENT_USE_TECH = Set(within=model.J)


# H2 end use technologies.
model.H2_USE_TECH = Set(within=model.J)


# Storage technologies.
model.STRG_TECH = Set(within=model.J)


# CO2 storage technologies.
model.CO2_STORAGE_TECH = Set(within=model.STRG_TECH)


# H2 storage technologies.
model.H2_STORAGE_TECH = Set(within=model.STRG_TECH)


# Post-combustion set - to classify constraints
model.POSTCOMB = Set(within=model.END_USE_TECH)


# Non post-combustion set - to classify constraints
model.NO_POSTCOMB = Set(within=model.END_USE_TECH)


# Performance metric definition.
model.M = Set(ordered=True)


# Performance metrics for LCA.
model.LCA_METRICS = Set(within=model.M)


# Distribution technologies.
model.D = Set(ordered=True)


# Hydrogen pipes.
model.HYDROGEN_PIPES = Set(within=model.D)


# CO2 pipes.
model.CO2_PIPES = Set(within=model.D)


# Onshore CO2 pipes.
model.ONSHORE_PIPES = Set(within=model.D)


# Offshore CO2 pipes.
model.OFFSHORE_PIPES = Set(within=model.D)


# Scenarios.
model.S = Set(ordered=True)


# Discrete operating modes for distribution tech.
model.DIST_MODE = Set(ordered=True)


"""
Define parameters
"""

# A parameter containing the LCA scores for various technologies.
model.LCA_SCORE = Param(model.J,model.LCA_METRICS,default=0)


# A parameter containing the LCA scores for network technologies.
model.NETWORK_LCA = Param(model.D,model.LCA_METRICS,default=0)


# A parameter containing the LCA scores for storage technologies.
model.STRG_LCA = Param(model.STRG_TECH,model.LCA_METRICS,default=0)


# Number of base time units within each minor time period.
model.OPER_TIME_INTERVAL = Param(model.T)


# The temporal variation relative to average within each minor time period.
model.OPER_TIME_SIGNAL = Param(model.R, model.T, default=1)


# Spatio-temporal discrete representation of demand for a given resource.
model.DEMAND = Param(model.R, model.G, model.T, model.TM, model.S, default=0, mutable=True)


# Capture fraction of generated emissions.
model.CO2_REMOVAL_FRACTION = Param(model.TM, default=0.9)


# Total CO2 storage capacity in each grid.
model.TOT_CO2_STORES = Param(model.G, default=0)


# Total CO2 storage capacity in each grid.
model.TOT_H2_STORES = Param(model.G, default=0)


# Distances between grid cells in km.
model.DISTANCE = Param(model.G,model.G)


# Weight of each metric in each major period.
model.OBJ_WEIGHT = Param(model.M, model.TM)


# Resource import metrics.
model.IMPORT_COEFF = Param(model.IMP_R, model.M, default=0)


# Network design metrics.
model.NETWORK_COEFF = Param(model.D, model.M, default=0)


# Flow metric coefficients.
model.FLOW_COEFF = Param(model.D, model.M, default=0)


# Nameplate capacity of technologies.
model.NAME_PLATE_CAP = Param(model.J,default=0)


# Exogenously imposed learning rate measured as a fraction..
model.LEARNING_RED = Param(model.J, model.TM, default=1)


# Maximum injection rate into the storage technology..
model.MAX_INJECTION_RATE = Param(model.STRG_TECH, default=0)


# Maximum retrieval rate into the storage technology..
model.MAX_RETRIEVAL_RATE = Param(model.STRG_TECH, default=0)


# Technology availability to define the start time of first investment.
model.TECH_AVAILABILITY = Param(model.J, model.TM, default=1)


# Capital investment metrics.
model.INV_COEFF = Param(model.J, model.M, model.TM, default=0)
def INV_COEFF_init(model,j,g,m,tm):
   return model.INV_COEFF[j,m,tm]


# Initialise the investment coefficient in each grid.
model.INV_COEFF_GRID = Param(model.J, model.G, model.M, model.TM, 
   default=0,
   initialize=INV_COEFF_init,
   mutable=True)


# Operational metrics due to producing H2.
model.PROCESS_COEFF = Param(model.J, model.M, model.TM, default=0, mutable=True)


# RTN production/consumption coefficients.
model.RESOURCE_CONV_RATE = Param(model.J, model.R, default=0)


# Maximum flow of resource through a distribution mode.
model.FLOW_RSRC_MAX = Param(model.D)


# Existing infrastructure containing process technologies.
model.INIT_TECH = Param(model.PROCESS_TECH, model.G, model.TM,
    default=0, \
    mutable=True)


# Existing storage infrastructure.
model.INIT_STRG = Param(model.R, model.STRG_TECH, model.G, model.TM, default=0, mutable=True)


# Resource availabilities in various locations as generation/ use rates.
model.INIT_RSRC = Param(model.R, model.G, model.T, model.TM, default=0, mutable=True)


# Existing distribution technologies in operation.
model.INIT_DIST = Param(model.G, model.G, model.D, model.TM, default=0, mutable=True)


# Emission Factor deviation for the source on the basis of fuel.
model.EMISSION_FACTOR = Param(model.G)


def EMISSION_FACTOR_init(model,r,g):
   if r == name_for_uncaptured_CO2:
       return model.EMISSION_FACTOR[g]
   else:
       return 0

# Emission factors for region specific emission sources.
model.RESOURCE_FACTOR = Param(model.R, model.G, 
default=0, initialize=EMISSION_FACTOR_init,
mutable=True)


# Probability of scenario occurence.
model.PROBABILITY = Param(model.S, default=1)


# Coefficients to describe the flow consumption parameter.
model.FLOW_CONSUMPTION_COEFF = Param(model.D, model.DIST_MODE, model.R, default=0, within=NonNegativeReals)


# Coefficients to describe the flow production parameter.
model.FLOW_PRODUCTION_COEFF = Param(model.D, model.DIST_MODE, model.R, default=0, within=NonNegativeReals)


# Parameter to indicate if a region, g is onshore or offshore.
model.ONSHORE_GRIDS = Param(model.G, within=NonNegativeReals)


# Demand for a specific resource in grid cell g.
model.DEMAND_1 = Param(model.G, within=NonNegativeReals)


# Demand for a specific resource in grid cell g.
model.DEMAND_2 = Param(model.G, within=NonNegativeReals)


# Demand for a specific resource in grid cell g.
model.DEMAND_3 = Param(model.G, within=NonNegativeReals)


# Demand for a specific resource in grid cell g.
model.DEMAND_4 = Param(model.G, within=NonNegativeReals)


# Import locations present - True (1)  or False (0).
model.IMPORT_LOCATIONS = Param(model.G)


# Location factor for variable cost as function of the location.
model.LOCATION_FACTOR = Param(model.G)


# Total amount of process emissions that are generated in a region.
model.EMISSIONS_GRIDDED = Param(model.G)


# Operational availability of the assets located in a particular region.
model.AVAILABILITY= Param(model.G)


def set_import_limit(model,imp_r,g):
    """ A function to define the import rates for importable resources."""
    if imp_r in model.IMP_R:
        if model.IMPORT_LOCATIONS[g] == 1:
            return BIG_M
        else:
            return 0


model.IMPORT_RSRC_MAX = Param(model.IMP_R, model.G,
    default=0,
    initialize=set_import_limit,
    mutable=True)


# Storage coefficient - operational effects due to storing.
model.STRG_COEFF = Param(model.STRG_TECH, model.M, default=0)


# Storage technology efficiency.
model.RETRIEVAL_EFFICIENCY = Param(model.STRG_TECH, default=1)


"""
Define the variables in the model
"""

# Binary to indicate if the location is using hydrogen as opposed to incumbent fuel.
model.hydrogen_use = Var(model.G, model.TM, \
    domain=Binary)


# Production rate of tech j in grid g period t major period tm.
model.prod_rate = Var(model.J, model.G, model.T, model.TM, model.S, \
domain=NonNegativeReals)


# Number of process tech in grid g major period tm.
model.num_process = Var(model.PROCESS_TECH, model.G, model.TM, model.S, \
    domain=NonNegativeIntegers, \
    bounds=(0,MAX_PROCESS_TECH_PER_CELL), \
    initialize=int(MAX_PROCESS_TECH_PER_CELL/2))


# Number of end use tech in grid g major period tm.
model.num_end_use = Var(model.END_USE_TECH, model.G, model.TM, model.S, \
    domain=NonNegativeReals, \
    bounds=(0,MAX_END_USE_TECH_PER_CELL), \
    initialize=int(MAX_END_USE_TECH_PER_CELL/2))


# Number of end use tech in grid g major period tm.
model.num_end_use_invest = Var(model.END_USE_TECH, model.G, model.TM, model.S, \
    domain=NonNegativeReals, \
    bounds=(0,MAX_END_USE_TECH_PER_CELL), \
    initialize=int(MAX_END_USE_TECH_PER_CELL/2))


# Number of units of PROCESS_TECH invested in at G in tm.
model.num_process_invest = Var(model.PROCESS_TECH, model.G, model.TM, model.S, \
    domain=NonNegativeIntegers, \
    bounds=(0,MAX_PROCESS_TECH_PER_CELL), \
    initialize=int(MAX_PROCESS_TECH_PER_CELL/2))


def num_strg_init(model,r,strg_tech,g,tm,s):
   """ Defines the storage unit constraints."""
   if r not in model.STORAGE_R :
      # No storage units to be used if the resource r is not in the set STORAGE_R.
      model.num_strg[r,strg_tech,g,tm,s].fixed = True
      return 0

   elif r in model.STORABLE_H2 and strg_tech in model.CO2_STORAGE_TECH:
      # No storage units to be used when the resource is H2 and tech is injection wells.
      model.num_strg[r,strg_tech,g,tm,s].fixed = True
      return 0

   elif r in model.STORABLE_CO2 and strg_tech in model.H2_STORAGE_TECH:
      # No temporary storage of CO2 in pressurised vessels.
      model.num_strg[r,strg_tech,g,tm,s].fixed = True
      return 0
   
   else:
      return None


# Number of storage tech j in grid g major period tm.
model.num_strg = Var(model.R, model.STRG_TECH, model.G, model.TM, model.S, \
    domain=NonNegativeIntegers, \
    bounds=(0,MAX_STRG_TECH_PER_CELL), \
    initialize=num_strg_init)


# Number of storage tech j invested in grid g major period tm.
model.num_strg_invest = Var(model.R, model.STRG_TECH, model.G, model.TM, model.S, \
    domain=NonNegativeIntegers, \
    bounds=(0,MAX_STRG_TECH_PER_CELL), \
    initialize=num_strg_init)


def retrieval_rate_init(model,r,g,strg_tech,t,tm,s):
    """ Defines constraints on the retrieval rate variable."""
    if r in model.STORAGE_R:
        if r in model.STORABLE_CO2:
            # CO2 cannot be retrieved from the storage technologies once after storage.
            model.retrieval_rate[r,g,strg_tech,t,tm,s].fixed = True
            return 0
        else:
            return None

    else:
        # No retrieval for resources that are not stored.
        model.retrieval_rate[r,g,strg_tech,t,tm,s].fixed = True
        return 0

# Retrieval rate of a resource from storage technologies.
model.retrieval_rate = Var(model.R, model.G, model.STRG_TECH, model.T, model.TM, model.S, \
    domain=NonNegativeReals, \
    bounds=(0,BIG_M), \
    initialize=retrieval_rate_init)


def storage_rate_init(model,r,g,strg_tech,t,tm,s):
    """ Defines constraints on the storage rate variable."""
    if r in model.STORAGE_R:
        if r in model.STORABLE_H2 and strg_tech in model.CO2_STORAGE_TECH:
            # H2 cannot be stored in injection wells.
            model.storage_rate[r,g,strg_tech,t,tm,s].fixed = True
            return 0            
        else:
            return None
    else :
        model.storage_rate[r,g,strg_tech,t,tm,s].fixed = True
        return 0

# Storage rate of a resource into storage technologies.
model.storage_rate = Var(model.R, model.G, model.STRG_TECH, model.T, model.TM, model.S, \
    domain=NonNegativeReals, \
    bounds=(0,BIG_M), \
    initialize=storage_rate_init)


# Inventory level for a resource in storage technologies.
model.inventory_rsrc = Var(model.R, model.G, model.STRG_TECH, model.T, model.TM, model.S, \
    domain=NonNegativeReals, \
    bounds=(0,BIG_M))


def initial_inventory_init(model,r,g,strg_tech,s):
    """ Defines initial inventory constraints."""
    model.initial_inventory[r,g,strg_tech,s].fixed = True
    return 0

# Initial inventory level for a resource from storage technologies.
model.initial_inventory = Var(model.R, model.G, model.STRG_TECH, model.S, \
    domain=NonNegativeReals, \
    bounds=(0,BIG_M), \
    initialize=initial_inventory_init)


def emission_rate_init(model,r,g,t,tm,s):
    """ Defines constraints for the emission rate variable. """
    if r == name_for_emitted_CO2 or r == name_for_uncaptured_CO2:
        return None
    else :
        model.emission_rate[r,g,t,tm,s].fixed = True
        return 0

# Net resource emission rate in cell g period t major period tm
model.emission_rate = Var(model.R, model.G, model.T, model.TM, model.S, \
    domain=NonNegativeReals, \
    initialize=emission_rate_init)


def flow_init(model, g, g1, d, dist_mode, t, tm, s):
   """ Defines flow variable constraints."""
   if g == g1 :
      model.flow_rate[g,g1,d,dist_mode,t,tm,s].fixed = True
      return 0
   elif model.DISTANCE[g,g1] <= 999:
      return None
   else :
      model.flow_rate[g,g1,d,dist_mode,t,tm,s].fixed = True
      return 0


def flow_bounds(model, g, g1, d, dist_mode, t, tm, s):
   """ Defines flow variable bounds."""
   if g == g1 :
      return (0, 0)
   elif model.DISTANCE[g,g1] <= 999 :
      return (0,BIG_M)
   else :
      return (0,0)


# Flow rate of resource r from grid g to g1 in t and tm.
model.flow_rate = Var(model.G, model.G, model.D, model.DIST_MODE, model.T, model.TM, model.S, \
 domain=NonNegativeReals, \
 initialize=flow_init, \
 bounds=flow_bounds)


# Total flow rate of resource r summed across all discrete distribution modes from grid g to g1 in t and tm.
model.total_flow_rate = Var(model.G, model.G, model.D, model.T, model.TM, model.S, \
 domain=NonNegativeReals, \
 initialize=0)


def import_bounds(model, r, g, t, tm, s):
   """ Defines import rate constraints for the set of importable resources."""
   if r in model.IMP_R :
      return (0, model.IMPORT_RSRC_MAX[r,g])
   else :
      return (0, 0)


# Import rate of a resource r in grid g at time t and major time tm.
model.import_rate = Var(model.R, model.G, model.T, model.TM, model.S, \
 domain=NonNegativeReals,bounds=import_bounds)


# Total value of metric m in major period tm.
model.total_metrics = Var(model.M, model.TM, model.S, domain=NonNegativeReals)


def num_dist_init(model,g,g1,d,tm,s):
   """ Defines constraints on the number of distribution technologies."""
   if g == g1 :
      model.num_dist[g,g1,d,tm,s].fixed = True
      return 0
   elif model.DISTANCE[g,g1] <= 999:
      return None
   else :
      model.num_dist[g,g1,d,tm,s].fixed = True
      return 0


# Number of distribution technologies built between g and g1 by tm.
model.num_dist = Var(model.G, model.G, model.D, model.TM, model.S, \
 domain=NonNegativeIntegers, \
 bounds=(0,MAX_DIST_TECH_PER_CELL), \
 initialize=num_dist_init)


# Number of distribution technologies built between g and g1 in tm.
model.num_dist_invest = Var(model.G, model.G, model.D, model.TM, model.S, \
 domain=NonNegativeIntegers, \
 bounds=(0,MAX_DIST_TECH_PER_CELL), \
 initialize=num_dist_init)


"""
Define the equations used in the model
"""

def eqn2_rule(model,process_tech,g,tm,s):
   """ Process technology capacity balance in each grid cell."""
   if tm > 1 :
      return model.num_process[process_tech,g,tm,s] == model.num_process[process_tech,g,tm-1,s] \
        + model.num_process_invest[process_tech,g,tm,s]
   else :
      return model.num_process[process_tech,g,tm,s] == model.num_process_invest[process_tech,g,tm,s] \
        + model.INIT_TECH[process_tech,g,tm]
model.eqn2 = Constraint(model.PROCESS_TECH, model.G, model.TM, model.S, rule=eqn2_rule)


def eqn3_rule(model,process_tech,g,t,tm,s):
    """ Production rate constraint for process tech in each cell."""
    return model.prod_rate[process_tech,g,t,tm,s] <= \
        model.num_process[process_tech,g,tm,s]*model.NAME_PLATE_CAP[process_tech]*model.TECH_AVAILABILITY[process_tech,tm]
model.eqn3 = Constraint(model.PROCESS_TECH,model.G,model.T,model.TM,model.S,rule=eqn3_rule)


def eqn3b_rule(model,end_use_tech,g,t,tm,s):
    """ Production rate constraint for end use tech in each cell."""
    return model.prod_rate[end_use_tech,g,t,tm,s] <= \
        model.num_end_use[end_use_tech,g,tm,s]*model.NAME_PLATE_CAP[end_use_tech]*model.TECH_AVAILABILITY[end_use_tech,tm]
model.eqn3b = Constraint(model.END_USE_TECH,model.G,model.T,model.TM,model.S,rule=eqn3b_rule)


def eqn4_rule(model,r,g,t,tm,s):
    """ Resource/Material balance constraint for each grid cell."""
    return 0 == \
        + sum(model.RESOURCE_CONV_RATE[process_tech,r]*model.prod_rate[process_tech,g,t,tm,s] \
            for process_tech in model.PROCESS_TECH) \
        + sum(model.RESOURCE_CONV_RATE[end_use_tech,r]*model.prod_rate[end_use_tech,g,t,tm,s]*(1-model.RESOURCE_FACTOR[r,g]) \
            for end_use_tech in model.END_USE_TECH) \
        + model.import_rate[r,g,t,tm,s] \
        + model.INIT_RSRC[r,g,t,tm] \
        + sum(sum(sum(model.FLOW_PRODUCTION_COEFF[d,dist_mode,r]*model.flow_rate[g1,g,d,dist_mode,t,tm,s] \
            for g1 in model.G if model.DISTANCE[g,g1] <= 999) for d in model.D) for dist_mode in model.DIST_MODE) \
        - sum(sum(sum(model.FLOW_CONSUMPTION_COEFF[d,dist_mode,r]*model.flow_rate[g,g1,d,dist_mode,t,tm,s] \
            for g1 in model.G if model.DISTANCE[g,g1] <= 999) for d in model.D) for dist_mode in model.DIST_MODE)\
        - model.DEMAND[r,g,t,tm,s] \
        - model.emission_rate[r,g,t,tm,s] \
        - sum(model.storage_rate[r,g,strg_tech,t,tm,s] for strg_tech in model.STRG_TECH) \
        + sum(model.RETRIEVAL_EFFICIENCY[strg_tech]*model.retrieval_rate[r,g,strg_tech,t,tm,s] \
            for strg_tech in model.STRG_TECH)
model.eqn4 = Constraint(model.R,model.G,model.T,model.TM,model.S,rule=eqn4_rule)


def eqn5_rule(model,g,g1,d,t,tm,s):
    """ Flow constraint for distribution technologies."""
    if model.DISTANCE[g,g1] <= 999 :
        return sum(model.flow_rate[g,g1,d,dist_mode,t,tm,s] for dist_mode in model.DIST_MODE) <= \
            model.num_dist[g,g1,d,tm,s] * model.FLOW_RSRC_MAX[d]
    else :
        return Constraint.NoConstraint
model.eqn5 = Constraint(model.G,model.G, model.D, model.T,model.TM, model.S, rule=eqn5_rule)


def eqn6_rule(model,r,strg_tech,g,tm,s):
   """ Storage technology unit balance in each grid cell."""
   if tm > 1 :
      return model.num_strg[r,strg_tech,g,tm,s] == model.num_strg[r,strg_tech,g,tm-1,s] \
        + model.num_strg_invest[r,strg_tech,g,tm,s]
   else :
      return model.num_strg[r,strg_tech,g,tm,s] == model.num_strg_invest[r,strg_tech,g,tm,s] \
        + model.INIT_STRG[r,strg_tech,g,tm]
model.eqn6 = Constraint(model.R, model.STRG_TECH, model.G, model.TM, model.S, rule=eqn6_rule)


def CO2_storage_rule(model,storable_co2,co2_storage_tech,g,tm,s):
   """ Equation to ensure that offshore and onshore storage is separated."""
   if storable_co2 == name_for_stored_onshore_CO2 and model.ONSHORE_GRIDS[g] == 0:
      return model.num_strg[storable_co2,co2_storage_tech,g,tm,s] == 0
   
   elif storable_co2 == name_for_stored_offshore_CO2 and model.ONSHORE_GRIDS[g] == 1:
      return model.num_strg[storable_co2,co2_storage_tech,g,tm,s] == 0
   
   else:
      return Constraint.NoConstraint
model.off_or_onshore = Constraint(model.STORABLE_CO2, model.CO2_STORAGE_TECH, model.G,\
      model.TM, model.S, rule=CO2_storage_rule)

 
def eqn8_rule(model,r,g,strg_tech,t,tm,s):
    """ Storage inventory capacity constraint."""
    if r not in model.STORAGE_R:
        return Constraint.NoConstraint
    else:
        if strg_tech not in model.CO2_STORAGE_TECH:
            return model.inventory_rsrc[r,g,strg_tech,t,tm,s] <= \
            model.num_strg[r,strg_tech,g,tm,s]*model.NAME_PLATE_CAP[strg_tech]
        else:
            return Constraint.NoConstraint
model.eqn8 = Constraint(model.R, model.G, model.STRG_TECH, model.T, model.TM, model.S, rule=eqn8_rule)


def eqn7a_rule(model,tm,s):
   """ Total metrics calculaton - CAPEX."""
   return model.total_metrics['CAPEX',tm,s] == \
    sum(sum(model.INV_COEFF_GRID[process_tech,g,'CAPEX',tm]*model.num_process_invest[process_tech,g,tm,s] \
        for process_tech in model.PROCESS_TECH) for g in model.G) \
    + sum(sum(model.INV_COEFF_GRID[end_use_tech,g,'CAPEX',tm]*model.num_end_use_invest[end_use_tech,g,tm,s] \
        for end_use_tech in model.END_USE_TECH) for g in model.G) \
    + sum(sum(sum(model.PROCESS_COEFF[process_tech,'CAPEX',tm]*model.prod_rate[process_tech,g,t,tm,s]*model.OPER_TIME_INTERVAL[t] \
        for process_tech in model.PROCESS_TECH) for g in model.G) for t in model.T) \
    + sum(sum(sum(model.PROCESS_COEFF[end_use_tech,'CAPEX',tm]*model.prod_rate[end_use_tech,g,t,tm,s]*model.OPER_TIME_INTERVAL[t] \
        for end_use_tech in model.END_USE_TECH) for g in model.G) for t in model.T) \
    + sum(sum(sum (model.NETWORK_COEFF[d,'CAPEX']*model.DISTANCE[g,g1]*model.num_dist_invest[g,g1,d,tm,s] \
        for d in model.D) for g1 in model.G) for g in model.G) \
    + sum(sum(sum(sum(sum(model.FLOW_COEFF[d,'CAPEX']*model.flow_rate[g,g1,d,dist_mode,t,tm,s]*model.OPER_TIME_INTERVAL[t] \
        for dist_mode in model.DIST_MODE) for g1 in model.G) for g in model.G) for t in model.T) for d in model.D)\
    + sum(sum(sum(model.IMPORT_COEFF[imp_r,'CAPEX']*model.import_rate[imp_r,g,t,tm,s]*model.OPER_TIME_INTERVAL[t] \
        for imp_r in model.IMP_R) for g in model.G) for t in model.T) \
    + sum(sum(sum(model.INV_COEFF_GRID[strg_tech,g,'CAPEX',tm]*model.num_strg_invest[r,strg_tech,g,tm,s] \
        for strg_tech in model.STRG_TECH) for g in model.G) for r in model.R) \
    + sum(sum(sum(sum(model.STRG_COEFF[strg_tech,'CAPEX']*model.inventory_rsrc[r,g,strg_tech,t,tm,s] \
        for strg_tech in model.STRG_TECH) for g in model.G) for r in model.R) for t in model.T)
model.eqn7a = Constraint(model.TM,model.S,rule=eqn7a_rule)


def eqn7b_rule(model,tm,s):
   """ Total metrics calculaton - OPEX."""
   return model.total_metrics['OPEX',tm,s] == \
    sum(sum(model.INV_COEFF_GRID[process_tech,g,'OPEX',tm]*model.num_process[process_tech,g,tm,s] \
        for process_tech in model.PROCESS_TECH) for g in model.G) \
    + sum(sum(model.INV_COEFF_GRID[end_use_tech,g,'OPEX',tm]*model.num_end_use[end_use_tech,g,tm,s] \
        for end_use_tech in model.END_USE_TECH) for g in model.G) \
    + sum(sum(sum(model.PROCESS_COEFF[process_tech,'OPEX',tm]*model.prod_rate[process_tech,g,t,tm,s]*model.OPER_TIME_INTERVAL[t]*model.AVAILABILITY[g] \
        for process_tech in model.PROCESS_TECH) for g in model.G) for t in model.T) \
    + sum(sum(sum(model.PROCESS_COEFF[no_postcomb,'OPEX',tm]*model.prod_rate[no_postcomb,g,t,tm,s]*model.OPER_TIME_INTERVAL[t]*model.AVAILABILITY[g] \
        for no_postcomb in model.NO_POSTCOMB) for g in model.G) for t in model.T) \
    + sum(sum(sum(model.PROCESS_COEFF[postcomb,'OPEX',tm]*model.LOCATION_FACTOR[g]*model.prod_rate[postcomb,g,t,tm,s]*model.OPER_TIME_INTERVAL[t]*model.AVAILABILITY[g] \
        for postcomb in model.POSTCOMB) for g in model.G) for t in model.T) \
    + sum(sum(sum (model.NETWORK_COEFF[d,'OPEX']*model.DISTANCE[g,g1]*model.num_dist[g,g1,d,tm,s] \
        for d in model.D) for g1 in model.G) for g in model.G) \
    + sum(sum(sum(sum(sum(model.FLOW_COEFF[d,'OPEX']*model.flow_rate[g,g1,d,dist_mode,t,tm,s]*model.OPER_TIME_INTERVAL[t]*model.AVAILABILITY[g] for dist_mode in model.DIST_MODE) for g1 in model.G) for g in model.G) for t in model.T) for d in model.D) \
    + sum(sum(sum(model.IMPORT_COEFF[imp_r,'OPEX']*model.import_rate[imp_r,g,t,tm,s]*model.OPER_TIME_INTERVAL[t]*model.AVAILABILITY[g] for imp_r in model.IMP_R) for g in model.G) for t in model.T) \
    + sum(sum(sum(model.INV_COEFF_GRID[strg_tech,g,'OPEX',tm]*model.num_strg[r,strg_tech,g,tm,s] \
        for strg_tech in model.STRG_TECH) for g in model.G) for r in model.R) \
    + sum(sum(sum(sum(model.STRG_COEFF[strg_tech,'OPEX']*model.inventory_rsrc[r,g,strg_tech,t,tm,s] \
        for strg_tech in model.STRG_TECH) for g in model.G) for r in model.R) for t in model.T)
model.eqn7b = Constraint(model.TM,model.S,rule=eqn7b_rule)


def eqn7c_rule(model,lca_metrics,tm,s):
   """ Total metrics calculaton - LCA metrics."""
   return model.total_metrics[lca_metrics,tm,s] == \
      sum(sum(sum(model.LCA_SCORE[j,lca_metrics]*( \
       model.prod_rate[j,g,t,tm,s]*model.OPER_TIME_INTERVAL[t]*model.AVAILABILITY[g]) \
          for j in model.J) for g in model.G) for t in model.T) \
          + sum(sum(sum (model.NETWORK_LCA[d,lca_metrics]*model.DISTANCE[g,g1]*model.num_dist[g,g1,d,tm,s] \
          for d in model.D) for g1 in model.G) for g in model.G) \
          + sum(sum(sum(sum(model.STRG_LCA[strg_tech,lca_metrics]*model.inventory_rsrc[r,g,strg_tech,t,tm,s] \
          for strg_tech in model.STRG_TECH) for g in model.G) for r in model.R) for t in model.T)
model.eqn7c = Constraint(model.LCA_METRICS, model.TM, model.S, rule=eqn7c_rule)


def eqn9_rule(model,g,g1,d,tm,s):
   """ Distribution units balance in each grid cell."""
   if tm > 1 :
      return model.num_dist[g,g1,d,tm,s] == model.num_dist[g,g1,d,tm-1,s] \
        + model.num_dist_invest[g,g1,d,tm,s]
   else :
      return model.num_dist[g,g1,d,tm,s] == model.num_dist_invest[g,g1,d,tm,s] \
        + model.INIT_DIST[g,g1,d,tm]
model.eqn9 = Constraint(model.G, model.G, model.D, model.TM, model.S, rule=eqn9_rule)


def eqn10_rule(model,g,g1,tm,s):
    """ GUB Constraint - single H2 pipeline between any two grids - unidirectional flow."""
    return sum(model.num_dist[g,g1,hydrogen_pipes,tm,s] + model.num_dist[g1,g,hydrogen_pipes,tm,s] \
	for hydrogen_pipes in model.HYDROGEN_PIPES) <= 1
model.eqn10 = Constraint(model.G, model.G, model.TM, model.S, rule=eqn10_rule)


def eqn12a_rule(model,g,co2_storage_tech,t,tm,s):
    """ CO2 storage capacity constraint based on available geological volume."""
    if model.ONSHORE_GRIDS[g] == 0:
        return model.inventory_rsrc[name_for_stored_offshore_CO2,g,co2_storage_tech,t,tm,s] \
            <= MEGATON_TO_TON*model.TOT_CO2_STORES[g]
    else:
        return model.inventory_rsrc[name_for_stored_onshore_CO2,g,co2_storage_tech,t,tm,s] \
            <= MEGATON_TO_TON*model.TOT_CO2_STORES[g]
model.eqn12a = Constraint(model.G, model.CO2_STORAGE_TECH, model.T, model.TM, model.S, rule=eqn12a_rule)


def eqn12b_rule(model,g,t,tm,s):
    """ H2 storage capacity constraint based on available geological volume."""
    return model.inventory_rsrc[name_for_hydrogen,g,geo_H2_storage,t,tm,s] \
            <= MWH_TO_MJ*model.TOT_H2_STORES[g]
model.eqn12b = Constraint(model.G, model.T, model.TM, model.S, rule=eqn12b_rule)


def eqn11_rule(model,tm,s):
    """ CO2 constraint based on desired CO2 removal fraction """
    return (1-model.CO2_REMOVAL_FRACTION[tm])*INIT_CARBON_INTENSITY >= \
        sum(sum(TON_TO_GRAM*model.OPER_TIME_INTERVAL[t]*model.AVAILABILITY[g]*( \
              model.emission_rate[name_for_emitted_CO2,g,t,tm,s] \
            + model.emission_rate[name_for_uncaptured_CO2,g,t,tm,s] \
            - model.prod_rate[negative_emission_tech,g,t,tm,s]) \
            for g in model.G) for t in model.T)/sum(1 + \
            HHOUR_TO_SECONDS*HHOURS_IN_A_YEAR*(model.DEMAND_1[g1] + model.DEMAND_2[g1] \
            + model.DEMAND_3[g1] + model.DEMAND_4[g1])*model.AVAILABILITY[g1] for g1 in model.G) 
model.eqn11 = Constraint(model.TM, model.S, rule=eqn11_rule)


def eqn13_rule(model,storage_r,g,strg_tech,t,tm,s):
    """ General injection rate constraint."""
    return model.storage_rate[storage_r,g,strg_tech,t,tm,s] <= model.MAX_INJECTION_RATE[strg_tech]
model.eqn13 = Constraint(model.STORAGE_R, model.G, model.STRG_TECH, model.T, model.TM, model.S, rule=eqn13_rule)


def eqn14_rule(model,storage_r,g,strg_tech,t,tm,s):
    """ General retrieval rate constraint."""
    return model.retrieval_rate[storage_r,g,strg_tech,t,tm,s] <= model.MAX_RETRIEVAL_RATE[strg_tech]
model.eqn14 = Constraint(model.STORAGE_R, model.G, model.STRG_TECH, model.T, model.TM, model.S, rule=eqn14_rule)


def eqn15_rule(model,r,g,strg_tech,t,tm,s):
    """ Storage inventory balance."""
    if t == 1 and tm == 1:
        return model.inventory_rsrc[r,g,strg_tech,t,tm,s] == model.initial_inventory[r,g,strg_tech,s]\
        + model.OPER_TIME_INTERVAL[t]*(model.storage_rate[r,g,strg_tech,t,tm,s] \
        - model.retrieval_rate[r,g,strg_tech,t,tm,s])
    elif t == 1 and tm >= 1:
        return model.inventory_rsrc[r,g,strg_tech,t,tm,s] == \
        model.inventory_rsrc[r,g,strg_tech,model.T[-1],tm-1,s] \
        + model.OPER_TIME_INTERVAL[t]*(model.storage_rate[r,g,strg_tech,t,tm,s] \
        - model.retrieval_rate[r,g,strg_tech,t,tm,s])
    elif t != 1:
        return model.inventory_rsrc[r,g,strg_tech,t,tm,s] == \
        model.inventory_rsrc[r,g,strg_tech,t-1,tm,s] \
        + model.OPER_TIME_INTERVAL[t]*(model.storage_rate[r,g,strg_tech,t,tm,s] \
        - model.retrieval_rate[r,g,strg_tech,t,tm,s])
model.eqn15 = Constraint(model.R, model.G, model.STRG_TECH, model.T, model.TM, model.S, rule=eqn15_rule)


def eqn16a_rule(model,g,co2_storage_tech,t,tm,s):
    """ Injection rate limiting constraint for CO2."""
    if model.ONSHORE_GRIDS[g] == 0:
        return model.storage_rate[name_for_stored_offshore_CO2,g,co2_storage_tech,t,tm,s]*sum(model.OPER_TIME_INTERVAL[t1] for t1 in model.T) \
            <= model.num_strg[name_for_stored_offshore_CO2,co2_storage_tech,g,tm,s]*model.MAX_INJECTION_RATE[co2_storage_tech]
    else:
        return model.storage_rate[name_for_stored_onshore_CO2,g,co2_storage_tech,t,tm,s]*sum(model.OPER_TIME_INTERVAL[t1] for t1 in model.T) \
            <= model.num_strg[name_for_stored_onshore_CO2,co2_storage_tech,g,tm,s]*model.MAX_INJECTION_RATE[co2_storage_tech]
model.eqn16a = Constraint(model.G, model.CO2_STORAGE_TECH, model.T, model.TM, model.S, rule=eqn16a_rule)


def eqn16b_rule(model,g,co2_storage_tech,t,tm,s):
    """ Injection rate limiting constraint for CO2."""
    if model.ONSHORE_GRIDS[g] == 0:
        return model.storage_rate[name_for_stored_onshore_CO2,g,co2_storage_tech,t,tm,s] == 0
    else:
        return model.storage_rate[name_for_stored_offshore_CO2,g,co2_storage_tech,t,tm,s] == 0
model.eqn16b = Constraint(model.G, model.CO2_STORAGE_TECH, model.T, model.TM, model.S, rule=eqn16b_rule)


def eqn17_rule(model,g,g1,d,t,tm,s):
    """ Computes total flow rate across all distribution modes."""
    return model.total_flow_rate[g,g1,d,t,tm,s] == \
       sum(model.flow_rate[g,g1,d,dist_mode,t,tm,s] for dist_mode in model.DIST_MODE)
model.eqn17 = Constraint(model.G, model.G, model.D, model.T, model.TM, model.S, rule=eqn17_rule)


def eqn18_rule(model,g,g1,onshore_pipes,tm,s):
    """ Limits onshore pipes to onshore regions to differentiate pipeline costs."""
    if model.ONSHORE_GRIDS[g1] != 1:
        return model.num_dist[g,g1,onshore_pipes,tm,s] == 0
    else:
        return Constraint.NoConstraint
model.eqn18 = Constraint(model.G, model.G, model.ONSHORE_PIPES, model.TM, model.S, rule=eqn18_rule)


def eqn19_rule(model,tm,s):
    """ Ensure that total use of biomass is less than available amount."""
    return sum(sum(model.import_rate[name_for_biomass,g,t,tm,s]*model.OPER_TIME_INTERVAL[t] \
           for g in model.G) for t in model.T) <= BIO_AVAILABILITY_PER_YEAR*NUM_YEARS_PER_TM
model.eqn19 = Constraint(model.TM, model.S, rule=eqn19_rule)


def eqn20_rule(model,postcomb,g,t,tm,s):
   """ Ensures that post-combustion capture is applied to sources that are available 
     at least 50% of the time as opposed to ad-hoc."""
   if model.AVAILABILITY[g] <= MINIMUM_ASSET_AVAILABILITY:
       return model.prod_rate[postcomb,g,t,tm,s] == 0
   else:
       return Constraint.NoConstraint
model.eqn20 = Constraint(model.POSTCOMB, model.G, model.T, model.TM, model.S, rule=eqn20_rule)


def eqn21_rule(model,incumbent_use_tech,g,t,tm,s):
   """ This equation ensures that either H2 or the incumbent technology is used in a location. """
   return model.prod_rate[incumbent_use_tech,g,t,tm,s] <= (1-model.hydrogen_use[g,tm])*BIG_M
model.eqn21 = Constraint(model.INCUMBENT_USE_TECH, model.G, model.T, model.TM, model.S, rule=eqn21_rule)


def eqn22_rule(model,H2_use_tech,g,t,tm,s):
   """ This equation ensures that either H2 or the incumbent technology is used in a location. """
   return model.prod_rate[H2_use_tech,g,t,tm,s] <= model.hydrogen_use[g,tm]*BIG_M
model.eqn22 = Constraint(model.H2_USE_TECH, model.G, model.T, model.TM, model.S, rule=eqn22_rule)


def eqn23_rule(model,g,tm):
    """ Ensures that once you begin to use H2, you cannot transition backwards to old technologies. """
    if tm > 1:
        return model.hydrogen_use[g,tm] >= model.hydrogen_use[g,tm-1]
    else:
        return Constraint.NoConstraint
model.eqn23 = Constraint(model.G, model.TM, rule=eqn23_rule)


def eqn24_rule(model):
    """ Defines the constraint for cost."""
    return sum(sum(CAPITAL_RECOVERY_FACTOR*model.OBJ_WEIGHT['CAPEX',tm]*model.total_metrics['CAPEX',tm,s]*model.PROBABILITY[s] \
    for tm in model.TM) for s in model.S) \
    + sum(sum(model.OBJ_WEIGHT['OPEX',tm]*model.total_metrics['OPEX',tm,s]*model.PROBABILITY[s] \
    for tm in model.TM) for s in model.S) <= OPTIMAL_COST*COST_PREMIUM
model.eqn24 = Constraint(rule=eqn24_rule)


def obj_rule(model):
    """ Defines the objective function for the optimisation process."""
    return sum(sum(model.total_metrics[lca_objective_metric,tm,s]*model.PROBABILITY[s] \
    for tm in model.TM) for s in model.S)
model.obj = Objective(rule=obj_rule,sense=minimize)


"""
model customisation
"""


def set_resource_demand(instance):
   """ Defines the resource demand for the model instance."""
   for r in instance.R:
       for g in instance.G:
           for t in instance.T:
               for tm in instance.TM:
                   for s in instance.S:
                       if r == demand_id_1:
                           instance.DEMAND[r,g,t,tm,s].value = \
                              GWH_TO_MWH*MWH_TO_MJ*instance.OPER_TIME_SIGNAL[r,t]*instance.DEMAND_1[g]/sum(instance.OPER_TIME_INTERVAL[t1] for t1 in instance.T)
                       elif r == demand_id_2:
                           instance.DEMAND[r,g,t,tm,s].value = \
                              GWH_TO_MWH*MWH_TO_MJ*instance.OPER_TIME_SIGNAL[r,t]*instance.DEMAND_2[g]/sum(instance.OPER_TIME_INTERVAL[t1] for t1 in instance.T)
                       elif r == demand_id_3:
                           instance.DEMAND[r,g,t,tm,s].value = \
                              HHOUR_TO_SECONDS*HHOURS_IN_A_YEAR*instance.OPER_TIME_SIGNAL[r,t]*instance.DEMAND_3[g]/sum(instance.OPER_TIME_INTERVAL[t1] for t1 in instance.T)
                       elif r == demand_id_4:
                           instance.DEMAND[r,g,t,tm,s].value = \
                              HHOUR_TO_SECONDS*HHOURS_IN_A_YEAR*instance.OPER_TIME_SIGNAL[r,t]*instance.DEMAND_4[g]/sum(instance.OPER_TIME_INTERVAL[t1] for t1 in instance.T)
                       else:
                           instance.DEMAND[r,g,t,tm,s].value = 0

#def set_init_strg(instance):
#   for r in instance.R :
#      for strg_tech in instance.STRG_TECH :
#         for g in instance.G :
#            instance.INIT_STRG[r,strg_tech,g,1].value = instance.INIT_STRG_TM_1[strg_tech,g]

#def set_init_tech(instance):
#   for process_tech in instance.PROCESS_TECH :
#      for g in instance.G :
#         instance.INIT_TECH[process_tech,g,1].value = instance.INIT_TECH_TM_1[process_tech,g]

def set_cost_parameters(instance):
   """ Defines the costing metrics across all grids."""
   for tm in instance.TM :
      for g in instance.G :
         for m in instance.M :
            for j in instance.J :
               instance.INV_COEFF_GRID[j,g,m,tm].value = instance.INV_COEFF[j,m,1]*instance.LEARNING_RED[j,tm]
               instance.PROCESS_COEFF[j,m,tm].value = instance.PROCESS_COEFF[j,m,1].value*instance.LEARNING_RED[j,tm]


def set_process_emissions(instance):
   """ Defines the initial emissions - process."""
   for g in instance.G :
      for t in instance.T :
          for tm in instance.TM :
              instance.INIT_RSRC[name_for_uncaptured_CO2,g,t,tm].value = \
                   instance.EMISSIONS_GRIDDED[g]*KILOTON_TO_TON/instance.OPER_TIME_INTERVAL[t]
              


def custommodel(options,model,instance):
   """ Function used to call the different instantiated features as per the users' desire."""
   set_resource_demand(instance)
   set_cost_parameters(instance)
   set_process_emissions(instance)
#   set_init_strg(instance)
#   set_init_tech(instance)


def pyomo_modify_instance(options,model,instance):
   """ Calls on the user specified features and contains features to assist users with debugging."""
   print ('pyomo_modify_instance')
   custommodel(options,model,instance)
   #instance.preprocess()
   #opt = SolverFactory('cplex')
   #results = opt.solve(instance, tee=True, symbolic_solver_labels=True)
   #instance.pprint()
   #for constraint in instance.component_map(Constraint).itervalues():
   #     constraint.pprint()
   #log_infeasible_constraints(instance)
   #log_infeasible_bounds(instance)

def pyomo_save_results(options=None,instance=None,results=None):
   """ Prints save statement in the terminal along with executing post-processing actions."""
   print ('pyomo_save_results')
   output_files(instance)
   #key_performance_metrics(instance)
   #aggoutput(instance)
   #carbon(instance)
