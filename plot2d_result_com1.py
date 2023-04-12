# from turtle import circle
import matplotlib
import PyQt6.QtCore
import matplotlib.patches as patches
from matplotlib import cm

matplotlib.rcParams['text.usetex'] = True
import matplotlib.pyplot as plt
plt.rcParams['font.family'] = 'Times New Roman'
plt.rcParams['xtick.direction'] = 'in'

# from mpl_toolkits.mplot3d import Axes3D
# import mpl_toolkits.mplot3d.art3d as art3d

from argparse import ArgumentParser

import os, sys

import numpy as np

class matlabcolormap:
    orange = [0.8500,0.3250,0.0980]
    blue = [0,0.4470,0.7410]
    yellow = [0.9290,0.6940,0.1250]
    purple = [0.4940,0.1840,0.5560]
    cyan = [0.3010,0.7450,0.9330]
    green = [0.4660,0.6740,0.1880]
    red = [0.6350,0.0780,0.1840]

def parser():
    usage = 'Usage: python {}[--loop <Loop Number>] [--ps <Ps>]'
    argparser = ArgumentParser(usage=usage)
    # argparser.add_argument('--case', type=int,
    #                        required=True,
    #                        dest='case',
    #                        help='Distribution Case')
    argparser.add_argument('--loop', type=int,
                           required=True,
                           dest='loop',
                           help='Loop Number')
    argparser.add_argument('--ps', type=float,
                           required=True,
                           dest='ps',
                           help='Ps')
    # argparser.add_argument('--user',type=int,
    #                        required=True,
    #                        dest='User',
    #                        help='User Type')
    # argparser.add_argument('--result', '-r',
    #                        type=str,
    #                        required=True,
    #                        dest='Result',
    #                        help='result')
    arg = argparser.parse_args()
    # case = arg.case
    loop = arg.loop
    ps = arg.ps
    # user = arg.User
    # res = arg.Result
    
    return loop, ps


def file_read(case,loop_num,ps,user_type,res_type,opt=0):
    # x = np.array([])
    # y = np.array([])    
    # z = np.array([])
    x = []
    y = []
    if opt == 1:
        directory = 'results/case' + str(case) \
                + '_trans_com/Loop_num=' + str(loop_num) \
                + '/Ps_max=' + str(ps) \
                + '/user_type' + str(user_type) \
                + '/VLC_' + str(res_type) + '.txt'
    else:
        directory = 'results/case' + str(case) \
                + '_trans/Loop_num=' + str(loop_num) \
                + '/Ps_max=' + str(ps) \
                + '/user_type' + str(user_type) \
                + '/VLC_' + str(res_type) + '.txt'    
                
    file_name = open(directory)
    data = file_name.readlines()

    # x_cache = -np.Inf
    # y_cache = -np.Inf
    for num in data:
        x.append(float(num.split(' ')[0]))
        y.append(float(num.split(' ')[1]))

    file_name.close()
    
    return x,y

def file_read_com(case,loop_num,ps,user_type,res_type,opt=0):
    # x = np.array([])
    # y = np.array([])    
    # z = np.array([])
    x = []
    y = []
    if opt == 1:
        directory = 'results/case' + str(case) \
                + '_trans_opt/Loop_num=' + str(loop_num) \
                + '/Ps_max=' + str(ps) \
                + '/user_type' + str(user_type) \
                + '/VLC_' + str(res_type) + '_com.txt'
    else:
        directory = 'results/case' + str(case) \
                + '_trans/Loop_num=' + str(loop_num) \
                + '/Ps_max=' + str(ps) \
                + '/user_type' + str(user_type) \
                + '/VLC_' + str(res_type) + '_com.txt'    
                
    file_name = open(directory)
    data = file_name.readlines()

    # x_cache = -np.Inf
    # y_cache = -np.Inf
    for num in data:
        x.append(float(num.split(' ')[0]))
        y.append(float(num.split(' ')[1]))

    file_name.close()
    
    return x,y





