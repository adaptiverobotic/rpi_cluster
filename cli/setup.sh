set -e

# Change working directory to that of this script
cd "$( dirname "${BASH_SOURCE[0]}" )"

#-------------------------------------------------------------------------------

declare_variables() {
  readonly src_dir="code/src"
}

#-------------------------------------------------------------------------------

# Builds all c files
# in src directory.
# NOTE - This is a temporary
# function until we implement
# some sort of Makefile
build_src() {
  local to_build=$(ls $src_dir)

  mkdir -p bin

  # Compile each file individually
  for filename in $to_build;
  do
    echo "Compiling: $filename"

    # If one file fails, delete all of them. The build is a fail
    if ! gcc -o bin/"${filename%.*}.o" $src_dir/"$filename" -lm; then
      echo "Failed to compile $filename"
      echo "Deleting all src"
      rm -f bin/*
    fi
    echo ""
  done
}

#-------------------------------------------------------------------------------

# TODO - Use Makefile, currently
# just makes sure things are executable
build_sh() {
  # Make sure every script is
  # runnable with ./script_name.sh syntax
  # That way the appropriate shell
  # (bash, sh, expect) is run for a given script

  # TODO - Make sure curl is installed
  # TODO - Make sure sshpass is installed
  # TODO - Might be work packaging the cli.sh
  # with dpkg so we can allow apt-get to
  # manage dependency managment

  sudo apt-get install curl sshpass -y

  chmod +x **/*.sh
}

#-------------------------------------------------------------------------------

 main() {
   declare_variables "$@"
   "$@"
 }

 main "$@"
