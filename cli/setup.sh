set -e

#-------------------------------------------------------------------------------

declare_variables() {
  readonly src_dir="src"
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
    if ! gcc -o bin/"${filename%.*}.o" $src_dir/"$filename"; then
      echo "Failed to compile $filename"
      echo "Deleting all src"
      rm -f bin/*
    fi
    echo ""
  done
}

#-------------------------------------------------------------------------------

 main() {
   declare_variables "$@"
   "$@"
 }

 main "$@"
