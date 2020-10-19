# Author name: Nixon Sunny
# Author email: nixon.sunny13 AT imperial.ac.uk
# Organisation = Imperial College London
# Date: 05 March 2019
# Version: 1.0

##Elegancy GIS Inputs=name
##Shapefile_Path=string C:\Users\JohnDoe\Desktop\Optimisation_Files
##Land_Use_Raster_Data=raster
##No_Data_Value=number 48
##Raster_Value_of_Interest_separate_values_by_commas=string 12
##Complete_Region_Shapefile=vector Polygon
##Desired_Number_of_Cells=number 100
##Only_count_cells_with_at_least_x_percent_of_the_area_of_the_largest_cell_where_0_includes_all_cells=number 5
##Hydrogen_Intraday_Caverns=optional vector Point
##Hydrogen_Storage_csv_name_1=string Hydrogen_Storage_Gridded_1
##Hydrogen_Interseasonal_Caverns=optional vector Point
##Hydrogen_Storage_csv_name_2=string Hydrogen_Storage_Gridded_2
##Please_select_the_number_of_columns_needed_from_Hydrogen_storage_layer=string 1
##Hydrogen_Demand_Layer_1=optional vector Point
##Demand_csv_name1=optional string Demand_Gridded_1
##Hydrogen_Demand_Layer_2=optional vector Point
##Demand_csv_name2=optional string Demand_Gridded_2
##CO2_Storage_Sites=optional vector Point
##CO2_Storage_csv_name=optional string CO2_Stores_Gridded
##Natural_Gas_Transmission_lines=optional vector Line
##Transmission_Lines_csv_name=optional string Transmission_Lines_Gridded
##Output_Linear_Distance_Between_Cells=output table
##Output_Tortuosity_Between_Cells=output table
##Output_Cell_Area=output table
##Output_Available_Land_Area=output table
##Output_Grid_SHP=output vector


# Load libraries from QGIS and Python core
from qgis.core import *
from qgis.utils import *
from PyQt4.QtCore import *
import math
import csv
import time


# ------------------------Variable Declarations and Initializations
t_0 = time.time()
numGridCells = max(Desired_Number_of_Cells,1) # approximate number of cells that will be created in the grid
minCellFrac = float(Only_count_cells_with_at_least_x_percent_of_the_area_of_the_largest_cell_where_0_includes_all_cells)/100 # the minimum cell size as a fraction of the largest cell size
noDataVal = No_Data_Value
tmpNum = 0
rastNumInterest = [int(s) for s in Raster_Value_of_Interest_separate_values_by_commas.split(',')]
outATcsv = Output_Cell_Area
outLDcsv = Output_Linear_Distance_Between_Cells
outLAcsv = Output_Available_Land_Area
#outDemandcsv = Output_Demand
outTTcsv = Output_Tortuosity_Between_Cells
outSHP = Output_Grid_SHP
Hydrogen_flag = int(Please_select_the_number_of_columns_needed_from_Hydrogen_storage_layer)-1

maxIter = 10 # maximum number of iterations to get correct number of cells
minUnder = 0.95
maxOver = 1.05
iter = 0
areaConv = 100/4 #converts hectares to km^2 and then annual production to monthly production

# new attribute names
fieldNameID = "IDnum"
fieldNameArea = "Area-sq_km"
fieldNameX = "Centroid X"
fieldNameY = "Centroid Y"
fieldNameLen = "Road Len"
fieldNameCount = "Road Count"

# Copy the layers and leave the originals intact
fullRast_noConstr = processing.getObject(Land_Use_Raster_Data)
countrySHP = processing.getObject(Complete_Region_Shapefile)
#DemandRast = processing.getObject(Demand_Layer)
HydrogenDemandVector1 = processing.getObject(Hydrogen_Demand_Layer_1)
HydrogenDemandVector2 = processing.getObject(Hydrogen_Demand_Layer_2)
HydrogenStorageVector1 = processing.getObject(Hydrogen_Intraday_Caverns)
HydrogenStorageVector2 = processing.getObject(Hydrogen_Interseasonal_Caverns)
CO2StorageVector = processing.getObject(CO2_Storage_Sites)
NatGasTransmissionVector = processing.getObject(Natural_Gas_Transmission_lines)


