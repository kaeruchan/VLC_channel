python plot2d_result.py --loop 500000 --ps 1
for strategy in 'broadcast' 'selection' 'intelligent'
do
    python plot2d_result_opt.py --loop 500000 --ps 1 -s $strategy
done