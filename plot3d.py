from turtle import circle
import matplotlib
import PyQt6.QtCore
import matplotlib.patches as patches

matplotlib.rcParams['text.usetex'] = True
import matplotlib.pyplot as plt
plt.rcParams['font.family'] = 'Times New Roman'
plt.rcParams['xtick.direction'] = 'in'

from mpl_toolkits.mplot3d import Axes3D
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


    # Scenario 1
    U = np.array([
        [6,6], #U1
        [34,6], #U2
        [34,34], #U3
        [6,34], #U4
        [20,10], #U5
        [20,30] #U6
    ])

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


    fig, axes = plt.subplots(figsize=(8,6),subplot_kw=dict(projection='3d'))

    axes.set_xlim([0,40])
    axes.set_ylim([0,40])
    axes.set_zlim([0,4])
    axes.set_yticks(np.arange(0,50,10),size=14)
    axes.set_xticks(np.arange(0,50,10),size=14)
    axes.set_zticks(np.arange(0,5,1),size=14)
    # print(P[1])
    # plt.scatter(
    #      P[:,0],
    #      P[:,1],
    #     label="LED Array"
    # )
    # radius = (3.98-0.85) * np.tan(np.deg2rad(60))
    height = np.full(P.shape[0],3.98)
    user_height = np.full(U.shape[0],0.85)
    # print(height)
    
    plane_x, plane_y = np.meshgrid(range(0,41,1),range(0,41,1))
    plane_z = np.full(plane_x.shape,0.85)
    
    
    axes.scatter(P[:,0],P[:,1],height,color='blue',label='LED Source')
    axes.plot_surface(plane_x,plane_y,plane_z,alpha=.3)
    axes.stem(U[:,0],U[:,1],user_height,linefmt='C1-',markerfmt='C1o',basefmt='None',label='User')
   
    # print(P.shape)
    # for i in range(P.shape[0]):
    #     circle = plt.Circle(P[i],radius,linestyle='--', facecolor='None', edgecolor='black')
    #     axes.add_patch(circle)
    
    s = np.array([
        [1,1],
        [39,1],
        [39,39],
        [1,39],
        [1,1]
    ])
    
    # z = np.
    # axes.plot(s[:,0],s[:,1],color='red',label='Distributed Area')
    # axes.add_patch(circle11)
    # axes.add_patch(circle12)
    # axes.add_patch(circle21)

    axes.legend(loc="upper left", borderaxespad=0, fontsize=12)
    axes.set_xlabel('$x$~(m)', fontdict={'size': 16})
    axes.set_ylabel('$y$~(m)', fontdict={'size': 16})
    axes.set_zlabel('$z$~(m)', fontdict={'size': 16})
    axes.text(0, 20, 0.85, 'Device plane', color='black')
    fig.tight_layout()
    fig.subplots_adjust(left=-0.11)
    plt.savefig('LED3d_user1.png',dpi=300,bbox_inches='tight')
    plt.savefig('LED3d_user1.eps',dpi=300,bbox_inches='tight')
    # plt.show()
    
if __name__ == '__main__':
    main(sys.argv[1:])