# ------------------------Reproject shapefiles to the CRS of the raster
def layerReproj(layer_unknownCRS, layer_destCRS):
    if not(layer_destCRS.crs().authid() == layer_unknownCRS.crs().authid()): # check to see if the CRS are different
        iface.mainWindow().statusBar().showMessage("Checking the layer CRS") # Update the user in the status bar
        tmpReproj = processing.runalg("qgis:reprojectlayer", layer_unknownCRS, layer_destCRS.crs().authid(),None) # reroject the country shapefile to the new CRS
        layer_newCRS = QgsVectorLayer(tmpReproj['OUTPUT'], "Reprojected Shapefile", "ogr") # add the reprojection to the project
        if layer_newCRS.isValid():
            iface.mainWindow().statusBar().showMessage("Reprojected the necessary shp CRS: %s" % layer_newCRS.crs().authid()) # Update the user in the status bar
        else:
            iface.messageBar().pushInfo("Error","Could not reproject vector layer, please check vector layer", level=QgsMessageBar.CRITICAL)
    else: # if the CRS are the same, we are done
        layer_newCRS = layer_unknownCRS
        iface.mainWindow().statusBar().showMessage("Shapefile already has correct CRS") # Update the user in the status bar
    return layer_newCRS

# ------------------------Reproject rasters to the CRS of the raster
def rastReproj(layer_unknownCRS, layer_destCRS,floatFlag):
    canvExtent = iface.mapCanvas().extent()
    exmin = canvExtent.xMinimum()
    exmax = canvExtent.xMaximum()
    eymin = canvExtent.yMinimum()
    eymax = canvExtent.yMaximum()
    extent = "%f,%f,%f,%f" %(exmin, exmax, eymin, eymax)

    if not(layer_destCRS.crs().authid() == layer_unknownCRS.crs().authid()): # check to see if the CRS are different
        iface.mainWindow().statusBar().showMessage("Checking the layer CRS") # Update the user in the status bar
        tmpReproj = processing.runalg("gdalogr:warpreproject",layer_unknownCRS,layer_unknownCRS.crs().authid(),layer_destCRS.crs().authid(),noDataVal,0.0,0,extent,'',(4+floatFlag),3,75,6,1,False,2,False,'',None)
        layer_newCRS = QgsRasterLayer(tmpReproj['OUTPUT'], "Reprojected Raster") # add the reprojection to the project
        if layer_newCRS.isValid():
            iface.mainWindow().statusBar().showMessage("Reprojected the country shp CRS: %s" % layer_newCRS.crs().authid()) # Update the user in the status bar
        else:
            iface.messageBar().pushInfo("Error","Could not reproject vector layer, please check vector layer", level=QgsMessageBar.CRITICAL)
    else: # if the CRS are the same, we are done
        layer_newCRS = layer_unknownCRS
        iface.mainWindow().statusBar().showMessage("Shapefile already has correct CRS") # Update the user in the status bar
    return layer_newCRS

# ------------------------Create a tight grid overlay for  the country
def gridGen(layer_countryProfile, cellsize):
    if (not layer_countryProfile.isValid()):
        return layer_countryProfile

    # Generate the overall grid
    iface.mainWindow().statusBar().showMessage("Generating Grid Overlay") # Update the user in the status bar
    # define the extent of the grid, based on the size of the country shapefile
    extent = "%f, %f, %f, %f" % (layer_countryProfile.extent().xMinimum(), layer_countryProfile.extent().xMaximum(), layer_countryProfile.extent().yMinimum(), layer_countryProfile.extent().yMaximum()) 
    tmpGrid = processing.runalg('qgis:vectorgrid', extent, cellsize, cellsize, 0, None) # create the grid and save it
    layer_newGrid = QgsVectorLayer(tmpGrid['OUTPUT'], "Gridded Layer", "ogr") # add the grid to the project
    if layer_newGrid.isValid():
        iface.mainWindow().statusBar().showMessage("Generating Grid Overlay - Complete") # Update the user in the status bar
    else:
        iface.messageBar().pushInfo("Error","Trouble generating grid - vectorgrid", level=QgsMessageBar.WARNING)

    # Tighten the grid to just the country
    iface.mainWindow().statusBar().showMessage("Clipping Grid to country profile") # Update the user in the status bar
    tmpFull = processing.runalg('qgis:clip',layer_newGrid, layer_countryProfile,None) # create the tight grid by clipping the grid with the country profile
    layer_fullGrid = QgsVectorLayer(tmpFull['OUTPUT'], "Gridded Region", "ogr") # add the tight grid to the project
    if layer_fullGrid.isValid():
        iface.mainWindow().statusBar().showMessage("Clipping grid to country profile - complete") # Update the user in the status bar
    else:
        iface.messageBar().pushInfo("Error","Trouble generating grid - clip", level=QgsMessageBar.WARNING)

    return layer_fullGrid


