# Packaging script to build python-dataviz course
# Should be run after changing any *.ipynb files
# Tested on MacOS only
OUTPUT_DIR=~/Downloads/
PACKAGE_DIR=~/Downloads/python_dataviz
SOLUTIONS_DIR=~/Downloads/python_dataviz_solutions
mkdir -p $PACKAGE_DIR/images/python_dataviz
mkdir -p $PACKAGE_DIR/data
mkdir -p $PACKAGE_DIR/output
mkdir -p $SOLUTIONS_DIR
cp -R images/python_dataviz/* $PACKAGE_DIR/images/python_dataviz/
cp -R code/python_dataviz/data/* $PACKAGE_DIR/data
rm -R $PACKAGE_DIR/data/.ipynb_checkpoints $PACKAGE_DIR/data/*/.ipynb_checkpoints
# Clear output from cells before packaging
jupyter-nbconvert --ClearOutputPreprocessor.enabled=True --inplace code/python_dataviz/[0-9]*.ipynb
jupyter-nbconvert --to markdown  code/python_dataviz/[0-9]*.ipynb --output-dir python-dataviz-output/ --execute
# matplotlib figures end up with a title 'png'. Remove it with sed
sed -i '' 's/\[png\]/\[\]/g' python-dataviz-output/*.md
# image paths need to be set relative to the folder. Replace it with sed
sed -i '' -E 's/\((.+_files)/\(python-dataviz-output\/\1/g' python-dataviz-output/*.md
cp code/python_dataviz/*.ipynb $PACKAGE_DIR/
cp code/python_dataviz/solutions/*.ipynb $SOLUTIONS_DIR/
