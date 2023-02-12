from turtle import circle
import matplotlib
import PyQt6.QtCore
import matplotlib.patches as patches

matplotlib.rcParams['text.usetex'] = True
import matplotlib.pyplot as plt
plt.rcParams['font.family'] = 'Times New Roman'
plt.rcParams['xtick.direction'] = 'in'

from mpl_toolkits.mplot3d import Axes3D
from matplotlib.collections import LineCollection
import mpl_toolkits.mplot3d.art3d as art3d

import os, sys

import numpy as np


def main(argv):
    P = np.array([[1.2,3.72], #P11
        [10.6,3.72], #P12
        [20,3.72], #P13
        [29.4,3.72], #P14
        [38.8,3.72], #P15
        [5.9,11.86], #P21
        [15.3,11.86], #P22
        [24.7,11.86], #P23
        [34.1,11.86], #P24
        [1.2,20], #P31
        [10.6,20], #P32
        [20,20], #P33
        [29.4,20], #P34
        [38.8,20], #P35
        [5.9,28.14], #P41
        [15.3,28.14], #P42
        [24.7,28.14], #P43
        [34.1,28.14], #P44
        [1.2,36.28], #P51
        [10.6,36.28], #P52
        [20,36.28], #P53
        [29.4,36.28], #P54
        [38.8,36.28] #P55
    ])
    # P = np.array([[4.6,4.6], #P11
    #     [12.3,4.6], #P12
    #     [20,4.6], #P13
    #     [27.7,4.6], #P14
    #     [35.4,4.6], #P15
    #     [4.6,12.3], #P21
    #     [12.3,12.3], #P22
    #     [20,12.3], #P23
    #     [27.7,12.3], #P24
    #     [35.4,12.3], #25
    #     [4.6,20], #P31
    #     [12.3,20], #P32
    #     [20,20], #P33
    #     [27.7,20], #P34
    #     [35.4,20], #P35
    #     [4.6,27.7], #P41
    #     [12.3,27.7], #P42
    #     [20,27.7], #P43
    #     [27.7,27.7], #P44
    #     [35.4,27.7], #P45
    #     [4.6,35.4], #P51
    #     [12.3,35.4], #P52
    #     [20,35.4], #P53
    #     [27.7,35.4], #P54
    #     [35.4,35.4] #P55
    # ])


    # Scenario 1
    # U = np.array([
    #     [6,6], #U1
    #     [34,6], #U2
    #     [34,34], #U3
    #     [6,34], #U4
    #     [20,10], #U5
    #     [20,30] #U6
    # ])

    # Scenario 2
    # U = np.array([
    # [13,16],
    # [20,12],
    # [27,16],
    # [27,24],
    # [20,28],
    # [13,24],
    # ])
    # Scenario 3
    # U = np.array([
    #     [10.6,14.5],
    #     [15.3,22.7],
    #     [5.9,22.7],
    #     [34.1,20],
    #     [34.1,32.2],
    #     [34.1,7.8]
    # ])

    fig, axes = plt.subplots(figsize=(8,6))

    axes.set_xlim([0,40])
    axes.set_ylim([0,40])
    plt.yticks(size=16)
    plt.xticks(size=16)
    # print(P[1])
    plt.scatter(
         P[:,0],
         P[:,1],
        label="LED Array"
    )
    # plt.scatter(
    #     U[:,0],
    #     U[:,1],
    #     label='User'
    # )
    height = (3.98-0.85) * np.tan(np.deg2rad(60))
    # print(height)
    # print(P.shape)
    # for i in range(P.shape[0]):
    #     circle = plt.Circle(P[i],height,linestyle='--', facecolor='None', edgecolor='black')
    #     axes.add_patch(circle)
    
    s = np.array([
        [1,1],
        [39,1],
        [39,39],
        [1,39],
        [1,1]
    ])
    
    axes.plot(s[:,0],s[:,1],color='red',label='Distributed Area')
    # axes.add_patch(circle11)
    # axes.add_patch(circle12)
    # axes.add_patch(circle21)

    axes.legend(loc="upper left", 
                # borderaxespad=0, 
                fontsize=12,
                bbox_to_anchor=(0,1.14))
    plt.xlabel('$x$~(m)', fontdict={'size': 16})
    plt.ylabel('$y$~(m)', fontdict={'size': 16})
    
    l1 = [(10.6,20),(20,20)]
    l2 = [(20,20),(15.3,28.14)]
    l3 = [(15.3,28.14),(10.6,20)]
    lc = LineCollection([l1,l2,l3], color=['k','k','k'], linestyle=[':',':',':'],lw=2)
    
    plt.gca().add_collection(lc)
    axes.text(18,25,'$l$',fontsize=16)
    
    
    plt.savefig("LED_1.png", bbox_inches="tight", pad_inches = 0.05)
    plt.savefig("LED.eps", bbox_inches="tight", pad_inches = 0.05)
    
    
if __name__ == '__main__':
    main(sys.argv[1:])