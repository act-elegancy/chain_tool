# This script is designed to visualise the outputs from optimisation, particularly the investment related decisions.
# Author name: Nixon Sunny
# Author email = nixon.sunny13@imperial.ac.uk
# Organisation = Imperial College London
# Date: 05 March 2019
# Version: 1.0

##Elegancy GIS Outputs=name
##Outputs_path=string C:\Users\JohnDoe\Desktop\Optimisation_Files\
##Process_units_file_name=string prod_rate.csv
##Storage_units_file_name=string inventory_rsrc.csv
##Distribution_units_file_name=string total_flow_rate.csv
##Gridded_Shapefile_Layer=vector Polygon
##Gridded_Demand_Layer=optional vector Polygon
##Csv_file_showing_temporal_variations_in_demand=optional string Demand_Ratio.csv
##Enter_1_if_you_would_like_a_demand_variation_map_with_time=optional string 0

# Load libraries from QGIS and Python core
from qgis.core import *
from qgis.utils import *
from PyQt4.QtCore import *
import math
import csv
import os

#Initialise the lists needed for field identification.
major_time = []
process_output = []
process_field_raw = []
strg_output = []
strg_field_raw = []
dist_output = []
dist_field_from = []
dist_field_to = []
process_field_and_coordinates = []
strg_field_and_coordinates = []
dist_from_field_and_coordinates = []
dist_to_field_and_coordinates = []
Demand_Ratio = Csv_file_showing_temporal_variations_in_demand

# Retrieve the grid layer and store it in the following object.
Grid_layer = processing.getObject(Gridded_Shapefile_Layer)
Demand_Layer = processing.getObject(Gridded_Demand_Layer)

# Defining a function to determine the coordinates of each feature.
def coordinate_finder(input_layer):
    """ A function to determine the coordinates of all fields in the shape layer """
    field_id_long = [] # The list to contain the field ids in long form after reading the feature
    field_id = []# The list which contains the actual field ids as an output
    coordinates_list = []# The list containing the coordinates corresponding to each field
    for feature in input_layer.getFeatures():
        # looping over all the features in this layer
        coordinates_list.append(list(feature.geometry().centroid().asPoint()))# Add the coordinates of the centroid of each feature/ field.
        field_id_long.append(feature[0])# Correspondingly, add the field id to the output list
    field_id = map(int,field_id_long)# Convert the field_id_long form into integers for ready manipulation.
    return coordinates_list, field_id

coordinates_list, field_id = coordinate_finder(Grid_layer) # Call on any gridded layer to determine all field ids and coordinates

grid_coordinates_raw = [field_id, coordinates_list] # create a new list containing both the field id and corresponding coordinates.
grid_coordinates = list(map(list, zip(*grid_coordinates_raw)))# Reconstruct the combined list such that multiple columns are shown..

for grid in grid_coordinates:
    # loop over every grid in this list
    coordinates_without_brackets = str(grid[1]).replace('[','').replace(']','')# convert the list of coordinates into string format and replace parentheses.
    grid[1] = coordinates_without_brackets #replace the list of coordinates with the string format.

# Collct the field id's from process output and add to list.    
Process_units_file_path_and_name = Outputs_path + Process_units_file_name
with open(Process_units_file_path_and_name) as File:
    reader = csv.reader(File, delimiter=',', quotechar=',',
                        quoting=csv.QUOTE_MINIMAL)

    for row in reader:
        process_output.append(row)# Add each row of the optimisation output file into this list.

    for output in process_output[1:]:
        #'loop over each row in the output list from first item, ignoring header
        process_field_raw.append(output[2])# Add the third column along which should be field id
        major_time.append(output[0])

    process_field = map(int, process_field_raw) # Convert from string to integer format
    process_field.insert(0,"FIELD_ID") # Add a heading as the first list item.
    for field in process_field[1:]:
        # loop over every field in process outputs file
        for grid in grid_coordinates:
            # loop over every grid in grid and coordinates
            if field in grid:
                # check if the field from process output is in the grid and coordinates list.
                process_field_and_coordinates.append(grid)# If so, add the grid and coordinates to this new list.

process_field_and_coordinates.insert(0,[" FIELD_ID",["X-COORDINATE","Y-COORDINATE"]])#Insert field headings.