# ------------------------Delete old fields. Add field for ID, and field for area. Add area, x and y coordinates to vectors for each
def replaceFields(layer_repFields):
    iface.mainWindow().statusBar().showMessage("Adding cell ID and area to vector layer") # Update the user in the status bar
    caps = layer_repFields.dataProvider().capabilities() # need to have access to layer capabilities in order to update fields
    if not caps: # if the capabilities are not accessible, this a problem.
        iface.messageBar().pushInfo("Error","loading layer capabilities failed", level=QgsMessageBar.WARNING) 
    elif ((not QgsVectorDataProvider.DeleteAttributes) and (not QgsVectorDataProvider.AddAttributes)): # see if attribute methods are available. if they are not, this is a problem
        iface.messageBar().pushInfo("Error","loading data provider methods failed", level=QgsMessageBar.WARNING)
    else: # if these are available, we may proceed
        fieldCount = 0 # set the field count at 0, then count the number of current fields (info needed to delete them)
        for field in layer_repFields.pendingFields():
            fieldCount += 1
        delFields = range(fieldCount)
        layer_repFields.dataProvider().deleteAttributes(delFields) # delete all current attributes
        layer_repFields.updateFields()
        # add the attributes that we care about
        layer_repFields.dataProvider().addAttributes([QgsField(fieldNameID, QVariant.Int), QgsField(fieldNameArea, QVariant.Double)]) 
        layer_repFields.updateFields()

        layer_repFields.startEditing() # initiate editing of the layer attributes
        iter = layer_repFields.getFeatures()
        areaOp = QgsDistanceArea()
        areaOp.computeAreaInit()
        for feature in iter: # loop across all features in the layer
            if feature.geometry().wkbType() == QGis.WKBPolygon: # check to make sure the geometry is a valid choice
                feature[0] = feature.id()+1 # set the new feature ID value
                feature[1] = areaOp.measurePolygon(feature.geometry().asPolygon()[0])/(1000*1000)
                layer_repFields.updateFeature(feature) # update the feature with the field changes
            elif feature.geometry().wkbType() == QGis.WKBMultiPolygon: # check to make sure the geometry is a valid choice
                feature[0] = feature.id()+1 # set the new feature ID value
                inst = feature.geometry().asMultiPolygon()
                instArea = 0
                for geom in inst:
                    instArea = instArea + areaOp.measurePolygon(geom[0])/(1000*1000)
                feature[1] = instArea
                layer_repFields.updateFeature(feature) # update the feature with the field changes
            else: #can't / don't want to calculate for other geometry things
                iface.messageBar().pushInfo("Error","Unknown Geometry", level=QgsMessageBar.WARNING) # if the feature is not a polygon, this is a problem
        iface.mainWindow().statusBar().showMessage("Adding area and centroid location to vector layer - Complete") # Update the user in the status bar
        layer_repFields.commitChanges() # commit these changes 

    return layer_repFields


