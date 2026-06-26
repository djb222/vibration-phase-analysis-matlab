clc; clear; close all;

% Folder setup
baseFolder = fullfile('/MATLAB Drive');

dampingFolders = {'Damping 0', 'Damping 0.5', 'Damping 1', 'Damping 1.5'};
legendLabels = { ...
    '0 A (\zeta \approx 0.003, log dec)', ...
    '0.5 A (\zeta \approx 0.037, log dec)', ...
    '1.0 A (\zeta \approx 0.116, log dec)', ...
    '1.5 A (\zeta \approx 0.26, log dec)'};

fn = 1.65;   % Hz

invertCH2 = true;        % fixed polarity correction used for physical phase convention

cyclesToShow = 10;        % number of cycles shown in signal plots

allResults = [];

% Loop through damping folders
for d = 1:length(dampingFolders)

    folder = fullfile(baseFolder, dampingFolders{d});
    files = dir(fullfile(folder, 'scope_*.csv'));

    % Sort files by frequency
    fileFreqs = zeros(length(files),1);

    for k = 1:length(files)
        token = regexp(files(k).name, 'scope_(\d+)', 'tokens');

        if isempty(token)
            fileFreqs(k) = NaN;
        else
            freqText = token{1}{1};
            num = str2double(freqText);

            if strcmp(freqText, '05')
                fileFreqs(k) = 0.50;
            else
                fileFreqs(k) = num / 100;
            end
        end
    end

    [~, sortIdx] = sort(fileFreqs);
    files = files(sortIdx);
    fileFreqs = fileFreqs(sortIdx);

    results = [];

    fprintf('\n===== %s =====\n', dampingFolders{d});

    % Figures
    figRaw = figure('Name', ['RAW Signals - ', dampingFolders{d}], ...
        'NumberTitle', 'off');

    figCorr = figure('Name', ['Polarity-corrected & Normalised Signals - ', dampingFolders{d}], ...
        'NumberTitle', 'off');

    numFiles = length(files);
    rows = ceil(sqrt(numFiles));
    cols = ceil(numFiles / rows);

    % Loop CSV files
    for k = 1:length(files)

        filename = fullfile(folder, files(k).name);

        data = readmatrix(filename, "NumHeaderLines", 2);
        data = rmmissing(data);

        if size(data,2) < 3
            warning('Skipping %s: not enough columns', files(k).name);
            continue;
        end

        t_raw   = data(:,1);   % raw time from csv
        ch1_raw = data(:,2);   % CH1 = excitation
        ch2_raw = data(:,3);   % CH2 = response

        f = fileFreqs(k);

        if isnan(f)
            warning('Skipping %s: frequency not found in filename', files(k).name);
            continue;
        end

        r = f / fn;

        % Steady-state section
        n = length(t_raw);
        idx = round(0.2*n):round(0.8*n);

        t   = t_raw(idx);
        ch1 = ch1_raw(idx);
        ch2 = ch2_raw(idx); % cropping first and last 20% to remove transient
   
        % remove DC Offset
        ch1 = ch1 - mean(ch1, 'omitnan');
        ch2 = ch2 - mean(ch2, 'omitnan');
        

        % Raw phase: original CH2
        phase_rawSignal = getPhaseFRF(t, ch1, ch2, f);

        % Corrected signal and corrected phase
        ch2_corr = ch2;

        if invertCH2
            ch2_corr = -ch2_corr;
        end

        phase_corrected = getPhaseFRF(t, ch1, ch2_corr, f);

        % Store results
        results = [results; f, r, phase_rawSignal, phase_corrected];

        allResults = [allResults; ...
            d, f, r, phase_rawSignal, phase_corrected];

        % Crop for visual clarity
        T = 1/f;
        windowLength = cyclesToShow * T;
        tMid = mean(t);

        plotIdx = (t >= tMid - windowLength/2) & ...
                  (t <= tMid + windowLength/2);

        tPlot = t(plotIdx);

        ch1PlotRaw = ch1(plotIdx);
        ch2PlotRaw = ch2(plotIdx);

        ch1PlotCorr = ch1(plotIdx);
        ch2PlotCorr = ch2_corr(plotIdx);

        
        % Measured = original oscilloscope voltages
        % Processed = polarity-corrected and normalised
        % for clearer visual phase comparison only
        

        % Raw signals stay in volts
        yLabelRaw = 'Voltage (V)';

        % Processed signals are normalised
        ch1PlotCorr = ch1PlotCorr ./ max(abs(ch1PlotCorr));
        ch2PlotCorr = ch2PlotCorr ./ max(abs(ch2PlotCorr));

        yLabelCorr = 'Normalised amplitude';

        % Raw data plot
        figure(figRaw);
        subplot(rows, cols, k)

        plot(tPlot, ch1PlotRaw, 'LineWidth', 1.0); hold on;
        plot(tPlot, ch2PlotRaw, 'LineWidth', 1.0);

        grid on;
        xlabel('Time (s)');
        ylabel(yLabelRaw);

        title(sprintf('MEAS: f = %.2f Hz, r = %.2f, phase = %.1f°', ...
            f, r, phase_rawSignal), 'FontSize', 8);

        legend('CH1 frame excitation', ...
       'CH2 measured response', ...
            'FontSize', 6, 'Location', 'best');

        % Processed plot
        figure(figCorr);
        subplot(rows, cols, k)

        plot(tPlot, ch1PlotCorr, 'LineWidth', 1.0); hold on;
        plot(tPlot, ch2PlotCorr, 'LineWidth', 1.0);

        grid on;
        xlabel('Time (s)');
        ylabel(yLabelCorr);

        title(sprintf('PROC: f = %.2f Hz, r = %.2f, phase = %.1f°', ...
            f, r, phase_corrected), 'FontSize', 8);

        legend('CH1 frame excitation', ...
       'CH2 polarity-corrected response', ...
            'FontSize', 6, 'Location', 'best');

    end

    % Sort and display table
    results = sortrows(results, 1);

    resultsTable = array2table(results, ...
        'VariableNames', ...
        {'Frequency_Hz', 'Frequency_Ratio', ...
         'Raw_Phase_deg', 'Corrected_Phase_deg'});

    disp(resultsTable);

    % Individual raw vs normalised phase plot
    figure('Name', ...
    ['Measured vs Processed Phase - ', dampingFolders{d}], ...
        'NumberTitle', 'off');

    plot(results(:,2), results(:,3), 'o--', 'LineWidth', 1.2); hold on;
    plot(results(:,2), results(:,4), 'o-',  'LineWidth', 1.5);

    grid on;
    xlabel('Frequency Ratio r = f / f_n');
    ylabel('Phase Angle (degrees)');
    ylim([0 180]);
    xlim([0 3]);

    legend('Measured phase', ...
       'Processed phase', ...
       'Location', 'best');
    title(['Measured vs Processed FFT/FRF Phase - ', dampingFolders{d}]);

