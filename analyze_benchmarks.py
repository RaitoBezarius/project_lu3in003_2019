#!/usr/bin/env python3
import pandas as pd
import re

func_details = re.compile("(?P<name>.*)\((?P<n>\d*)\)")

def get_func_details(x):
    m = func_details.match(x)
    return (m.group('name'), int(m.group('n')))

def clean_up_numbers(x):
    return int(x.replace(',', ''))

def process_markdown_ram_file(lines):
    xs = filter(None, map(lambda x: list(filter(None, x.split('|'))), lines))
    calls = [get_func_details(x[0]) + (clean_up_numbers(x[1]), clean_up_numbers(x[2])) for x in xs]
    raw_df = pd.DataFrame(calls, columns=['Name', 'Size', 'Mean', 'GCs'])
    final_df = raw_df.groupby(['Name', 'Size']).mean()

    return final_df

def get_markdown(filename):
    with open('./ram_benchmark_rts.md', 'r') as f:
        lines = f.read().split('\n')
        return lines[1:]


def get_function_name(name):
    return name.split('/')[-1]

def get_dataset_size(name):
    return int(name.split('/')[0].split(' ')[-1])

def clean_up_measurements(df):
    df['Size'] = df.Name.apply(get_dataset_size)
    df['Name'] = df.Name.apply(get_function_name)

    return df.groupby(['Name', 'Size']).mean()

def task_A_plots(cpu, ram):
    edf, _ = cpu
    if edf is not None:
        # DIST_NAIF
        p1 = edf.drop(['dist_1', 'dist_2']).unstack(level=0).plot(y='Mean', yerr='Stddev', title='DIST NAIF temps CPU')
        p1.set_ylabel('Temps en secondes')
        p1.set_xlabel('Taille de l\'entrée ($\\vert x \\vert$)')
        p1.get_figure().savefig('charts/CPU_DIST_NAIF.png')
    
    edf, _ = ram
    if edf is not None:
        p2 = edf.drop(['dist_1', 'dist_2']).unstack(level=0).plot(y='Mean')
        p2.set_ylabel('Mémoire maximum consommée en octets')
        p2.set_xlabel('Taille de l\'entrée ($\\vert x \\vert$)')
        p2[0].get_figure().savefig('charts/RAM_DIST_NAIF.png')


def task_B_plots(cpu, ram):
    edf, adf = cpu
    if edf is not None and edf is not None:
        # SOL_1 and DIST_1 on the same plot.
        p1 = pd.concat([edf.drop(['dist_naif', 'dist_2']), adf.drop('sol_2')]).unstack(level=0).plot(y='Mean', yerr='Stddev', logy=True, logx=True, title='SOL_1 et DIST_1 temps CPU')
        p1.set_ylabel('Temps en secondes')
        p1.set_xlabel('Taille de l\'entrée ($\\vert x \\vert$)')
        p1.get_figure().savefig('charts/CPU_SOL_1_AND_DIST_1.png')

    _, adf = ram
    if adf is not None:
        p2 = adf.drop('sol_2').unstack(level=0).plot(y='Mean')
        p2.set_ylabel('Mémoire maximum consommée en octets')
        p2.set_xlabel('Taille de l\'entrée ($\\vert x \\vert$)')
        p2[0].get_figure().savefig('charts/RAM_PROG_DYN.png')

def task_C_plots(cpu, ram):
    edf, _ = cpu

    if edf is not None:
        # DIST_1 and DIST_2
        p1 = edf.drop('dist_naif').unstack(level=0).plot(y='Mean', yerr='Stddev', logy=True, logx=True, title='DIST_1 et DIST_2 temps CPU')
        p1.set_ylabel('Temps en secondes')
        p1.set_xlabel('Taille de l\'entrée ($\\vert x \\vert$)')
        p1.get_figure().savefig('charts/CPU_DIST_1_vs_DIST_2.png')
    
    edf, _ = ram
    if edf is not None:
        # DIST_1 and DIST_2
        p2 = edf.drop('dist_naif').unstack(level=0).plot(y='Mean')
        p2.set_ylabel('Mémoire maximum consommée en octets')
        p2.set_xlabel('Taille de l\'entrée ($\\vert x \\vert$)')
        p2[0].get_figure().savefig('charts/RAM_DIST_1_vs_DIST_2.png')

def task_D_plots(cpu, ram):
    _, adf = cpu
    if adf is not None:
        # SOL_2
        p1 = adf.drop('sol_1').unstack(level=0).plot(y='Mean', yerr='Stddev', logy=True, logx=True, title='SOL_2 temps CPU')
        p1.set_ylabel('Temps en secondes')
        p1.set_xlabel('Taille de l\'entrée ($\\vert x \\vert$)')
        p1.get_figure().savefig('charts/CPU_SOL_2.png')
    
    _, adf = ram
    if adf is not None:
        p2 = adf.drop('sol_1').unstack(level=0).plot(y='Mean')
        p2.set_ylabel('Mémoire maximum consommée en octets')
        p2.set_xlabel('Taille de l\'entrée ($\\vert x \\vert$)')
        p2[0].get_figure().savefig('charts/RAM_SOL_2.png')

def comparison_plots(cpu, ram):
    edf, adf = cpu
    
    if edf is not None:
        p1 = edf.unstack(level=0).plot(y='Mean', yerr='Stddev', logy=True, logx=True, title='Distance d\'édition temps CPU')
        p1.set_ylabel('Temps en secondes')
        p1.set_xlabel('Taille de l\'entrée ($\\vert x \\vert$)')
        p1.get_figure().savefig('charts/CPU_EDF.png')
    if adf is not None:
        p2 = adf.unstack(level=0).plot(y='Mean', yerr='Stddev', logy=True, logx=True, title='Alignement optimaux temps CPU')
        p2.set_ylabel('Temps en secondes')
        p2.set_xlabel('Taille de l\'entrée ($\\vert x \\vert$)')
        p2.get_figure().savefig('charts/CPU_ADF.png')

def main():
    try:
        cedf = clean_up_measurements(pd.read_csv("./cpu_distance_edition.csv"))
    except:
        cedf = None

    try:
        cadf = clean_up_measurements(pd.read_csv("./cpu_alignement.csv"))
    except:
        cadf = None

    cpu = (cedf, cadf)
    
    try:
        ram_df = process_markdown_ram_file(get_markdown('./ram_benchmark_rts.md'))
        ram = (ram_df.drop(['sol_2', 'prog_dyn']), ram_df.drop(['dist_1', 'dist_2']))
    except Exception as e:
        print('ram:', e)
        ram = (None, None)
        raise e

    task_A_plots(cpu, ram)
    task_B_plots(cpu, ram)
    task_C_plots(cpu, ram)
    task_D_plots(cpu, ram)

    comparison_plots(cpu, ram)

if __name__ == '__main__':
    main()
