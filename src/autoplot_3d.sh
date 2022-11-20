

for case in {1..3} 
do
    for user_type in {1..3} 
    do 
        for plot in 'user' 'sec' 
        do
            python plot3d_result.py --case $case --loop 10000 --ps 0.25 --user $user_type -r $plot
        done
    done
done 