end

% Combined results table
allResults = sortrows(allResults, [1 2]);

allResultsTable = array2table(allResults, ...
    'VariableNames', ...
    {'DampingFolderIndex', 'Frequency_Hz', 'Frequency_Ratio', ...
     'Raw_Phase_deg', 'Corrected_Phase_deg'});

disp('===== ALL RESULTS =====');
disp(allResultsTable);

% Combined corrected phase plot
figure('Name', 'Combined Processed FFT/FRF Phase Comparison', ...
    'NumberTitle', 'off');

hold on; grid on;

for d = 1:length(dampingFolders)

    idx = allResults(:,1) == d;
    temp = allResults(idx, :);
    temp = sortrows(temp, 2);

    plot(temp(:,3), temp(:,5), 'o-', 'LineWidth', 1.5, ...
        'DisplayName', legendLabels{d});

end

xlabel('Frequency Ratio r = f / f_n');
ylabel('Processed Phase Angle (degrees)');
ylim([0 180]);
xlim([0 3]);
title('Corrected Experimental FFT/FRF Phase Angle vs Frequency Ratio');
legend('Location', 'best');

% Combined raw phase plot
figure('Name', 'Combined Raw FFT/FRF Phase Comparison', ...
    'NumberTitle', 'off');

hold on; grid on;

for d = 1:length(dampingFolders)

    idx = allResults(:,1) == d;
    temp = allResults(idx, :);
    temp = sortrows(temp, 2);

    plot(temp(:,3), temp(:,4), 'o--', 'LineWidth', 1.5, ...
        'DisplayName', legendLabels{d});

end

xlabel('Frequency Ratio r = f / f_n');
ylabel('Raw Phase Angle (degrees)');
ylim([0 180]);
xlim([0 3]);
title('Raw Experimental FFT/FRF Phase Angle vs Frequency Ratio');
legend('Location', 'best');


% Local function: FFT/FRF phase extraction

function phase_deg = getPhaseFRF(t, ch1, ch2, f)

    dt = mean(diff(t));
    Fs = 1 / dt;
    N  = length(t);

    w = hann(N);

    CH1 = fft(ch1 .* w);
    CH2 = fft(ch2 .* w);

    freqAxis = (0:N-1) * (Fs / N);

    [~, freqIdx] = min(abs(freqAxis - f));

    % FRF = output / input
    H = CH2(freqIdx) / CH1(freqIdx);

    phase_raw = rad2deg(angle(H));

    % response lag convention
    phase_deg = mod(-phase_raw, 360);

    % 0–180 SDOF convention
    if phase_deg > 180
        phase_deg = 360 - phase_deg;
    end

end