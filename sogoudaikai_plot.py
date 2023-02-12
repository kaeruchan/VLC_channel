import matplotlib
import PyQt6.QtCore

matplotlib.rcParams['text.usetex'] = True
import matplotlib.pyplot as plt
plt.rcParams['font.family'] = 'Times New Roman'
plt.rcParams['xtick.direction'] = 'in'
import numpy as np



import os, sys

class matlabcolormap:
    orange = [0.8500,0.3250,0.0980]
    blue = [0,0.4470,0.7410]
    yellow = [0.9290,0.6940,0.1250]
    purple = [0.4940,0.1840,0.5560]
    cyan = [0.3010,0.7450,0.9330]
    green = [0.4660,0.6740,0.1880]
    red = [0.6350,0.0780,0.1840]


def file_read(l_d):
    # x = np.array([])
    # y = np.array([])    
    # z = np.array([])
    x = []
    y = []
    directory ='temp33/l_d=' + str(l_d) + '/sougou.txt'
    
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
    
    x_1,y_1 = file_read(0.4)
    x_2,y_2 = file_read(0.5)
    x_3,y_3 = file_read(0.6)


    fig, axes = plt.subplots(figsize=(8,6))
    
    plt.semilogy(x_1,
                 y_1,
                 color = matlabcolormap.red,
                 linestyle = '-',
                 marker = 'None',
                 linewidth = 2,
                 label = '$l_d = 0.4$')
    
    plt.semilogy(x_2,
                 y_2,
                 color = matlabcolormap.yellow,
                 linestyle = ':',
                 marker = 'None',
                 linewidth = 2,
                 label = '$l_d = 0.5$')
    
    plt.semilogy(x_3,
                 y_3,
                 color = matlabcolormap.blue,
                 linestyle = '--',
                 marker = 'None',
                 linewidth = 2,
                 label = '$l_d = 0.6$')
    
    axes.set_xlim([0,360])
    axes.set_ylim([1e-7,1e-5])
    
    plt.xticks(np.arange(0,420,60),fontsize=14)
    plt.yticks(fontsize=14)
    
    plt.grid(True, which='major', linestyle = '-', alpha=0.6)
    plt.grid(True, which='minor', linestyle = ':', alpha=0.3)
    
    axes.legend(loc='lower left',
                borderaxespad=1,
                fontsize=14)
    
    axes.set_xlabel('Azimuth angle $\\theta$',fontsize=14)
    axes.set_ylabel('$h * u(D_{\\rm PD}, D_{\\rm LED}, D_{U},r)$', fontsize=14)
    
    
    
    dirs = 'output/figure_temp'
    
    os.makedirs(dirs, exist_ok=True)
    os.chdir(dirs)
    
    plt.savefig('result33.png',bbox_inches='tight',dpi=300)
    plt.savefig('result33.eps',bbox_inches='tight',dpi=300)
    
if __name__ == '__main__':
    main(sys.argv[1:])