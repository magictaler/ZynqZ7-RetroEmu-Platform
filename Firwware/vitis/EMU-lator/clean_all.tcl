#*****************************************************************************************
# This script will delete all automatically generated files that were created by the
# following scripts:
# create_project_file.tcl
# create_sdk_files.tcl
#*****************************************************************************************

# Set the reference directory for source file relative paths (by default the value is script directory path)
set origin_dir "[file normalize "."]"

#
# Deletes files given files or do nothing if list is empty
# file_list: List of files to delete
#
proc file_delete_if_exists {file_list} {
    if {[string length $file_list] > 0} {
        eval file delete -force $file_list
    }
}

puts -nonewline "THIS WILL REMOVE ALL GENERATED FILES ARE YOU SURE YOU WANT TO DO THIS (Y/N): "
flush stdout
set response [gets stdin]

if {[string toupper $response] == "Y"} {
    # Select the bootimage directory as workspace to allow more of the project files to be
    # deleted
    #setws bootimage

    file delete -force $origin_dir/.metadata
    file delete -force $origin_dir/.Xil
    file delete -force $origin_dir/.analytics
    file delete -force $origin_dir/IDE.log
    file delete -force $origin_dir/../Packages
    file delete -force $origin_dir/RemoteSystemsTempFiles
    file_delete_if_exists [glob -nocomplain -join -directory $origin_dir/ *_platform]
    file_delete_if_exists [glob -nocomplain -join -directory $origin_dir/ *_system]
    file_delete_if_exists [glob -nocomplain -join -directory $origin_dir/../../build *.bin]

    set folders [glob -type d $origin_dir/*]
    foreach f $folders {
       file_delete_if_exists [glob -nocomplain -join -directory $f Release]
       file_delete_if_exists [glob -nocomplain -join -directory $f Debug]
       file_delete_if_exists [glob -nocomplain -join -directory $f _ide]
       file delete -force $f/.cproject
       file delete -force $f/.project
       file_delete_if_exists [glob -nocomplain -join -directory $f *.prj]
       file_delete_if_exists [glob -nocomplain -join -directory $f **/*.spec]
       file_delete_if_exists [glob -nocomplain -join -directory $f **/README.txt]
    }
}