process_compiled_list = [process_output, process_field_and_coordinates]# Produce a compiled list with the grid coordinates added to process output
process_list_with_brackets = list(map(list, zip(*process_compiled_list)))# Reformat the lists in column format.
process_csv_path_and_filename = Outputs_path + "process_final.csv" #Write the output file name and path for the final combined csv file.

process_final = []# List to contain the final output contents.

for process_item in process_list_with_brackets:
    # loop over each item in this combined list 
    process_output_string = str(process_item[0]).replace('[','').replace(']','')# remove the brackets surrounding the field id and convert to string.
    field_and_coordinates_string = str(process_item[1]).replace('[','').replace(']','')# remove the brackets surrounding coordinates and convert to string
    process_item[0] = process_output_string # Update the first item in the list as a string
    process_item[1] = field_and_coordinates_string# Update the coordinates item in this list.
    process_item = process_item[0] +"," + process_item[1]
    process_item_final = process_item.replace("'","")# Remove apostrophes in output text
    process_final.append(process_item_final)# Append the list with refined contents

with open(process_csv_path_and_filename,"wb") as process_file:
    # Create the output csv and write each line of the process_final list.
    for line in process_final:
        process_file.write(line + '\n')

# the following code is a replication of the above code, can be refactored and written as a function
# with a minor modification which is to change the column number of field id.
Storage_units_file_path_and_name = Outputs_path + Storage_units_file_name
with open(Storage_units_file_path_and_name) as File:
    reader = csv.reader(File, delimiter=',', quotechar=',',
                        quoting=csv.QUOTE_MINIMAL)

    for row in reader:
        strg_output.append(row)
    
    for output in strg_output[1:]:
        strg_field_raw.append(output[3])

    strg_field = map(int, strg_field_raw)
    strg_field.insert(0,"FIELD_ID")
    for field in strg_field[1:]:
        for grid in grid_coordinates:
            if field in grid:
                strg_field_and_coordinates.append(grid)

strg_field_and_coordinates.insert(0,[" FIELD_ID",["X-COORDINATE","Y-COORDINATE"]])
strg_compiled_list = [strg_output, strg_field_and_coordinates]
strg_list_with_brackets = list(map(list, zip(*strg_compiled_list)))
strg_csv_path_and_filename = Outputs_path + "storage_final.csv"

strg_final = []

for strg_item in strg_list_with_brackets:
    strg_output_string = str(strg_item[0]).replace('[','').replace(']','')
    field_and_coordinates_string = str(strg_item[1]).replace('[','').replace(']','')
    strg_item[0] = strg_output_string
    strg_item[1] = field_and_coordinates_string
    strg_item = strg_item[0] +"," + strg_item[1]
    strg_item_final = strg_item.replace("'","")
    strg_final.append(strg_item_final)

with open(strg_csv_path_and_filename,"wb") as strg_file:
    for line in strg_final:
        strg_file.write(line + '\n')

# Again this code is a replciation of the above with the exception being field id columns.
# Rewrite as a common function if limited by CPU speed, it is written this way to assist in
# any rapid prototyping allowing changes to be made to the output files.
Distribution_units_file_path_and_name = Outputs_path + Distribution_units_file_name
with open(Distribution_units_file_path_and_name) as File:
    reader = csv.reader(File, delimiter=',', quotechar=',',
                        quoting=csv.QUOTE_MINIMAL)

    for row in reader:
        dist_output.append(row)

    for output in dist_output[1:]:
        dist_field_from.append(output[2])
        dist_field_to.append(output[3])

    dist_grid_from = map(int, dist_field_from)
    dist_grid_from.insert(0,"FIELD_ID")
    dist_grid_to = map(int, dist_field_to)
    dist_grid_to.insert(0,"FIELD_ID")

    dist_lists = [dist_grid_from, dist_grid_to]
    dist_fields_and_coordinates = [dist_from_field_and_coordinates, dist_to_field_and_coordinates]

    for distribution_list in dist_lists:
        # loop over from field list and to field list.
        list_index = dist_lists.index(distribution_list)# Store the index of the list in this variable
        for field in distribution_list[1:]:
            # loop over all fields in the designated list, ignoring the header.
            for grid in grid_coordinates:
                # loop over all potential grids in the layer
                if field in grid:
                    # check if the field in either from or to lists is in the grid, if so add it to the list below.
                    dist_fields_and_coordinates[list_index].append(grid)

