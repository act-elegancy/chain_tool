from __future__ import division
from pyomo.environ import *

name_for_nat_gas = 'NAT_GAS_HIGH_P'
MJ_TO_MWH = 3600
name_for_offset_tech = 'NET'
name_for_OpEx = 'OPEX'
MINIMUM_ASSET_AVAILABILITY = 0.7

def summary(instance):
   if instance == None:
       return
   csv = open('Simulation_summary.csv','w')
   csv.write('Total annualised costs (£k per yr): %f\n' % value(instance.obj))
   
   csv.write('Gas requirement (MWh per yr): %f\n' \
   % (sum(sum(sum(sum( \
   instance.import_rate[name_for_nat_gas,g,t,tm,s].value*instance.OPER_TIME_INTERVAL[t]*instance.AVAILABILITY[g]/MJ_TO_MWH \
            for g in instance.G) for t in instance.T) for tm in instance.TM) for s in instance.S)))
   
   csv.write('Total emissions offset (tons per yr): %f\n' \
   % (sum(sum(sum(sum( \
   instance.prod_rate[name_for_offset_tech,g,t,tm,s].value*instance.OPER_TIME_INTERVAL[t]*instance.AVAILABILITY[g] \
            for g in instance.G) for t in instance.T) for tm in instance.TM) for s in instance.S)))
              
   csv.write('Total cost of offsets (£k per yr): %f\n' \
   % (sum(sum(sum(sum( \
   instance.prod_rate[name_for_offset_tech,g,t,tm,s].value*instance.OPER_TIME_INTERVAL[t]*instance.AVAILABILITY[g]*( \
   instance.PROCESS_COEFF[name_for_offset_tech,name_for_OpEx,tm].value) \
            for g in instance.G) for t in instance.T) for tm in instance.TM) for s in instance.S)))
   
   csv.write('Grid cell, Annualised cost of capture and heat supply (£k per year)\n')
   for g in instance.G:
       if instance.AVAILABILITY[g] > MINIMUM_ASSET_AVAILABILITY:
           csv.write('{0:d},{1:.0f}\n' .format(g,(sum(sum(sum(sum( \
           instance.OPER_TIME_INTERVAL[t]*instance.AVAILABILITY[g]*( \
           instance.PROCESS_COEFF[postcomb,name_for_OpEx,tm].value*instance.prod_rate[postcomb,g,t,tm,s].value \
           + instance.import_rate[name_for_nat_gas,g,t,tm,s].value*instance.IMPORT_COEFF[name_for_nat_gas,name_for_OpEx])
           for postcomb in instance.POSTCOMB) for t in instance.T) for tm in instance.TM) for s in instance.S))))
   
   csv.close


def num_process(instance):
   if instance == None :
      return
   csv = open('num_process.csv','w')
   csv.write('Major time, Technologies, Grid Cell, Scenario, Number of processes\n')
   for tm in instance.TM :
      for process_tech in instance.PROCESS_TECH :
         for g in instance.G :
            for s in instance.S:
               if instance.num_process[process_tech,g,tm,s].value > 0:
                   csv.write('{0:d},{1:s},{2:d},{3:s},{4:.0f}\n' \
                   .format(tm,process_tech,g,s,instance.num_process[process_tech,g,tm,s].value))
   csv.close

def prod_rate(instance,tolerance=0.01):
   if instance == None :
      return
   csv = open('prod_rate.csv','w')
   csv.write('Major time, Technology, Grid Cell, Scenario, Minor time, Production rate\n')
   for tm in instance.TM :
      for process_tech in instance.PROCESS_TECH :
         for g in instance.G :
            for s in instance.S :
               for t in instance.T :
                  if instance.prod_rate[process_tech,g,t,tm,s].value > tolerance:
                     csv.write('{0:d},{1:s},{2:d},{3:s},{4:d},{5:.3f}\n' \
                       .format(tm,process_tech,g,s,t,instance.prod_rate[process_tech,g,t,tm,s].value))
   for tm in instance.TM :
      for end_use_tech in instance.END_USE_TECH :
         for g in instance.G :
            for s in instance.S :
               for t in instance.T :
                  if instance.prod_rate[end_use_tech,g,t,tm,s].value > tolerance:
                     csv.write('{0:d},{1:s},{2:d},{3:s},{4:d},{5:.3f}\n' \
                       .format(tm,end_use_tech,g,s,t,instance.prod_rate[end_use_tech,g,t,tm,s].value))
   csv.close

