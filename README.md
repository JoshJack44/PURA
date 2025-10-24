# Visual Calibration Experiment

This repository contains the MATLAB code for the Visual Calibration experiment, including all helper functions needed to run the task.

## Files

- `exp_aud_threshold.m` – measure threshold first
- `exp_vis_aud.m` – main experiment script (need measured threhsold as input)
- `DrawFixation.m` – helper for drawing fixation dots  
- `GeneratePinkNoise.m` – generates fractal noise textures  
- `ShowInstructions.m` – displays instructions to participants  
- `saveResultsCSV.m` – saves trial data to CSV  
- `angle2pix.m` – converts visual angles to pixels  
- `checkForEscape.m` – checks for escape key press during experiment  
- `randseq.m` – helper for random sequences  
- `expmat.m` – trial matrix template  

## Requirements

- MATLAB (tested on R2022b or later)  gi
- Psychtoolbox installed  
- UW Toolbox
- VCC Toolbox
- Aud Stim Generator 

## How to Run

1. Open MATLAB and set the working directory to this folder.  
2. Run the main experiment script:  

