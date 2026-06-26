# Vibration Phase Angle Analysis — MATLAB Signal Processing

## Overview

This repository contains MATLAB scripts used to analyse the phase response of a single-degree-of-freedom vibration rig using experimental oscilloscope data.

The project involved comparing measured phase behaviour against theoretical SDOF vibration response. The analysis used FFT/FRF processing, cross-correlation validation, and analytical modelling to interpret how damping affected the system response across a range of excitation frequencies.

## My Contribution

This was a university group project. My main contribution focused on MATLAB post-processing, phase angle analysis, theoretical modelling, and interpretation of the experimental results.

I contributed to:

- Developing MATLAB scripts to process oscilloscope CSV data.
- Estimating phase angle using FFT/FRF methods.
- Implementing cross-correlation as a time-domain validation method.
- Applying channel polarity correction to match the physical phase convention.
- Building a theoretical SDOF phase response model.
- Comparing experimental phase behaviour against theoretical predictions.
- Interpreting limitations such as resonance nonlinearity, signal noise, damping effects, and measurement constraints.

## Technologies Used

- MATLAB
- FFT
- Frequency response functions
- Cross-correlation
- Signal processing
- Dynamic systems
- Experimental vibration analysis
- Data visualisation

## Key Files

```text
scripts/
├── PAAWaveforms.m                  # FFT/FRF phase analysis and waveform plotting
├── PhaseAngleCrossCorrelation.m    # Time-domain phase validation using cross-correlation
├── Analytical1DOF.m                # Theoretical SDOF phase response model
└── NominalFFTCheck.m               # Frequency checking and FFT validation