dist_fields_and_coordinates[0].insert(0,["FROM FIELD_ID",["FROM X-COORDINATE","FROM Y-COORDINATE"]])
dist_fields_and_coordinates[1].insert(0,["TO FIELD_ID",["TO X-COORDINATE","TO Y-COORDINATE"]])

dist_compiled_list = [dist_output, dist_fields_and_coordinates[0], dist_fields_and_coordinates[1]]
dist_list_with_brackets = list(map(list, zip(*dist_compiled_list)))
dist_csv_path_and_filename = Outputs_path + "distribution_final.csv"

dist_final = []

for dist_item in dist_list_with_brackets:
    dist_output_string = str(dist_item[0]).replace('[','').replace(']','')
    from_field_and_coordinates_string = str(dist_item[1]).replace('[','').replace(']','')
    to_field_and_coordinates_string = str(dist_item[2]).replace('[','').replace(']','')
    dist_item[0] = dist_output_string
    dist_item[1] = from_field_and_coordinates_string
    dist_item[2] = to_field_and_coordinates_string
    dist_item = dist_item[0] +"," + dist_item[1] +","+ dist_item[2]
    dist_item_final = dist_item.replace("'","")
    dist_final.append(dist_item_final)

with open(dist_csv_path_and_filename,"wb") as dist_file:
    for line in dist_final:
        dist_file.write(line + '\n')

"""
Frpm here on, the written process csv is reread and the items are sorted
This is specific to the problem instance
"""
# The number of specific occurences of major time is revealed and held in a new set for future use.
unique_major_time = list(set(major_time))

def writeSortedOutput(input_list_of_tech_strings,all_tech_lists,first_line_of_csv):
    " A function to sort the contents of the technology csv and save it as a vector layer"
    csv_files = []# A list containing path strings for all technology csv.
    for tech in all_tech_lists:
        # loop over all technologies in a list of technologies.
        index_for_string = all_tech_lists.index(tech)# create an index representing the technology number in the list.
        for tm in unique_major_time:
            csv_path = Outputs_path + input_list_of_tech_strings[index_for_string]+ "_"+ "%s.csv" % (tm)
            # depending on the index write the name of tech as csv
            csv_files.append(csv_path)# add the path string into the list to csv files.
            with open(csv_path,"wb") as csv_file:
                # Create a new csv file which contains the output contents specific to that technology.
                csv_file.write(first_line_of_csv + '\n')
                for item in tech:
                    if item[0] == tm:
                        # loop over all items in tech and tidy up the contents without brackets and aposrophes.
                        item_final = str(item).replace("'","").replace("[","").replace("]","")
                        csv_file.write(item_final + '\n')# write the refined output for each technology.

    # The following focuses on adding the outputs as layer to the map canvas
    for path, directories, files in os.walk(Outputs_path):
        for file in files:
            # looping over all the files in the output path specified and checking if the technology related files are present.
            if str(os.path.join(path,file)) in csv_files:
                fullname = os.path.join(path, file).replace('\\', '/')
                filename = os.path.splitext(os.path.basename(fullname))[0]
                uri = 'file:///%s?crs=%s&delimiter=%s&xField=%s&yField=%s' % (fullname, Grid_layer.crs().authid(), ',', 'X COORDINATE', 'Y COORDINATE')
                # uri specifies the file path, delimiter to use in the text file, name, coordinate system, x and y coordinates.
                layer = QgsVectorLayer(uri, 'layer', 'delimitedtext')# Creates a layer using the details above.
                QgsVectorFileWriter.writeAsVectorFormat(layer, Outputs_path + '/' + filename + '.shp', 'CP1250', None, 'ESRI Shapefile')
                # The above line creates an output vector layer in the coordinate projection as the provided gridded layer.
    return csv_files



