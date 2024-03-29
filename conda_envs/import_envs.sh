eval "$(conda shell.bash hook)"

ls | grep "ENV*" | cut -c 5- | while read -r txt_file ; do
    CURR_ENV=${txt_file%.txt}
    echo "File: $txt_file | Env: $CURR_ENV"
    conda env create -f ENV_$txt_file
    # conda create --name $CURR_ENV --file ENV_$txt_file 
done