# ------------------------Number of grid cells that are too small
def countSmallFeatures(layer_smallFeat):
    if (not layer_smallFeat.isValid()):
        return -1
    
    minArea = minCellFrac*layer_smallFeat.maximumValue(layer_smallFeat.fieldNameIndex(fieldNameArea))
    strTooSmall = "\"%s\" < %f" % (fieldNameArea,minArea)
    requestSmallFeat = QgsFeatureRequest().setFilterExpression(strTooSmall)
    requestSmallFeat.setFlags(QgsFeatureRequest.NoGeometry)
    smallFeat = layer_smallFeat.getFeatures(requestSmallFeat)

    return smallFeat

# ------------------------Write attribute table to CSV
def writeAttributeTable(layer_attr):
    iface.mainWindow().statusBar().showMessage("Writing attribute table to CSV") # Update the user in the status bar
    if (not layer_attr.isValid()):
        return -1
        
    # will only keep the file open during the with statement, then closes
    with open(outATcsv,"wb") as ofileAT:
        writerAT = csv.writer(ofileAT, delimiter=',', quoting=csv.QUOTE_NONNUMERIC) # writer is necessary to create csv
    
        # loop across all features in the layer
        iter = layer_attr.getFeatures()
        for feature in iter:
            # check to make sure the geometry is a valid choice
            if feature.geometry().type() == QGis.Polygon:
                writerAT.writerow(feature.attributes()) # write all feature attributes to the csv
            else:
                iface.messageBar().pushInfo("Error","Unknown Geometry", level=QgsMessageBar.WARNING) # if the feature is not a polygon, this is a problem
        iface.mainWindow().statusBar().showMessage("Writing attribute table to CSV - complete") # Update the user in the status bar
    
    return 1

# ------------------------Write vector to file
def writeVec(vect,destFile):
    iface.mainWindow().statusBar().showMessage("Writing vector to CSV") # Update the user in the status bar
    if (not vect):
        return -1
        
    with open(destFile,"wb") as ofileDest:
        writerDest = csv.writer(ofileDest, delimiter=',', quoting=csv.QUOTE_NONNUMERIC) # writer is necessary to create csv
        
        for k in range(0,len(vect)):
            row_k = [k+1] + [vect[k]]
            writerDest.writerow(row_k)
        
    iface.mainWindow().statusBar().showMessage("Writing vector to CSV - Complete") # Update the user in the status bar
    
    return 1

# ------------------------Calulate linear distance between all centroid locations
def writeLinDist(layer_grid):
    iface.mainWindow().statusBar().showMessage("Writing linear distances to CSV") # Update the user in the status bar
    if (not layer_grid.isValid()):
        return -1
    
    # will only keep the file open during the with statement, then closes
    with open(outLDcsv,"wb") as ofileLD:
        writerLD = csv.writer(ofileLD, delimiter=',', quoting=csv.QUOTE_NONNUMERIC) # writer is necessary to create csv
        headerRow = (range(0,len(list(layer_grid.getFeatures()))+1)) # top line that lists all cell ID
        writerLD.writerow(headerRow)
        
        meas = QgsDistanceArea()
        meas.setEllipsoid(layer_grid.crs().authid())
        meas.setEllipsoidalMode(True)
        
        iterV = layer_grid.getFeatures()
        for featureV in iterV : # iterate over each cell, row-wise
            row_i = [featureV[0]] # starts the row with the ID of the current cell
            iterH = layer_grid.getFeatures()
            for featureH in iterH: # iterate over each cell, column-wise
                if (featureH[0] == featureV[0]):
                    dist = 0
                elif featureV.geometry().touches(featureH.geometry()):
                    dist = meas.measureLine(featureV.geometry().centroid().asPoint(),featureH.geometry().centroid().asPoint())/1000
                else:
                    dist = 999
                row_i.append(dist) # find the linear distance in km and append it to the current vector of distances
            writerLD.writerow(row_i) # write the vector of distances to the csv
            
    iface.mainWindow().statusBar().showMessage("Writing linear distances to CSV - Complete") # Update the user in the status bar
    return 1