def writeProcessTimeList(process_csv_list,filename_string):
    """A function to create time indexed csv of process tech and concatenate it"""
    process_tm = [[] for i in range(len(unique_major_time))]# Generate a list of paths for each major time.
    # loop over the major time periods.
    for tm in unique_major_time:
        tm_index = unique_major_time.index(tm)
        # String recorded to check which files are from the same major time period.
        tm_string = '%s.csv' % (tm)
        for path in process_csv_list:
            if tm_string in path:
                process_tm[tm_index].append(path)

        list_of_csv_paths = []
        concatenated = Outputs_path + filename_string+ "_concatenated_" + tm_string
        list_of_csv_paths.append(concatenated)

        with open(concatenated,"wb") as csv_file, open(process_tm[tm_index][0]) as first_csv:
            for line in first_csv:
                csv_file.write(line)

            for path in process_tm[tm_index][1:]:
                open_csv = open(path,'r')
                open_csv.next()
                for line in open_csv:
                    csv_file.write(line)

    return list_of_csv_paths


def writeStorageTimeList(storage_csv_list,filename_string):
    """A function to create time indexed csv of storage tech and rename contents"""
    storage_tm = [[] for i in range(len(unique_major_time))]# Generate a list of paths for each major time.
    list_of_csv_paths = []

    for tm in unique_major_time:
        tm_index = unique_major_time.index(tm)# String recorded to check which files are from the same major time period.
        tm_string = '%s.csv' % (tm)

        for path in storage_csv_list:
            if tm_string in path:
                storage_tm[tm_index].append(path)

        concatenated = Outputs_path + filename_string+ "_concatenated_" + tm_string
        list_of_csv_paths.append(concatenated)

        with open(concatenated,"wb") as out_csv, open(storage_tm[tm_index][0]) as in_csv:
            reader = csv.reader(in_csv, delimiter=',')
            header = next(reader)
            out_csv.write(str(header).replace("'","").replace('[','').replace(']','') + '\n')
            for row in reader:
                if int(row[5]) >= 10:
                    row[5] = '2000-01-%s' % (row[5].replace(' ','')) + ' 00:00:00.000'
                else:
                    row[5] = '2000-01-0%s' % (row[5].replace(' ','')) + ' 00:00:00.000'
                line = str(row).replace("'","").replace("[","").replace("]","")
                out_csv.write(line + '\n')

    return list_of_csv_paths

	
#def cumulativeProd(list_of_csv_paths):
    # """ A function to sum the different location-indexed production rates together"""
    # all_grids = []
    # all_minor_time = []
    # temp_list = []
    # for path in list_of_csv_paths:
        # path_index = list_of_csv_paths.index(path) + 1
        # cumulative_prod = Outputs_path + "cumulative_prod_"+"%s.csv" %(str(path_index))
        # filename = "cumulative_prod_" +"%s.shp" %(str(path_index))
        # with open(path) as infile, open(cumulative_prod, 'wb') as outfile:
            # reader = csv.reader(infile, delimiter=',')
            # header = next(reader)
            # for row in reader:
                # all_grids.append(row[2])
                # all_minor_time.append(row[4])
                # temp_list.append(row)
            # unique_grids = list(set(all_grids))
            # unique_minor_time = list(set(all_minor_time))
            # str_header = str(header).replace('[','').replace(']','').replace("'","")
            # outfile.write(str_header + '\n')
            # for time in unique_minor_time:
                # for grid in unique_grids:
                    # total_prod = 0
                    # output_flag = []
                    # for row in temp_list:
                        # if row[2] == grid and row[4] == time:
                            # total_prod = total_prod + float(row[5])
                            # Major_time = row[0]
                            # Grid_cell = row[2]
                            # Scenario = row[3]
                            # if int(time) >= 10:
                                # Minor_time = '2000-01-%s' % (time.replace(' ','')) + ' 00:00:00.000'
                            # else:
                                # Minor_time = '2000-01-0%s' % (time.replace(' ','')) + ' 00:00:00.000'
                            # Field_id = row[6]
                            # X_coordinate = row[7]
                            # Y_coordinate = row[8]
                            # output_flag.append(1)

                    # if len(output_flag) >= 1:
                        # line = [Major_time," ",Grid_cell,Scenario,Minor_time,total_prod,Field_id,X_coordinate,Y_coordinate]
                        # str_line = str(line).replace('[','').replace(']','').replace("'","")
                        # outfile.write(str_line + '\n')

            # fullname = cumulative_prod.replace('\\', '/')
            # uri = 'file:///%s?crs=%s&delimiter=%s&xField=%s&yField=%s' % (fullname, Grid_layer.crs().authid(), ',', 'X COORDINATE', 'Y COORDINATE')
            # # uri specifies the file path, delimiter to use in the text file, name, coordinate system, x and y coordinates.
            # layer = QgsVectorLayer(uri, 'layer', 'delimitedtext')# Creates a layer using the details above.
            # QgsVectorFileWriter.writeAsVectorFormat(layer, Outputs_path + '/' + filename , 'CP1250', None, 'ESRI Shapefile')
            # The above line creates an output vector layer in the coordinate projection as the provided gridded layer.