def import_rate(instance,tolerance=0.01):
   if instance == None :
      return
   csv = open('import_rate.csv','w')
   csv.write('Major time, Resource type, Grid cell, Minor time, Scenario, Import rate\n')
   for tm in instance.TM :
      for r in instance.R :
         for g in instance.G :
            for t in instance.T :
               for s in instance.S :
                  if instance.import_rate[r,g,t,tm,s].value > tolerance:
                     csv.write('{0:d},{1:s},{2:d},{3:d},{4:s},{5:.3f}\n'\
                       .format(tm,r,g,t,s,instance.import_rate[r,g,t,tm,s].value))
   csv.close


def inventory_rsrc(instance,tolerance=0.01):
   if instance == None :
      return
   csv = open('inventory_rsrc.csv','w')
   csv.write('Major time, Storage type, Resource type, Grid cell, Scenario, Minor Time, Inventory\n')
   for tm in instance.TM :
      for strg_tech in instance.STRG_TECH :
         for r in instance.R :
            for g in instance.G :
               for s in instance.S :
                  for t in instance.T :
                     if instance.inventory_rsrc[r,g,strg_tech,t,tm,s].value > tolerance:
                        csv.write('{0:d},{1:s},{2:s},{3:d},{4:s},{5:d},{6:.3f}\n'\
                          .format(tm,strg_tech,r,g,s,t,instance.inventory_rsrc[r,g,strg_tech,t,tm,s].value))
   csv.close


def num_dist(instance):
   if instance == None :
      return
   csv = open('num_dist.csv','w')
   csv.write('Major time, From grid, To grid, Distribution technology, Scenario, No. of units owned\n')
   for tm in instance.TM :
         for g in instance.G :
            for g1 in instance.G :
               for d in instance.D :
                  for s in instance.S :
                     if instance.num_dist[g,g1,d,tm,s].value > 0 :
                        csv.write('{0:d},{1:d},{2:d},{3:s},{4:s},{5:.3f}\n' \
                           .format(tm,g,g1,d,s,instance.num_dist[g,g1,d,tm,s].value))
   csv.close


def num_strg(instance):
   if instance == None :
      return
   csv = open('num_strg.csv','w')
   csv.write('Major time, Resource type, Grid cell, Storage technology, Scenario, No. of storage units\n')
   for tm in instance.TM :
      for r in instance.R :
         for g in instance.G :
            for strg_tech in instance.STRG_TECH :
               for s in instance.S:
                  if instance.num_strg[r,strg_tech,g,tm,s].value > 0:
                     csv.write('{0:d},{1:s},{2:d},{3:s},{4:s},{5:.3f}\n'\
                       .format(tm,r,g,strg_tech,s,instance.num_strg[r,strg_tech,g,tm,s].value))
   csv.close


def flow_rate(instance,tolerance=0.01):
   if instance == None :
      return
   csv = open('total_flow_rate.csv','w')
   csv.write('Major Time, Distribution type, From grid, To grid, Scenario, Minor time, Flowrate\n')
   for tm in instance.TM :
      for d in instance.D :
         for g in instance.G :
            for g1 in instance.G :
               for s in instance.S :
                  for t in instance.T :
                     if instance.total_flow_rate[g,g1,d,t,tm,s].value > tolerance:
                        csv.write('{0:d},{1:s},{2:d},{3:d},{4:s},{5:d},{6:.3f}\n' \
                          .format(tm,d,g,g1,s,t,instance.total_flow_rate[g,g1,d,t,tm,s].value))
   csv.close


def total_metrics(instance,tolerance=0.01):
   if instance == None :
      return
   csv = open('total_metrics.csv','w')
   csv.write('Major Time, Performance metric, Scenario, Total metric value\n')
   for tm in instance.TM :
       for m in instance.M :
           for s in instance.S :
               if instance.total_metrics[m,tm,s].value > tolerance:
                   csv.write('{0:d},{1:s},{2:s},{3:.3f}\n' \
                       .format(tm,m,s,instance.total_metrics[m,tm,s].value))
   csv.close


def detoutput(instance):
   num_process(instance)
   prod_rate(instance)
   import_rate(instance)
   num_dist(instance)
   num_strg(instance)
   inventory_rsrc(instance)
   flow_rate(instance)
   total_metrics(instance)
   summary(instance)