# ------------------------Calculate Tortuosity Data
def writeTortuosity(layer_tort):
    if not(layer_tort.isValid()):
        return -1
    
    iface.mainWindow().statusBar().showMessage("Writing Tortuosities to CSV")
    with open(outTTcsv,"wb") as ofileTT:
        writerTT = csv.writer(ofileTT, delimiter=',', quoting=csv.QUOTE_NONNUMERIC) # writer is necessary to create csv
        headerRow = range(0,len(list(layer_tort.getFeatures()))+1) # top line that lists all cell ID
        headerRow.insert(0,0)
        writerTT.writerow(headerRow)
        
        iterV = layer_tort.getFeatures()
            
        for featureV in iterV:
            row_i = [featureV[0]]
            row_i.append("truck")
            iterH = layer_tort.getFeatures()
                
            for featureH in iterH:
                if (featureH[0] == featureV[0]):
                    row_i.append(0)
                elif featureV.geometry().touches(featureH.geometry()):
                    row_i.append(1.4)
                else:
                    row_i.append(2.6)
            writerTT.writerow(row_i)
    iface.mainWindow().statusBar().showMessage("Writing linear distances to CSV - Complete") # Update the user in the status bar
    
    return 1


# ------------------------convert grid to raster w/ ID - rasterize
def gridToRast(layer_grid):
    if (not layer_grid.isValid()):
        return -1
        
    fGxmin = layer_grid.extent().xMinimum()
    fGxmax = layer_grid.extent().xMaximum()
    fGymin = layer_grid.extent().yMinimum()
    fGymax = layer_grid.extent().yMaximum()
    extent = "%f,%f,%f,%f" %(fGxmin, fGxmax, fGymin, fGymax)
    
    iface.mainWindow().statusBar().showMessage("Generating raster from country profile") # Update the user in the status bar
    
    tmpRast = processing.runalg("gdalogr:rasterize",layer_grid, fieldNameID, 1, 100, 100, extent, 0, 1, -999, 3, 75, 6, 1, 0, 2, '', None)
    layer_rast = QgsRasterLayer(tmpRast['OUTPUT'], "Full Grid Raster")
    
    if layer_rast.isValid():
        iface.mainWindow().statusBar().showMessage("Generating raster from country profile - Complete") # Update the user in the status bar
    else:
        iface.messageBar().pushInfo("Error","Trouble generating graster from country profile", level=QgsMessageBar.WARNING)
        
    return layer_rast


# ------------------------Perform Statistics on the raster, and write it into a temporary vector
def gridStats(layer_gridRast, layer_fullRast, layer_gridSource):
    if ((not layer_gridRast.isValid()) or (not layer_fullRast.isValid())):
        return -1
        
    fGxmin = layer_gridSource.extent().xMinimum()
    fGxmax = layer_gridSource.extent().xMaximum()
    fGymin = layer_gridSource.extent().yMinimum()
    fGymax = layer_gridSource.extent().yMaximum()
    extent = "%f,%f,%f,%f" %(fGxmin, fGxmax, fGymin, fGymax)

    iface.mainWindow().statusBar().showMessage("Performing statistics on Land Area Usage") # Update the user in the status bar
    rastPath = "%s;%s" %(layer_gridRast.dataProvider().dataSourceUri(), layer_fullRast.dataProvider().dataSourceUri())
    tmpVar = processing.runalg("grass7:r.stats",rastPath,"space","-999","255",False,False,True,False,False,False,False,False,False,True,True,False,False,extent,None,None)
    rastAreas = open(tmpVar['rawoutput'])

    # read raster stats data into vector
    currLine = rastAreas.readline()
    vector_land = [0]*len(list(layer_gridSource.getFeatures()))
    while currLine != "":
        cID,cLandUse,cArea = currLine.split()
        if int(cLandUse) in rastNumInterest:
            vector_land[int(cID)-1] = vector_land[int(cID)-1] + float(cArea)
        currLine = rastAreas.readline()
    iface.mainWindow().statusBar().showMessage("Performing statistics on Land Area Usage - Complete") # Update the user in the status bar
    
    return vector_land
    

# ------------------------Perform Statistics on the raster, and write it into a temporary vector

