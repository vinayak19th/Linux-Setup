#!/bin/zsh 
#Clearn-Up

if [ -e envs.txt ]; then
    rm envs.txt
fi

eval "$(conda shell.bash hook)"
conda env list >> envs.txt
sed -i -e :a -e '/^\n*$/{$d;N;};/\n$/ba' envs.txt

tail -n +3 envs.txt | while read -r line; do
    CURR_ENV=$(echo $line | awk '{print $1}')
    echo "Exporting $CURR_ENV"
    conda activate $CURR_ENV
    conda list  > "ENV_$CURR_ENV.txt"
done 