def outputWriter(final_output_csv,tech_index_in_list):
    OUTPUT_TECH_RAW = [[],[],[]]# New list to hold the strings from technologies in the output files..
    OUTPUT_TECH = [[],[],[]]# New list to hold unique strings from technologies in the output files..
    ALL_TECH_LISTS = [[],[],[]]# All technology lists provided here.
    for output in final_output_csv:
        # loops over all the outout csvs - process, storage, dist
        output_index = final_output_csv.index(output)
        # Determine the index of the output within the list of outputs
        with open(output) as output_csv:
            reader = csv.reader(output_csv, delimiter=',')
            header = next(reader)# identifies the first row of the reader object as the header
            for row in reader:
                # Append the list raw with all the technology strings present in output file.
                OUTPUT_TECH_RAW[output_index].append(row[tech_index_in_list[output_index]])# Creates a list of all the technologies in the process output

        OUTPUT_TECH[output_index] = list(set(OUTPUT_TECH_RAW[output_index]))# Determine a list of unique technology strings present.
        ALL_TECH_LISTS[output_index] = [[] for i in range(len(OUTPUT_TECH[output_index]))] # Create as many lists as there are technologies.
        with open(output) as output_csv:
            #open that output file and read the contents
            reader = csv.reader(output_csv, delimiter=',')
            header = next(reader)
            for row in reader:
                for j in range(len(OUTPUT_TECH[output_index])):
                    #iterate over as many technology strings as needs be.
                    if row[tech_index_in_list[output_index]] == OUTPUT_TECH[output_index][j]:
                        # Check if the technology string in the output file is part of the unique strings
                        ALL_TECH_LISTS[output_index][j].append(row)# append the list in a unique position and create unique lists for each technology.

    return OUTPUT_TECH, ALL_TECH_LISTS # return a list containing all the unique technologies and all the occurences of those in the outputs from optimisation.

final_output_csv = [process_csv_path_and_filename,strg_csv_path_and_filename,dist_csv_path_and_filename]
tech_index_in_list = [1,1,1]

OUTPUT_TECH, ALL_TECH_LISTS = outputWriter(final_output_csv,tech_index_in_list)


# Create a series of lists needed for writing output csvs and creating vector layers.
PROCESS_TECH = OUTPUT_TECH[0]
STRG_TECH = OUTPUT_TECH[1]
DIST_TECH = OUTPUT_TECH[2]
ALL_PROCESS_LISTS = ALL_TECH_LISTS[0]
ALL_STRG_LISTS = ALL_TECH_LISTS[1]
ALL_DIST_LISTS = ALL_TECH_LISTS[2]


strg_csv_first_line = "Major Time, Storage Type, Resource, Grid Cell, Scenario, Minor Time, Inventory, FIELD ID, X COORDINATE, Y COORDINATE"
process_csv_first_line = "Major Time, Technologies, Grid Cell, Scenario, Minor Time, Production Rate, FIELD ID, X COORDINATE, Y COORDINATE"
dist_csv_first_line  = "Major Time, Distribution Type, From grid, To grid, Scenario, Minor Time, Flowrate, FROM FIELD, FROM X, FROM Y, TO FIELD, TO X, TO Y"

process_string = "process"
storage_string = "storage"
storage_files = writeSortedOutput(STRG_TECH,ALL_STRG_LISTS,strg_csv_first_line)
process_files = writeSortedOutput(PROCESS_TECH,ALL_PROCESS_LISTS,process_csv_first_line)
concatenated_process_list = writeProcessTimeList(process_files,process_string)
concatenated_storage_list = writeStorageTimeList(storage_files,storage_string)
#cumulativeProd(concatenated_process_list)


