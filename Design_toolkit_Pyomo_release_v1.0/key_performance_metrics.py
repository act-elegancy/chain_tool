from __future__ import division
from pyomo.environ import *

TON_TO_GRAM = 1000000
ELECTRICITY_PER_UNIT_GAS = 0.44
SPEC_PRIMARY_ENERGY_WITHOUT_CAPTURE = 1.15
NUM_YEARS_PER_TM = 5
DISCOUNT_RATE = 0.06
KWH_TO_MJ = 3.6
THOUSAND_TO_REG = 1000
LEVELISED_COST_OF_H2_WITHOUT_CAPTURE = 0.02
name_for_stored_onshore_CO2 = 'CLIQ_CO2_ONSHORE'
name_for_hydrogen = 'CGAS_H2'
name_for_electricity ='ELECTRICITY'
name_for_emitted_CO2 = 'EMITTED_CO2'
name_for_nat_gas = 'NAT_GAS_HIGH_P'

def carbon_intensity_prod(instance):
   if instance == None :
      return
   csv = open('carbon_intensity_prod.csv','w')
   csv.write('Major time, Carbon Intensity of production (g per MJ)\n')
   for tm in instance.TM :
       
       H2_production_output = \
       sum(sum(sum(sum(instance.RESOURCE_CONV_RATE[process_tech,name_for_hydrogen]*( \
       instance.prod_rate[process_tech,g,t,tm,s].value*instance.OPER_TIME_INTERVAL[t]) \
           for process_tech in instance.PROCESS_TECH) for g in instance.G) \
           for s in instance.S) for t in instance.T)
       
       released_CO2 = \
       sum(sum(sum(sum(instance.RESOURCE_CONV_RATE[process_tech,name_for_emitted_CO2]*( \
       instance.prod_rate[process_tech,g,t,tm,s].value*instance.OPER_TIME_INTERVAL[t]) \
           for process_tech in instance.PROCESS_TECH) for g in instance.G) \
           for s in instance.S) for t in instance.T)
       
       carbon_intensity = released_CO2*TON_TO_GRAM/H2_production_output
       csv.write('{0:d},{1:.3f}\n'.format(tm,carbon_intensity))
   csv.close


def specific_CO2_avoided(instance):
   if instance == None :
      return
   csv = open('specific_CO2_avoided.csv','w')
   csv.write('Major time, Specific carbon Intensity avoided (g per MJ)\n')
   for tm in instance.TM :
       
       H2_production_output = \
       sum(sum(sum(sum(instance.RESOURCE_CONV_RATE[process_tech,name_for_hydrogen]*( \
       instance.prod_rate[process_tech,g,t,tm,s].value*instance.OPER_TIME_INTERVAL[t]) \
           for process_tech in instance.PROCESS_TECH) for g in instance.G) \
           for s in instance.S) for t in instance.T)
       
       captured_CO2 = \
       sum(sum(sum(sum(instance.RESOURCE_CONV_RATE[process_tech,name_for_stored_onshore_CO2]*( \
       instance.prod_rate[process_tech,g,t,tm,s].value*instance.OPER_TIME_INTERVAL[t]) \
           for process_tech in instance.PROCESS_TECH) for g in instance.G)\
           for s in instance.S) for t in instance.T)
       
       spec_carbon_intensity_avoided = captured_CO2*TON_TO_GRAM/H2_production_output
       csv.write('{0:d},{1:.3f}\n'.format(tm,spec_carbon_intensity_avoided))
   csv.close


