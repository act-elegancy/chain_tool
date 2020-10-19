from __future__ import division
from pyomo.environ import *

def numprocess(instance):
   if instance == None :
      return
   csv = open('num_process.csv','w')
   csv.write('Number of process technologies\n')
   csv.write('Major time, Process type, Grid Cell, Number of process technologies\n')
   for tm in instance.TM :
      for process_tech in instance.PROCESS_TECH :
         for g in instance.G :
            if instance.num_process[process_tech,g,tm].value > 0 :
               csv.write('{0:d},{1:s},{2:d},{3:.0f}\n' \
                .format(tm,process_tech,g,instance.num_process[process_tech,g,tm].value))
   csv.close

def prodrate(instance,tolerance=0.01):
   if instance == None :
      return
   csv = open('prod_rate.csv','w')
   csv.write('Production rate (kg/ day)\n')
   csv.write('Major time, Process type, Grid Cell, Minor time, Production rate\n')
   for tm in instance.TM :
      for process_tech in instance.PROCESS_TECH :
         for g in instance.G :
            for t in instance.T :
               if instance.prod_rate[process_tech,g,t,tm].value > tolerance :
                  csv.write('{0:d},{1:s},{2:d},{3:d},{4:.3f}\n' \
                    .format(tm,process_tech,g,t,instance.prod_rate[process_tech,g,t,tm].value))
   csv.close

def flowrsrc(instance,tolerance=0.01):
   if instance == None :
      return
   csv = open('flow_rsrc.csv','w')
   csv.write('Flows between grids (kg/day)\n')
   csv.write('Major, Resource, From grid, To grid, Minor time, Distribution Mode, Flowrate (kg/day)\n')
   for tm in instance.TM :
      for r in instance.R :
         for g in instance.G :
            for g1 in instance.G :
               for d in instance.D :
                  for t in instance.T :
                     if instance.flow_rsrc[r,g,g1,d,t,tm].value > tolerance :
                        csv.write('{0:d},{1:s},{2:d},{3:d},{4:d},{5:s},{6:.3f}\n' \
                          .format(tm,r,g,g1,t,d,instance.flow_rsrc[r,g,g1,d,t,tm].value))
   csv.close

def importedrsrc(instance,tolerance=0.01):
   if instance == None :
      return
   csv = open('imported_rsrc.csv','w')
   csv.write('Import rate(kg/day)\n')
   csv.write('Major time, Resource type, Grid cell, Minor time, Import rate (kg/day)\n')
   for tm in instance.TM :
      for r in instance.R :
         for g in instance.G :
            for t in instance.T :
               if instance.imported_rsrc[r,g,t,tm].value > tolerance :
                  csv.write('{0:d},{1:s},{2:d},{3:d},{4:.3f}\n'\
                    .format(tm,r,g,t,instance.imported_rsrc[r,g,t,tm].value))
   csv.close

def surplusrsrc(instance,tolerance=0.01):
   if instance == None :
      return
   csv = open('surplus_rsrc.csv','w')
   csv.write('Net Accumulation(kg/day)\n')
   csv.write('Major time, Resource type, Grid cell, Minor time, Accumulation (kg/day)\n')
   for tm in instance.TM :
      for r in instance.R :
         for g in instance.G :
            for t in instance.T :
               if instance.surplus_rsrc[r,g,t,tm].value > tolerance :
                  csv.write('{0:d},{1:s},{2:d},{3:d},{4:.3f}\n'\
                    .format(tm,r,g,t,instance.surplus_rsrc[r,g,t,tm].value))
   csv.close

def numdist(instance,tolerance=0.01):
   if instance == None :
      return
   csv = open('num_dist.csv','w')
   csv.write('Number of distribution modes\n')
   csv.write('Major time, Resource, From grid, To grid, Distribution Mode, No. of units owned\n')
   for tm in instance.TM :
      for des_r in instance.DES_R :
         for g in instance.G :
            for g1 in instance.G :
               for d in instance.D :
                  if instance.num_dist[des_r,g,g1,d,tm].value > tolerance :
                     csv.write('{0:d},{1:s},{2:d},{3:d},{4:s},{5:.3f}\n' \
                        .format(tm,des_r,g,g1,d,instance.num_dist[des_r,g,g1,d,tm].value))
   csv.close


def numstrg(instance,tolerance=0.01):
   if instance == None :
      return
   csv = open('num_strg.csv','w')
   csv.write('Number of storage units needed\n')
   csv.write('Major time, Resource type, Grid cell, Storage technology, No. of storage units\n')
   for tm in instance.TM :
      for r in instance.R :
         for g in instance.G :
            for strg_tech in instance.STRG_TECH :
               if instance.num_strg[r,strg_tech,g,tm].value > tolerance :
                  csv.write('{0:d},{1:s},{2:d},{3:s},{4:.3f}\n'\
                    .format(tm,r,g,strg_tech,instance.num_strg[r,strg_tech,g,tm].value))
   csv.close

def detoutput(instance):
   numprocess(instance)
   prodrate(instance)
   flowrsrc(instance)
   importedrsrc(instance)
   surplusrsrc(instance)
   numdist(instance)
   numstrg(instance)