def computeOptInputs(input_layer,gridded_layer,file_name,iter_flag):
    if input_layer.isValid() and gridded_layer.isValid():
        if input_layer.crs().authid() != gridded_layer.crs().authid():
            iface.mainWindow().statusBar().showMessage("Input and gridded layers have different CRS, please check") # Update the user in the status bar
            layer = layerReproj(input_layer,gridded_layer)
        else:
            iface.mainWindow().statusBar().showMessage("Correct match between the two layers, well done") # Update the user in the status bar
            layer = input_layer
        # Run processing algorithm to join attributes by location.
        iface.mainWindow().statusBar().showMessage("Run Spatial join algorithm") # Update the user in the status bar
        new_path = Shapefile_Path + "\ " + file_name+ ".shp"
        processing.runalg('qgis:joinattributesbylocation',gridded_layer,layer,u'intersects',0.00,1,'SUM',1,new_path)
        iface.mainWindow().statusBar().showMessage("Spatial join completed") # Update the user in the status bar
        layer_name = "%s" % file_name
        wb = QgsVectorLayer(new_path,layer_name,'ogr')
        
        caps = wb.dataProvider().capabilities()
        if not caps:
            iface.messageBar().pushInfo("Error","loading layer capabilities failed", level=QgsMessageBar.WARNING) 
        elif ((not QgsVectorDataProvider.DeleteAttributes) and (not QgsVectorDataProvider.AddAttributes)): 
            # see if attribute methods are available. if they are not, this is a problem
            iface.messageBar().pushInfo("Error","loading data provider methods failed", level=QgsMessageBar.WARNING)
        else: # if these are available, we may proceed
            fieldCount = 0 # set the field count at 0, then count the number of current fields (info needed to delete them)
            for field in wb.pendingFields():
                fieldCount += 1
        delFields = range(1,fieldCount-2-iter_flag)
        delFields.append(fieldCount-1) #Add the count field arising from join to the list to be removed.

        wb.dataProvider().deleteAttributes(delFields) # delete all undesired attributes
        wb.updateFields()
        csv_path = Shapefile_Path + "\ " + file_name + ".csv"
        QgsVectorFileWriter.writeAsVectorFormat(wb,csv_path,"utf-8", None, "CSV")
        iface.mainWindow().statusBar().showMessage("Vector layer converted to a csv file") # Update the user in the status bar

    else:
        iface.mainWindow().statusBar().showMessage("Invalid layer") # Update the user in the status bar

# ------------------------Begin the work - call functions and subroutines

# reproject the Vector shapefile for the region.
reprojSHP = layerReproj(countrySHP,fullRast_noConstr)
QgsMapLayerRegistry.instance().addMapLayer(reprojSHP)

t_1 = time.time()
t_01 = t_1 - t_0
print "Time to reproject region shapefile: %.2f s" % t_01 


fullRast = fullRast_noConstr

QgsMapLayerRegistry.instance().addMapLayer(fullRast)

t_2 = time.time()
t_12 = t_2 - t_1
print "Time to apply constraint layer to full raster when it exists: %.2f s" % t_12


# determine the necessary cell size to get approximately numGridCells of cells in the grid
reprojArea = (reprojSHP.extent().xMaximum()-reprojSHP.extent().xMinimum())*(reprojSHP.extent().yMaximum()-reprojSHP.extent().yMinimum())
cellDimension = math.sqrt(reprojArea/numGridCells)
gridSHP = gridGen(reprojSHP,cellDimension)

t_3 = time.time()
t_23 = t_3 - t_2
print "Time to create initial grid: %.2f s" % t_23


# replace the attribute fields with the ID and area
tightGridSHP = replaceFields(gridSHP)

t_4 = time.time()
t_34 = t_4 - t_3
print "Time to replace fields: %.2f s" % t_34


# get the right number of grid cells requested, excluding ones that are too small
numFeat = len(list(tightGridSHP.getFeatures())) 
prevNum = numGridCells
smallFeatList = countSmallFeatures(tightGridSHP)
numSmallFeat = len(list(smallFeatList))