def specific_primary_energy_cons(instance):
   if instance == None :
      return
   csv = open('specific_primary_energy_cons.csv','w')
   csv.write('Major time, Specific primary energy requirement (MJ per MJ)\n')
   for tm in instance.TM :
       
       H2_production_output = \
       sum(sum(sum(sum(instance.RESOURCE_CONV_RATE[process_tech,name_for_hydrogen]*( \
       instance.prod_rate[process_tech,g,t,tm,s].value*instance.OPER_TIME_INTERVAL[t]) \
           for process_tech in instance.PROCESS_TECH) for g in instance.G) \
           for s in instance.S) for t in instance.T)
       
       nat_gas_input = \
       sum(sum(sum(sum(-instance.RESOURCE_CONV_RATE[process_tech,name_for_nat_gas]*( \
       instance.prod_rate[process_tech,g,t,tm,s].value*instance.OPER_TIME_INTERVAL[t]) \
           for process_tech in instance.PROCESS_TECH) for g in instance.G) \
           for s in instance.S) for t in instance.T)
       
       electricity_input = \
       sum(sum(sum(sum(-instance.RESOURCE_CONV_RATE[process_tech,name_for_electricity]*( \
       instance.prod_rate[process_tech,g,t,tm,s].value)*( \
       instance.OPER_TIME_INTERVAL[t]/ELECTRICITY_PER_UNIT_GAS) \
           for process_tech in instance.PROCESS_TECH) for g in instance.G)\
           for s in instance.S) for t in instance.T)
       
       spec_primary_energy_cons = (nat_gas_input + electricity_input)/H2_production_output
       csv.write('{0:d},{1:.3f}\n'.format(tm,spec_primary_energy_cons))
   csv.close


def specific_primary_energy_per_CO2_avoided(instance):
   if instance == None :
      return
   csv = open('SPECCA.csv','w')
   csv.write('Major time, Specific primary energy per unit of CO2 avoided (MJ per ton)\n')
   for tm in instance.TM :
       
       H2_production_output = \
       sum(sum(sum(sum(instance.RESOURCE_CONV_RATE[process_tech,name_for_hydrogen]*( \
       instance.prod_rate[process_tech,g,t,tm,s].value*instance.OPER_TIME_INTERVAL[t]) \
           for process_tech in instance.PROCESS_TECH) for g in instance.G)\
           for s in instance.S) for t in instance.T)
       
       nat_gas_input = \
       sum(sum(sum(sum(-instance.RESOURCE_CONV_RATE[process_tech,name_for_nat_gas]*(\
       instance.prod_rate[process_tech,g,t,tm,s].value*instance.OPER_TIME_INTERVAL[t]) \
           for process_tech in instance.PROCESS_TECH) for g in instance.G) \
           for s in instance.S) for t in instance.T)
       
       electricity_input = \
       sum(sum(sum(sum(-instance.RESOURCE_CONV_RATE[process_tech,name_for_electricity]*( \
       instance.prod_rate[process_tech,g,t,tm,s].value)*( \
       instance.OPER_TIME_INTERVAL[t]/ELECTRICITY_PER_UNIT_GAS) \
           for process_tech in instance.PROCESS_TECH) for g in instance.G) \
           for s in instance.S) for t in instance.T)
       
       spec_primary_energy_cons = (nat_gas_input + electricity_input)/H2_production_output
       
       captured_CO2 = \
       sum(sum(sum(sum(instance.RESOURCE_CONV_RATE[process_tech,name_for_stored_onshore_CO2]*(\
       instance.prod_rate[process_tech,g,t,tm,s].value*instance.OPER_TIME_INTERVAL[t])\
           for process_tech in instance.PROCESS_TECH) for g in instance.G)\
           for s in instance.S) for t in instance.T)
       
       spec_carbon_intensity_avoided = captured_CO2/H2_production_output
       spec_primary_energy_per_CO2_avoided = \
          (spec_primary_energy_cons - SPEC_PRIMARY_ENERGY_WITHOUT_CAPTURE)/spec_carbon_intensity_avoided 
       
       csv.write('{0:d},{1:.3f}\n'.format(tm,spec_primary_energy_per_CO2_avoided))
   csv.close