def writeSortedDistOutput(input_list_of_tech_strings,all_tech_lists,first_line_of_csv):
    " A function to sort the contents of the technology csv and save it as a vector layer"
    distribution_csv_files = []
    for tech in all_tech_lists:
        # loop over all technologies in a list of technologies.
        index_for_string = all_tech_lists.index(tech)# create an index representing the technology number in the list.
        for tm in unique_major_time:
            csv_path = Outputs_path + input_list_of_tech_strings[index_for_string]+ "_dist_"+ "%s.csv" % (tm)
            # depending on the index write the name of tech as csv
            distribution_csv_files.append(csv_path)# add the path string into the list to csv files.
            with open(csv_path,"wb") as csv_file:
                # Create a new csv file which contains the output contents specific to that technology.
                csv_file.write(first_line_of_csv + '\n')
                for item in tech:
                    if item[0] == tm:
                        # loop over all items in tech and tidy up the contents without brackets and aposrophes.
                        item_final = str(item).replace("'","").replace("[","").replace("]","")
                        csv_file.write(item_final + '\n')# write the refined output for each technology.

    return distribution_csv_files

dist_files = writeSortedDistOutput(DIST_TECH,ALL_DIST_LISTS,dist_csv_first_line)

line_start_coordinates = [[] for i in range(len(dist_files))]# A list to hold the line start points for all dist technologies
line_end_coordinates = [[] for i in range(len(dist_files))]# A list to hold the end points for all dist technologies
line_start_fields = [[] for i in range(len(dist_files))]# A list to hold the starting field ids for all dist tech
line_end_fields = [[] for i in range(len(dist_files))]# A list to hold the ending field ids for all dist tech
attribute_dist_type = [[] for i in range(len(dist_files))]# distribution mode type to be added as an attribute in line layer.
attribute_scenario = [[] for i in range(len(dist_files))]# scenario type to be added as an attribute in line layer.
attribute_minortime = [[] for i in range(len(dist_files))]# minor time to be added as an attribute in line layer.
attribute_flowrate = [[] for i in range(len(dist_files))]# flowrate to be added as an attribute in line layer.

