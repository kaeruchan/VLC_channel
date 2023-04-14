from turtle import circle
import matplotlib
import PyQt6.QtCore
import matplotlib.patches as patches
from matplotlib import cm

matplotlib.rcParams['text.usetex'] = True
import matplotlib.pyplot as plt
plt.rcParams['font.family'] = 'Times New Roman'
plt.rcParams['xtick.direction'] = 'in'

from mpl_toolkits.mplot3d import Axes3D
import mpl_toolkits.mplot3d.art3d as art3d

from argparse import ArgumentParser

import os, sys

import numpy as np

def parser():
    usage = 'Usage: python {} [--case <Case>] [--loop <Loop Number>] [--ps <Ps>]'
    argparser = ArgumentParser(usage=usage)
    argparser.add_argument('--case', type=int,
                           required=True,
                           dest='case',
                           help='Distribution Case')
    argparser.add_argument('--loop', type=int,
                           required=True,
                           dest='loop',
                           help='Loop Number')
    argparser.add_argument('--ps', type=float,
                           required=True,
                           dest='ps',
                           help='Ps')
    argparser.add_argument('--user',type=int,
                           required=True,
                           dest='User',
                           help='User Type')
    argparser.add_argument('--result', '-r',
                           type=str,
                           required=True,
                           dest='Result',
                           help='result')
    arg = argparser.parse_args()
    case = arg.case
    loop = arg.loop
    ps = arg.ps
    user = arg.User
    res = arg.Result
    
    return case, loop, ps, user, res


def file_read(case,loop_num,ps,user_type,res_type):
    x = np.array([])
    y = np.array([])    
    z = np.array([])
    
    directory = 'results/case' + str(case) \
            + '/Loop_num=' + str(loop_num) \
            + '/Ps=' + str(ps) \
            + '/user_type' + str(user_type) \
            + '/VLC_' + str(res_type) + '.txt'
    file_name = open(directory)
    data = file_name.readlines()

    x_cache = -np.Inf
    y_cache = -np.Inf
    for num in data:
        if float(num.split(' ')[0]) > x_cache:
            x_cache = float(num.split(' ')[0])
            x = np.append(x,float(num.split(' ')[0]))
        # x.append(float(num.split(' ')[0]))
        # y.append(float(num.split(' ')[1]))
        if float(num.split(' ')[1]) > y_cache:
            y_cache = float(num.split(' ')[1])
            y = np.append(y,float(num.split(' ')[1]))
        # print(y)
        z = np.append(z,float(num.split(' ')[2]))

    file_name.close()
    
    z = z.reshape([len(x),len(y)]).T
    # print(z)
    # print(z.shape)

    return np.array(x),np.array(y),np.array(z)





def main(argv):

    case, loop, ps, user, res = parser()
    x,y,z = file_read(case,loop,ps,user,res)
    
    x, y = np.meshgrid(x,y)
    # print(z)


    fig = plt.figure(figsize=(8,6),constrained_layout=True)
    axes = fig.gca(projection='3d')
    norm = plt.Normalize(z.min(),z.max())
    colors = cm.jet(norm(z))

    surf = axes.plot_surface(x,y,z, facecolors=colors, shade=False)
    surf.set_facecolor((0,0,0,0))

    axes.set_xlim([0,40])
    axes.set_ylim([0,40])
    axes.set_zlim([0,2.5])
    axes.set_yticks(np.arange(0,50,10),size=14)
    axes.set_xticks(np.arange(0,50,10),size=14)
    axes.set_zticks(np.arange(0,3,0.5),size=14)
    
    # axes.zaxis.set_major_locator(matplotlib.ticker.LinearLocator(10))
    #  A StrMethodFormatter is used automatically
    # axes.zaxis.set_major_formatter('{x:.02f}')
    # fig.colorbar(surf, shrink=.5, aspect=5)

    # axes.legend(loc="upper left", borderaxespad=0, fontsize=12)
    axes.set_xlabel('$x_E$~(m)', fontdict={'size': 14})
    axes.set_ylabel('$y_E$~(m)', fontdict={'size': 14})
    if res == 'sec':
        zlabel = 'Secrecy sum rate (bit/hz/sec)'
    elif res == 'eve':
        zlabel = 'Transmission Capacity of Eve (bit/hz/sec)'
    elif res == 'user':
        zlabel = 'Sum rate of users (bit/hz/sec)'
    axes.set_zlabel(zlabel, fontdict={'size': 14})
    
    
    dirs = 'output/figure/case' + str(case) + '/Loop_num=' + str(loop) + '/Ps=' + str(ps) + '/user_type' + str(user)
    os.makedirs(dirs, exist_ok=True)
    os.chdir(dirs)
    for spine in axes.spines.values():
        spine.set_visible(False)
    fig.tight_layout()
    fig.subplots_adjust(left=-0.11)
    plt.savefig(str(res)+ '.png',dpi=300,bbox_inches='tight')
    plt.savefig(str(res)+ '.eps',dpi=300,bbox_inches='tight')
    plt.savefig(str(res)+ '.pdf',dpi=300,bbox_inches='tight')
    # plt.show()
    
if __name__ == '__main__':
    main(sys.argv[1:])