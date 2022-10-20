import matplotlib
matplotlib.use('TkAgg')
matplotlib.rcParams['text.usetex'] = True 

import matplotlib.pyplot as plt
plt.rcParams['font.family'] = 'Times New Roman'
plt.rcParams['xtick.direction'] = 'in'
plt.rcParams['ytick.direction'] = 'in'

import os
import sys

P11 = [1.2,3.72]
P12 = [10.6,3.72]
P13 = [20,3.72]
P14 = [29.4,3.72]
P15 = [38.8,3.72]
P21 = [5.9,11.86]
P22 = [15.3,11.86]
P23 = [24.7,11.86]
P24 = [34.1,11.86]
P31 = [1.2,20]
P32 = [10.6,20]
P33 = [20,20]
P34 = [29.4,20]
P35 = [38.8,20]
P41 = [5.9,28.14]
P42 = [15.3,28.14]
P43 = [24.7,28.14]
P44 = [34.1,28.14]
P51 = [1.2,36.28]
P52 = [10.6,36.28]
P53 = [20,36.28]
P54 = [29.4,36.28]
P55 = [38.8,36.28]


# Scenario 1
# U1 = [6,6]
# U2 = [34,6]
# U3 = [34,34]
# U4 = [6,34]
# U5 = [20,10]
# U6 = [20,30]

# Scenario 2
# U1 = [13,16]
# U2 = [20,12]
# U3 = [27,16]
# U4 = [27,24]
# U5 = [20,28]
# U6 = [13,24]

# Scenario 3
# U1 = [10.6,14.5]
# U2 = [15.3,22.7]
# U3 = [5.9,22.7]
# U4 = [34.1,20]
# U5 = [34.1,32.2]
# U6 = [34.1,7.8]

# verts = [(5.,5.),
#          (5.,35.),
#          (35.,35.),
#          (35.,5.),
#          (5.,5.)
#         ]

# codes = [
#     Path.MOVETO,
#     Path.LINETO,
#     Path.LINETO,
#     Path.LINETO,
#     Path.LINETO,
# ]

# path = Path(verts, codes)


fig, axes = plt.subplots(figsize=(8,6))

axes.set_xlim([0,40])
axes.set_ylim([0,40])
plt.yticks(size=14)
plt.xticks(size=14)

plt.xlabel()

plt.scatter(
    [
        P11[0],
        P12[0],
        P13[0],
        P14[0],
        P15[0],
        P21[0],
        P22[0],
        P23[0],
        P24[0],
        P31[0],
        P32[0],
        P33[0],
        P34[0],
        P35[0],
        P41[0],
        P42[0],
        P43[0],
        P44[0],
        P51[0],
        P52[0],
        P53[0],
        P54[0],
        P55[0]
    ],
    [
        P11[1],
        P12[1],
        P13[1],
        P14[1],
        P15[1],
        P21[1],
        P22[1],
        P23[1],
        P24[1],
        P31[1],
        P32[1],
        P33[1],
        P34[1],
        P35[1],
        P41[1],
        P42[1],
        P43[1],
        P44[1],
        P51[1],
        P52[1],
        P53[1],
        P54[1],
        P55[1]
    ],
    label="LED Array"
)

axes.legend(loc="upper left", borderaxespad=0, fontsize=12)
plt.savefig("LED.png", bbox_inches="tight", pad_inches = 0.05)
plt.savefig("LED.eps", bbox_inches="tight", pad_inches = 0.05)