for dist_file in dist_files:
    # loop over each distribution technology csv file.
    dist_index = dist_files.index(dist_file)# Determine the index of the technology in the csv.
    with open(dist_file) as dist_csv:
        reader = csv.reader(dist_csv, delimiter=',')
        header = next(reader)
        for row in reader:
            # loop over each row in the output file for each distribution technology
            line_start_fields[dist_index].append(int(row[7]))# for each distribution tech, add the start field for line segment
            line_end_fields[dist_index].append(int(row[10]))#for each distribution tech, add the end field for line segment
            line_start_coordinates[dist_index].append([float(row[8]),float(row[9])])#for each distribution tech, add the x and y start coordinates
            line_end_coordinates[dist_index].append([float(row[11]),float(row[12])])#for each distribution tech, add the x and y end coordinates
            attribute_dist_type[dist_index].append(row[1])# A list of the type of distribution mode to be used as an attribute in the line layer.
            attribute_scenario[dist_index].append(row[4])# A list of the type of scenarioe to be used as an attribute in the line layer.
            attribute_minortime[dist_index].append(row[5])# A list of the type of minor timeto be used as an attribute in the line layer.
            attribute_flowrate[dist_index].append(row[6])# A list of the type of flowrate to be used as an attribute in the line layer.

    # Next loop over the created lists and create new layers
    uri = 'LineString?crs=%s' % (Grid_layer.crs().authid())# Ensure that the output layers have the same CRS as the gridded input layer.
    line_layer = QgsVectorLayer(uri, "line_4pt", "memory")# Create the line layer as a memory layer
    provider = line_layer.dataProvider()# Use data provider to access features
    fields = []
    fields.append(QgsField('ID', QVariant.Double))
    fields.append(QgsField('Scenario', QVariant.String))
    fields.append(QgsField('DistType', QVariant.String))
    fields.append(QgsField('Time', QVariant.String))
    fields.append(QgsField('Flowrate', QVariant.Double))
    provider.addAttributes(fields)
    line_layer.updateFields()


    unique_minor_time = list(set(attribute_minortime[dist_index]))
    for time in unique_minor_time:
        starting_field  = []
        ending_field = []
        starting_coordinates  = []
        ending_coordinates = []
        dist_type = []
        scenario = []
        minor_time = []
        flowrate = []
        minor_time_index = -1

        if int(time) >= 10:
            minor_time_string = '2000-01-%s' % (time.replace(' ','')) + ' 00:00:00.000'
        else:
            minor_time_string = '2000-01-0%s' % (time.replace(' ','')) + ' 00:00:00.000'

        for all_minor_time in attribute_minortime[dist_index]:
            minor_time_index += 1

            if all_minor_time == time:
                starting_field.append(line_start_fields[dist_index][minor_time_index])
                ending_field.append(line_end_fields[dist_index][minor_time_index])
                starting_coordinates.append(line_start_coordinates[dist_index][minor_time_index])
                ending_coordinates.append(line_end_coordinates[dist_index][minor_time_index])
                dist_type.append(attribute_dist_type[dist_index][minor_time_index])
                scenario.append(attribute_scenario[dist_index][minor_time_index])
                minor_time.append(all_minor_time)
                flowrate.append(attribute_flowrate[dist_index][minor_time_index])

        #Set the starting value for the field item counter. 
        item = starting_field[0]
        k = 0
        while item in starting_field:
            field_occurence_index = []
            field_index = -1
            # while loop to cover all the elements in the starting field.
            for field in starting_field:
                field_index += 1
                if field == item:
                    field_occurence_index.append(field_index)

            #Check how many times the item occurs in the list
            if len(field_occurence_index) == 1:
                # if the field only appears once in the start list, i.e, only one distribution line segment starts from this field
                point_a = starting_coordinates[field_occurence_index[0]]# Determine the starting coordinates of this item
                point_b = ending_coordinates[field_occurence_index[0]]# Determine the ending coordinates of this item
                start = QgsPoint(point_a[0],point_a[1])# Use the x and y attributes of the point list to create a QgsPoint object
                end = QgsPoint(point_b[0],point_b[1])# Use the x and y attributes of the end list.
                k += 1
                feature = QgsFeature(line_layer.fields())# Start a Qgs feature
                feature.setGeometry(QgsGeometry.fromPolyline([start,end]))# Tell QGis that the feature being added is a line using two points.
                feature.setAttribute('ID',k)
                feature.setAttribute('Scenario',scenario[field_occurence_index[0]])
                feature.setAttribute('DistType',dist_type[field_occurence_index[0]])
                feature.setAttribute('Time',minor_time_string)
                feature.setAttribute('Flowrate',float(flowrate[field_occurence_index[0]]))
                provider.addFeatures([feature])# Add the feature to the layer
                line_layer.updateExtents()# Update the extents upon addition
                item = ending_field[field_occurence_index[0]]#Update item counter with the field at which the line ends.
                del starting_coordinates[field_occurence_index[0]], ending_coordinates[field_occurence_index[0]]# Delete the starting field and correponding coordinates
                del starting_field[field_occurence_index[0]], ending_field[field_occurence_index[0]]# Delete ending field and coordinates
                del scenario[field_occurence_index[0]], dist_type[field_occurence_index[0]]# Delete the other attributes
                del minor_time[field_occurence_index[0]], flowrate[field_occurence_index[0]]# Delete the other attributes

                #To ensure that the other elements in the list are plotted when one line ends. 
                if len(starting_field) == 0:
                    # if the length of starting field list is zero, then there are no more items in the list.
                    item = 'Complete'
                elif item not in starting_field:
                    # if the item counter at the end of the line is not in the start_list, then update item with the next element in start list.
                    item = starting_field[0]

            elif len(field_occurence_index) > 1:
                # if the field has more connections than one, i.e, there are multiple line segments from this field.
                for index in field_occurence_index:
                    # loop over each index to highlight the fields to which current field has connections.
                    point_a = starting_coordinates[index]# Determine the starting point as above.
                    point_b = ending_coordinates[index]# Same as above
                    start = QgsPoint(point_a[0],point_a[1])# As above
                    end = QgsPoint(point_b[0],point_b[1])# As above
                    k += 1
                    feature = QgsFeature(line_layer.fields())
                    feature.setGeometry(QgsGeometry.fromPolyline([start,end]))
                    feature.setAttribute('ID',k)
                    feature.setAttribute('Scenario',scenario[index])
                    feature.setAttribute('DistType',dist_type[index])
                    feature.setAttribute('Time',minor_time_string)
                    feature.setAttribute('Flowrate',float(flowrate[index]))
                    provider.addFeatures([feature])
                    start = QgsPoint(point_b[0],point_b[1])# After adding the first line segment in, this creates a new start point at the current end point
                    end = QgsPoint(point_a[0],point_a[1])# The end point is set as the start point from earlier so that it returns to complete the next set of connections.             
                    k += 1
                    feature = QgsFeature(line_layer.fields())
                    feature.setGeometry(QgsGeometry.fromPolyline([start,end]))
                    feature.setAttribute('ID',k)
                    provider.addFeatures([feature])
                    line_layer.updateExtents()# Update extents

                item = ending_field[field_occurence_index[-1]]# item takes a value at the end of the loop corresponding to the last field that was added.

                for index in sorted(field_occurence_index, reverse=True):
                    del starting_coordinates[index], ending_coordinates[index]#Delete the coordinates corresponding to added lines
                    del starting_field[index], ending_field[index]#Delete the fields that have just been added
                    del scenario[index], dist_type[index]# Delete the other attributes
                    del minor_time[index], flowrate[index]# Delete the other attributes

                if len(starting_field) == 0:
                    item = 'Complete'
                elif item not in starting_field:
                    item = starting_field[0]
    
    for tm in unique_major_time:
        tm_string = '%s.csv' % (tm)
        if tm_string in dist_file:
            tm_shape = '%s.shp' % (tm)
            #Write each line layer as a new vector layer so that it can be easily visualised.
            QgsVectorFileWriter.writeAsVectorFormat(line_layer, dist_file[:-5]+ tm_shape, 'CP1250', None, 'ESRI Shapefile')