while ((iter < maxIter) and (((numFeat-numSmallFeat) < numGridCells*minUnder) or ((numFeat-numSmallFeat) > numGridCells*maxOver))):
    iter = iter+1
    newNum = prevNum + ((numGridCells - numFeat)+numSmallFeat)*.9
    cellDimension = math.sqrt(reprojArea/newNum)
    gridSHP = gridGen(reprojSHP,cellDimension)
    tightGridSHP = replaceFields(gridSHP)
    prevNum = newNum
    numFeat = len(list(tightGridSHP.getFeatures()))
    smallFeatList = countSmallFeatures(tightGridSHP)
    numSmallFeat = len(list(smallFeatList))
    print "*** Iteration number: %d" % iter
    
t_5 = time.time()
t_45 = t_5 - t_4
print "Time to create good grid: %.2f s" % t_45


# Remove grid cells that are too small from the layer
with edit(tightGridSHP):
    deleteFeat = countSmallFeatures(tightGridSHP)
    for feature in deleteFeat:
        tightGridSHP.deleteFeature(feature.id())

fullGridSHP = replaceFields(tightGridSHP)

print "*** Remaining grid cells: %d" % len(list(fullGridSHP.getFeatures()))

QgsMapLayerRegistry.instance().addMapLayer(fullGridSHP)

t_6 = time.time()
t_56 = t_6 - t_5
print "Time to remove small grid cells: %.2f s" % t_56


# Export Attribute Table csv
writeAttributeTableFlag = writeAttributeTable(fullGridSHP)

t_7 = time.time()
t_67 = t_7 - t_6
print "Time to export attribute table: %.2f s" % t_67


# Perform the raster cell counts for each feature
gridRast = gridToRast(fullGridSHP)
#QgsMapLayerRegistry.instance().addMapLayer(gridRast)

t_10 = time.time()
t_910 = t_10 - t_9
print "Time to rasterize grid: %.2f s" % t_910

# Export Linear Distance matrix csv
writeLinDistFlag = writeLinDist(fullGridSHP)

t_8 = time.time()
t_78 = t_8 - t_7
print "Time to export centroid distances: %.2f s" % t_78


# Export Tortuosity matrix csv
writeToruosityFlag = writeTortuosity(fullGridSHP)

t_9 = time.time()
t_89 = t_9 - t_8
print "Time to calculate and export tortuosity: %.2f s" % t_89



tmp_availLand = gridStats(gridRast,fullRast,fullGridSHP)
#tot_demand = gridDemand(gridRast,DemandRast,fullGridSHP)
availLand = [x/(1000.0*1000.0) for x in tmp_availLand]

t_11 = time.time()
t_1011 = t_11 - t_10
print "Time to stats: %.2f s" % t_1011


# save raster stats data to csv
flagLA = writeVec(availLand,outLAcsv)
#flagDemand = writeVec(tot_demand,outDemandcsv)

t_12 = time.time()
t_1112 = t_12 - t_11
print "Time to write stats to csv: %.2f s" % t_1112


#QgsMapLayerRegistry.instance().removeMapLayer(gridRast)
#QgsMapLayerRegistry.instance().removeMapLayer(fullRast)

#t_total = t_12 - t_0
#print "Total time:"
#print t_total

if not(HydrogenDemandVector1 == None):
    computeOptInputs(HydrogenDemandVector1,fullGridSHP,Demand_csv_name1,0)

if not(HydrogenDemandVector2 == None):
    computeOptInputs(HydrogenDemandVector2,fullGridSHP,Demand_csv_name2,0)

if not(NatGasTransmissionVector == None):
    computeOptInputs(NatGasTransmissionVector,fullGridSHP,Transmission_Lines_csv_name,0)

if not(CO2StorageVector == None):
    computeOptInputs(CO2StorageVector,fullGridSHP,CO2_Storage_csv_name,0)

if not(HydrogenStorageVector1 == None):
    computeOptInputs(HydrogenStorageVector1,fullGridSHP,Hydrogen_Storage_csv_name_1,Hydrogen_flag)

if not(HydrogenStorageVector2 == None):
    computeOptInputs(HydrogenStorageVector2,fullGridSHP,Hydrogen_Storage_csv_name_2,Hydrogen_flag)