def main(argv):

    loop, ps = parser()

    res = 'user'
    
    x_1_1,y_1_1 = file_read(1,loop,ps,1,res)
    x_1_2,y_1_2 = file_read(1,loop,ps,2,res)
    x_1_3,y_1_3 = file_read(1,loop,ps,3,res)
    x_2_1,y_2_1 = file_read(2,loop,ps,1,res)
    x_2_2,y_2_2 = file_read(2,loop,ps,2,res)
    x_2_3,y_2_3 = file_read(2,loop,ps,3,res)
    x_3_1,y_3_1 = file_read(3,loop,ps,1,res)
    x_3_2,y_3_2 = file_read(3,loop,ps,2,res)
    x_3_3,y_3_3 = file_read(3,loop,ps,3,res)
    x_1_1_com,y_1_1_com = file_read_com(1,loop,ps,1,res)
    x_1_2_com,y_1_2_com = file_read_com(1,loop,ps,2,res)
    x_1_3_com,y_1_3_com = file_read_com(1,loop,ps,3,res)
    x_2_1_com,y_2_1_com = file_read_com(2,loop,ps,1,res)
    x_2_2_com,y_2_2_com = file_read_com(2,loop,ps,2,res)
    x_2_3_com,y_2_3_com = file_read_com(2,loop,ps,3,res)
    x_3_1_com,y_3_1_com = file_read_com(3,loop,ps,1,res)
    x_3_2_com,y_3_2_com = file_read_com(3,loop,ps,2,res)
    x_3_3_com,y_3_3_com = file_read_com(3,loop,ps,3,res)
    # x, y = np.meshgrid(x,y)
    # print(z)
    x_dummy = x_1_1
    y_dummy = -np.ones(len(x_dummy))

    fig, axes = plt.subplots(figsize=(8,6))
    # norm = plt.Normalize(z.min(),z.max())
    # colors = cm.jet(norm(z))

    # surf = axes.plot_surface(x,y,z, facecolors=colors, shade=False)
    # surf.set_facecolor((0,0,0,0))
    plt.plot(x_1_1,
             y_1_1,
             color = matlabcolormap.red,
             linestyle = '-',
             marker = 'o',
             markerfacecolor = 'None',
             linewidth = 2,
             markersize = 10,
             label = 'Broadcast'
    )
    plt.plot(x_1_1_com,
             y_1_1_com,
             color = matlabcolormap.red,
             linestyle = '--',
             marker = 's',
             markerfacecolor = 'None',
             linewidth = 2,
             markersize = 10,
            #  label = 'Broadcast'
    )
    # plt.plot(x_1_2,
    #          y_1_2,
    #          color = matlabcolormap.blue,
    #          linestyle = '-',
    #          marker = 'o',
    #          markerfacecolor = 'None',
    #          linewidth = 2,
    #          markersize = 10,
    #          label = 'Broadcast, Scenario 2'
    # )
    # plt.plot(x_1_3,
    #          y_1_3,
    #          color = matlabcolormap.yellow,
    #          linestyle = '-',
    #          marker = 'o',
    #          markerfacecolor = 'None',
    #          linewidth = 2,
    #          markersize = 10,
    #          label = 'Broadcast, Scenario 3')
    
    plt.plot(x_2_1,
             y_2_1,
             color = matlabcolormap.yellow,
             linestyle = '-',
             marker = '^',
             markerfacecolor = 'None',
             linewidth = 2,
             markersize = 10,
             label = 'Simple'
    )
    plt.plot(x_2_1_com,
             y_2_1_com,
             color = matlabcolormap.yellow,
             linestyle = '--',
             marker = 'v',
             markerfacecolor = 'None',
             linewidth = 2,
             markersize = 10,
            #  label = 'Simple'
    )
    # plt.plot(x_2_2,
    #          y_2_2,
    #          color = matlabcolormap.blue,
    #          linestyle = '--',
    #          marker = '^',
    #          markerfacecolor = 'None',
    #          linewidth = 2,
    #          markersize = 10,
    #          label = 'Simple, Scenario 2'
    # )
    # plt.plot(x_2_3,
    #          y_2_3,
    #          color = matlabcolormap.yellow,
    #          linestyle = '--',
    #          marker = '^',
    #          markerfacecolor = 'None',
    #          linewidth = 2,
    #          markersize = 10,
    #          label = 'Simple, Scenario 3')
    
    plt.plot(x_3_1,
             y_3_1,
             color = matlabcolormap.blue,
             linestyle = '-',
             marker = '1',
             markerfacecolor = 'None',
             linewidth = 2,
             markersize = 10,
             label = 'Smart'
    )
    plt.plot(x_3_1_com,
             y_3_1_com,
             color = matlabcolormap.blue,
             linestyle = '--',
             marker = '2',
             markerfacecolor = 'None',
             linewidth = 2,
             markersize = 10,
            #  label = 'Smart'
    )
    # plt.plot(x_3_2,
    #          y_3_2,
    #          color = matlabcolormap.blue,
    #          linestyle = ':',
    #          marker = 's',
    #          markerfacecolor = 'None',
    #          linewidth = 2,
    #          markersize = 10,
    #          label = 'Smart, Scenario 2'
    # )
    # plt.plot(x_3_3,
    #          y_3_3,
    #          color = matlabcolormap.yellow,
    #          linestyle = ':',
    #          marker = 's',
    #          markerfacecolor = 'None',
    #          linewidth = 2,
    #          markersize = 10,
    #          label = 'Smart, Scenario 3')
    
    
    
    plt.plot(x_dummy,
             y_dummy,
             color = 'black',
             linestyle = '--',
             marker = 'None',
             markerfacecolor = 'None',
             linewidth = 2,
             markersize = 10,
             label = 'LED arragement shape in [23]'
    )

    axes.set_xlim([0.1,1])
    axes.set_ylim([0,5])
    # axes.set_zlim(0,5)
    plt.xticks(np.arange(0.1,1.1,0.1),fontsize=14)
    plt.yticks(np.arange(0,6,1),fontsize=14)
    # axes.set_zticks(np.arange(0,6,1),size=14)
    plt.grid(True, which='major', linestyle = '-', alpha=0.6)
    plt.grid(True, which='minor', linestyle = ':', alpha=0.3)
   
    
    # axes.zaxis.set_major_locator(matplotlib.ticker.LinearLocator(10))
    #  A StrMethodFormatter is used automatically
    # axes.zaxis.set_major_formatter('{x:.02f}')
    # fig.colorbar(surf, shrink=.5, aspect=5)
    # box = axes.get_position()
    # axes.set_position([box.x0, box.y0, box.width * 0.8, box.height])
    axes.legend(loc="upper left", 
                borderaxespad=1, 
                fontsize=10,
                # bbox_to_anchor=(1, 0.5)
                )
    axes.set_xlabel('Transmission power $P_s$~(W)', fontdict={'size': 16})
    axes.set_ylabel('Sum rate of users~(bit/hz/sec)', fontdict={'size': 16})
    # if res == 'sec':
    #     zlabel = 'Secrecy Capacity'
    # elif res == 'eve':
    #     zlabel = 'Transmission Capacity of Eve (bit/hz/sec)'
    # elif res == 'user':
    #     zlabel = 'Sum Rate of Users (bit/hz/sec)'
    # axes.set_zlabel(zlabel, fontdict={'size': 16})
    
    
    dirs = 'output/figure_d' + '/Ps=' + str(ps)
    os.makedirs(dirs, exist_ok=True)
    os.chdir(dirs)
    # fig.tight_layout()
    # fig.subplots_adjust(left=-0.11)
    plt.savefig(str(res)+ '_sce1.png',bbox_inches='tight',dpi=300)
    plt.savefig(str(res)+ '_sce1.eps',bbox_inches='tight',dpi=300)
    # plt.show()
    
if __name__ == '__main__':
    main(sys.argv[1:])