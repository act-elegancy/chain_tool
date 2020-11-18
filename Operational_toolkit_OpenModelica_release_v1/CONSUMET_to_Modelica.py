import numpy as np

data_regression = np.genfromtxt('regression.csv', delimiter=',')

#input_lb    = [273.15,  1.0]
#input_ub    = [303.15, 40.0]
 #   modelString = ['Density', 'Enthalpy', 'Entropy', 'Viscosity']

# Specify the index of the property type
imodel = 3; 

string = str()
for row in data_regression:
    if row[0] == imodel:
        if row[-1] != 0.0:
            tterm = "Tr^" + str(row[1]) + "*" if row[1] > 0 else str() # Tr is the first variable
            pterm = "Pr^" + str(row[2]) + "*" if row[2] > 0 else str() # Pr is the second variable
            coeff = "(" + str(row[3]) + ")"
            if row[3] != 0:
                string = string + tterm + pterm + coeff + "+"

string = string[:-1]
print(string)


