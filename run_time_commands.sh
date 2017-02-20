#!/bin/bash 
python run.py --project-path ../drone-improvement-approach/dataset/ 

python run.py --project-path ../drone-improvement-approach/dataset/ --min-num-features 8000 --start-with odm_georeferencing --end-with odm_orthophoto --orthophoto-resolution 34 --use-opensfm-pointcloud --verbose --time


