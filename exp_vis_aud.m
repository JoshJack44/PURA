function exp_vis_aud(subid, degOffset)


%% paths

% define paths ***********
paths.main = fullfile('/Users', 'wpark78', 'Documents', 'code');
paths.tool = fullfile(paths.main, 'tools');
paths.project = fullfile(paths.main, 'PURA');
paths.VCC = fullfile(paths.tool, 'VCCToolbox');
paths.UWstim = fullfile(paths.tool, 'UWToolbox', 'UWToolbox', 'stimulus');
paths.audstim = fullfile(paths.tool, 'aud-stim-generator');
paths.result = fullfile(paths.project, 'results_main');

% create path if needed
if ~exist(paths.result, 'dir')
    mkdir(paths.result);
    fprintf('Created new folder: %s\n', paths.result);
else
    fprintf('Folder already exists: %s\n', paths.result);
end

% addpath
addpath(paths.VCC);
addpath(paths.UWstim);
addpath(paths.audstim);

%% basic settings

PsychDefaultSetup(2);
Screen('Preference', 'SkipSyncTests', 1);
% ListenChar(2);
InitializePsychSound;
commandwindow;
seed = sum(100 * clock);
rand('seed', seed);

%% audio settings

Fs = 44100; 
nrchannels = 2; 
pahandle = PsychPortAudio('Open', [], [], 0, Fs, nrchannels);

%% screen settings

display.dist = 57; % cm *********** distance b/w participant and monitor
display.width = 53.9; % cm ***********
display.debug = 0;
display.screen = max(Screen('Screens')); 
% display.screen = 1; 

display = OpenWindow(display);
Screen('BlendFunction', display.windowPtr,'GL_SRC_ALPHA','GL_ONE_MINUS_SRC_ALPHA');

cx = display.center(1);
cy = display.center(2);
display.pixPerDeg = angle2pix(display,1); 

display.white = WhiteIndex(display.windowPtr);
display.black = BlackIndex(display.windowPtr);
display.gray = white/2;
display.bkColor = [1, 1, 1] * display.black;
display.fixation.size = 0.3; % deg
display.fixation.color = {[255 0 0], [0,0,0]}; % outer, inner

text.size = 40;
text.color = white;
Screen('TextSize',display.windowPtr,text.size);

%% stimulus settings 

% flash rate
stim.rate = 5; % Hz 
stim.expansionframes = 3; % number of frames devoted to expansion

% timing
stim.dur.fixation = 0.5; 
stim.dur.fractalFlash = 1; % flash
stim.dur.expansion = 1/stim.rate * stim.expansionframes; 
stim.dur.wait = 0.4; % post-stimulus wait (0 to skip)

stim.expansionfactor = 1.5; % expansion factor
stim.dotSize = 1; % deg
stim.baseRect = [0 0 display.resolution];
stim.baseSize = max(display.resolution);

stim.eccentricity = 10; % deg for sound probe ***********
stim.degOffset = degOffset; % deg 

paud.Fs = Fs;
paud.Fc = 400; % Hz
paud.phi = 0; % phase
paud.dur = .07; % sec
paud.RiseFallDur = .005; % sec
paud.orbital = 1;
paud.silence = .03; 
paud.itd = 1;
paud.ild = 1;
paud.doppler = 0;
paud.inverseSquareLaw = 1;

%% conditions 

n_trials_per_cond = 20; % *********** 20

% labels 
labels.fractal     = {'expand','contract','neutral'};
labels.hemifields  = {'left','right'};
labels.soundOrders = {'LR','RL'};     % first burst location -> second
labels.gaze        = {'at', 'away'};

% conditions
fractalConditions  = 1:length(labels.fractal);
hemifields         = 1:length(labels.hemifields);
soundOrders        = 1:length(labels.soundOrders);
gaze               = 1:length(labels.gaze);

% emat
condMat = expmat(fractalConditions, hemifields, soundOrders, gaze); 
[block, ~] = size(condMat); 
condMat = repmat(condMat, n_trials_per_cond, 1); 
[n_trials, ~] = size(condMat);

% randomized sequence with balancing within each original block
[seq, ~] = randseq(condMat, block);

%% instructions

ShowInstructions(display.windowPtr, display.white, display.black, cx, cy);

%% trial

% results columns:
% 1 Trial, 2 VisualManip, 3 Hemifield, 4 AudioOrder, 5 Gaze, 6 Response, 7 RT(s)
results = cell(n_trials, 7);
breakdur = 30; % sec
trialsperblock = n_trials/4; 
try
    for k = 1:numel(seq)

        trialIdx   = seq(k);
        cond       = condMat(trialIdx, :);
        fractalLab = labels.fractal{cond(1)};
        hemiLab    = labels.hemifields{cond(2)};
        orderLab   = labels.soundOrders{cond(3)};
        gazeLab    = labels.gaze{cond(4)};
        
        fprintf('Trial %d / %d: Visual=%s, Hemi=%s, Audio=%s, Gaze=%s\n', ...
            k, numel(seq), fractalLab, hemiLab, orderLab, gazeLab);
        resp = SingleTrial(display, pahandle, stim, paud, fractalLab, hemiLab, orderLab, gazeLab);
        
        results{k,1} = k;
        results{k,2} = fractalLab;
        results{k,3} = hemiLab;
        results{k,4} = orderLab;
        results{k,5} = gazeLab;
        results{k,6} = resp.response;
        results{k,7} = resp.RT;

        % break
        if rem(k,trialsperblock)==0 && k~=n_trials
            Screen('FillRect', display.windowPtr, display.black);
            DrawFormattedText(display.windowPtr, 'Break!', 'center', 'center', display.white, 70);
            Screen('Flip', display.windowPtr);
            WaitSecs(breakdur);
            Screen('FillRect', display.windowPtr, display.black);
            DrawFormattedText(display.windowPtr, 'Press any key to begin', 'center', 'center', display.white, 70);
            Screen('Flip', display.windowPtr);
            KbStrokeWait;
            Screen('FillRect', display.windowPtr, display.black);
            Screen('Flip', display.windowPtr);
        end

    end
    
    % save filename and path
    ts = datestr(now,'yyyymmdd_HHMMSS');
    fname = sprintf([subid, '_visaud_results_%s'], ts);
    savename = fullfile(paths.result, fname);

    % save
    saveResultsCSV(results, [savename, '.csv']);
    save([savename, '.mat'], 'condMat', 'display', 'stim', 'paud', 'seed', 'labels', 'paths');

    % plot
    plotAccuracy(savename);

catch ME
    fprintf('\nExperiment terminated early: %s\nSaving partial results...\n', ME.message);
    saveResultsCSV(results, savename);
    PsychPortAudio('Close', pahandle);
    sca;
    ListenChar(1);
    rethrow(ME)
end

sca;
PsychPortAudio('Close', pahandle);
ListenChar(1);

end