clc; clear; close all;

%% Folder setup
baseFolder = fullfile('/MATLAB Drive');

dampingFolders = {'Damping 0', 'Damping 0.5', 'Damping 1', 'Damping 1.5'};
legendLabels = { ...
    '0 A (\zeta \approx 0.003, log dec)', ...
    '0.5 A (\zeta \approx 0.037, log dec)', ...
    '1.0 A (\zeta \approx 0.116, log dec)', ...
    '1.5 A (\zeta \approx 0.26, log dec)'};

% Natural frequency
fn = 1.65;   % Hz

allResults = [];

%% Loop through each damping folder
for d = 1:length(dampingFolders)

    folder = fullfile(baseFolder, dampingFolders{d});
    files = dir(fullfile(folder, 'scope_*.csv'));

    results = [];

    fprintf('\n===== %s =====\n', dampingFolders{d});

    %% Create one figure per damping case for time signals
    figure('Name', ['Signals - ', dampingFolders{d}], ...
           'NumberTitle', 'off');

    numFiles = length(files);
    rows = ceil(sqrt(numFiles));
    cols = ceil(numFiles / rows);

    %% Loop through each CSV file
    for k = 1:length(files)

        filename = fullfile(folder, files(k).name);

        %% Read CSV
        data = readmatrix(filename, "NumHeaderLines", 2);
        data = rmmissing(data);

        if size(data,2) < 3
            warning('Skipping %s: not enough columns', files(k).name);
            continue;
        end

        t = data(:,1);
        ch1 = data(:,2);   % Excitation / frame input
        ch2 = data(:,3);   % Response / moving mass

        %% Use steady-state section only
        n = length(t);
        idx = round(0.2*n):round(0.8*n);

        t = t(idx);
        ch1 = ch1(idx);
        ch2 = ch2(idx);

        %% Remove DC offset
        ch1 = ch1 - mean(ch1, 'omitnan');
        ch2 = ch2 - mean(ch2, 'omitnan');
        
        
        %% Get frequency from filename
        name = files(k).name;
        token = regexp(name, 'scope_(\d+)', 'tokens');

        if isempty(token)
            warning('Skipping %s: frequency not found in filename', files(k).name);
            continue;
        end

        freqText = token{1}{1};
        num = str2double(freqText);

        if strcmp(freqText, '05')
            f = 0.50;
        else
            f = num / 100;
        end

        %Cross-correlation co-efficient check
        rawCorr = corr(ch1, ch2, 'Rows', 'complete');
        correctedCorr = corr(ch1, -ch2, 'Rows', 'complete');

        fprintf('f = %.2f Hz, raw corr = %.3f, corrected corr = %.3f\n', ...
            f, rawCorr, correctedCorr);

        %% Frequency ratio
        r = f / fn;

        %% Sampling frequency
        Fs = 1 / mean(diff(t));

        %% Cross-correlation phase extraction
        [c, lags] = xcorr(ch1, ch2, 'coeff');

        lagTimes = lags / Fs;
        T = 1 / f;

        % Only allow response lag between 0 and 180 degrees
        valid = lagTimes >= 0 & lagTimes <= T/2;

        c_valid = c(valid);
        lagTimes_valid = lagTimes(valid);

        if isempty(c_valid)
            warning('Skipping %s: no valid lag range found', files(k).name);
            continue;
        end

        [~, idxMax] = max(c_valid);
        timeDelay = lagTimes_valid(idxMax);

        %% Convert time delay to phase angle
        phase_deg = 180 - (360 * f * timeDelay);

        % Keep within physical 0 to 180 degree range
        phase_deg = max(0, min(180, phase_deg));

        %% Store results
        results = [results; f, r, phase_deg, timeDelay];
        allResults = [allResults; d, f, r, phase_deg, timeDelay];

        %% Plot signal as subplot inside damping figure
        subplot(rows, cols, k)

        plot(t, ch1, 'LineWidth', 1.0); hold on;
        plot(t, ch2, 'LineWidth', 1.0);

        grid on;
        xlabel('Time (s)');
        ylabel('Voltage');

        title(sprintf('f = %.2f Hz, r = %.2f, phase = %.1f°', ...
              f, r, phase_deg), 'FontSize', 8);

        legend('CH1', 'CH2', ...
               'FontSize', 6, ...
               'Location', 'best');

    end

    %% Sort results for this damping case by frequency
    results = sortrows(results, 1);

    %% Display table
    resultsTable = array2table(results, ...
        'VariableNames', ...
        {'Frequency_Hz', 'Frequency_Ratio', 'Phase_deg', 'TimeDelay_s'});

    disp(resultsTable);

    %% Plot phase angle for this damping case
    figure('Name', ['Phase - ', dampingFolders{d}], ...
           'NumberTitle', 'off');

    plot(results(:,2), results(:,3), 'o-', 'LineWidth', 1.5);

    grid on;
    xlabel('Frequency Ratio r = f / f_n');
    ylabel('Phase Angle (degrees)');
    ylim([0 180]);
    xlim([0 3]);

    title(['Phase Angle vs Frequency Ratio - ', dampingFolders{d}]);

end

%% Combined results table
allResults = sortrows(allResults, [1 2]);

allResultsTable = array2table(allResults, ...
    'VariableNames', ...
    {'DampingFolderIndex', 'Frequency_Hz', ...
     'Frequency_Ratio', 'Phase_deg', 'TimeDelay_s'});

disp('===== ALL RESULTS =====');
disp(allResultsTable);

%% Combined comparison plot
figure('Name', 'Combined Phase Comparison', ...
       'NumberTitle', 'off');

hold on; grid on;

for d = 1:length(dampingFolders)

    idx = allResults(:,1) == d;
    temp = allResults(idx, :);
    temp = sortrows(temp, 2);

    plot(temp(:,3), temp(:,4), 'o-', 'LineWidth', 1.5, ...
        'DisplayName', legendLabels{d});

end

xlabel('Frequency Ratio r = f / f_n');
ylabel('Phase Angle (degrees)');
ylim([0 180]);
xlim([0 3]);

title('Experimental Phase Angle vs Frequency Ratio for All Damping Cases');
legend('Location', 'best');