def levelised_cost_of_H2_prod(instance):
   if instance == None:
       return
   csv = open('levelised_cost_of_H2_prod.csv','w')
   csv.write('Levelised cost of H2 production (£/ kWh)\n')
   investment_present_value = 0
   operation_present_value = 0
   H2_production_present_value = 0
   
   for tm in instance.TM:
       # Investment capital is split equally into the number of years within the tm.
       investment_cost = \
       sum(sum(sum(instance.num_process_invest[process_tech,g,tm,s].value*( \
       instance.INV_COEFF_GRID[process_tech,g,'CAPEX',tm].value/NUM_YEARS_PER_TM) \
       for g in instance.G) for process_tech in instance.PROCESS_TECH) for s in instance.S)
       
       operation_cost = \
       sum(sum(sum(instance.num_process[process_tech,g,tm,s].value*( \
       instance.INV_COEFF_GRID[process_tech,g,'OPEX',tm].value) \
       for g in instance.G) for process_tech in instance.PROCESS_TECH) for s in instance.S)\
       + sum(sum(sum(sum(instance.IMPORT_COEFF[imp_r,'OPEX']*( \
       instance.import_rate[imp_r,g,t,tm,s].value*instance.OPER_TIME_INTERVAL[t]) \
       for imp_r in instance.IMP_R) for g in instance.G) \
       for t in instance.T) for s in instance.S)
       
       H2_production_output = \
       sum(sum(sum(sum(instance.RESOURCE_CONV_RATE[process_tech,name_for_hydrogen]*(\
       instance.prod_rate[process_tech,g,t,tm,s].value*instance.OPER_TIME_INTERVAL[t]) \
           for process_tech in instance.PROCESS_TECH) for g in instance.G)\
           for s in instance.S) for t in instance.T)

       discount_denominator = sum(1/(1+DISCOUNT_RATE)**((tm-1)*NUM_YEARS_PER_TM + 1 + i)\
                              for i in range(NUM_YEARS_PER_TM))
       
       investment_present_value += investment_cost*discount_denominator
       operation_present_value += operation_cost*discount_denominator
       H2_production_present_value += H2_production_output*discount_denominator
   
   levelised_cost_of_H2 =  (investment_present_value + operation_present_value)*(\
                            KWH_TO_MJ*THOUSAND_TO_REG/H2_production_present_value)
   csv.write('{0:.3f}\n'.format(levelised_cost_of_H2))
   csv.close
   return levelised_cost_of_H2


def cost_of_CO2_avoided(instance,LCOH):
   if instance == None:
       return
   csv = open('cost_of_CO2_avoided.csv','w')
   csv.write('Cost of CO2 avoidance (£/ ton)\n')
   
   H2_production_output = \
       sum(sum(sum(sum(sum(instance.RESOURCE_CONV_RATE[process_tech,name_for_hydrogen]*( \
       instance.prod_rate[process_tech,g,t,tm,s].value*instance.OPER_TIME_INTERVAL[t]) \
       for process_tech in instance.PROCESS_TECH) for g in instance.G) \
       for s in instance.S) for t in instance.T) for tm in instance.TM)
       
   captured_CO2 = \
       sum(sum(sum(sum(sum(instance.RESOURCE_CONV_RATE[process_tech,name_for_stored_onshore_CO2]*( \
       instance.prod_rate[process_tech,g,t,tm,s].value*instance.OPER_TIME_INTERVAL[t]) \
       for process_tech in instance.PROCESS_TECH) for g in instance.G) \
       for s in instance.S) for t in instance.T) for tm in instance.TM)
   
   spec_carbon_intensity_avoided = captured_CO2/H2_production_output
   cost_of_CO2_avoidance = (LCOH - LEVELISED_COST_OF_H2_WITHOUT_CAPTURE)/( \
         spec_carbon_intensity_avoided*KWH_TO_MJ)
   csv.write('{0:.3f}\n'.format(cost_of_CO2_avoidance))
   csv.close


def key_performance_metrics(instance):
   carbon_intensity_prod(instance)
   specific_CO2_avoided(instance)
   specific_primary_energy_cons(instance)
   specific_primary_energy_per_CO2_avoided(instance)
   LCOH = levelised_cost_of_H2_prod(instance)
   cost_of_CO2_avoided(instance,LCOH)