def writetemporalDemand(demand_layer,csv_filename):
    "A function to output the demand variations with time using a demand variation csv"
    iface.mainWindow().statusBar().showMessage("Adding cell ID and area to vector layer") # Update the user in the status bar
    caps = demand_layer.dataProvider().capabilities() # need to have access to layer capabilities in order to update fields
    if not caps: # if the capabilities are not accessible, this a problem.
        iface.messageBar().pushInfo("Error","loading layer capabilities failed", level=QgsMessageBar.WARNING) 
    elif ((not QgsVectorDataProvider.DeleteAttributes) and (not QgsVectorDataProvider.AddAttributes)): # see if attribute methods are available. if they are not, this is a problem
        iface.messageBar().pushInfo("Error","loading data provider methods failed", level=QgsMessageBar.WARNING)
    else: # if these are available, we may proceed
        Additional_attr = []
        Additional_attr.append(QgsField('Time', QVariant.String))
        demand_layer.dataProvider().addAttributes(Additional_attr) # delete all current attributes
        demand_layer.updateFields()
        time_csvpath = Outputs_path + csv_filename
        demand_layer.startEditing() # initiate editing of the layer attributes
        features = demand_layer.getFeatures()
        feature_list = []

        for feature in features: # loop across all features in the layer
            feature_list.append(feature)

        with open(time_csvpath) as Demand_time:
            reader = csv.reader(Demand_time, delimiter=',')
            header = next(reader)
            for row in reader:
                for feature in feature_list:
                    new_feature = QgsFeature(demand_layer.fields())
                    new_feature.setGeometry(feature.geometry())
                    new_feature[0] = feature[0]

                    if not feature[1]:
                        new_feature[1] = NULL
                    else:
                        new_feature[1] = float(row[1])*float(feature[1])

                    if int(row[0]) >= 10:
                        new_feature[2] = '2000-01-%s' % (row[0].replace(' ','')) + ' 00:00:00.000'
                    else:
                        new_feature[2] = '2000-01-0%s' % (row[0].replace(' ','')) + ' 00:00:00.000'
                    demand_layer.dataProvider().addFeatures([new_feature]) # update the feature with the field changes

                demand_layer.commitChanges() # commit these changes 

    return demand_layer

if int(Enter_1_if_you_would_like_a_demand_variation_map_with_time) == 1:
    writetemporalDemand(Demand_Layer,Demand_Ratio)
