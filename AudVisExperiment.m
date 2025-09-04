function CombinedAudVisDemo()

Fs              = 44100;          % audio sampling rate
freqPureTone    = 400;            % Hz
toneDur         = 0.30;           % seconds per tone burst
silenceDur      = 0.10;           % gap between bursts (s)

% Visual timing (seconds)
durations.fixation    = 1;        % red phase
durations.fractalFlash= 5;        % red+flash after fixation
durations.yellowCue   = 2;        % yellow + purple target
durations.greenCue    = 2;        % green + animation + audio
durations.wait        = 0;        % post-green wait (0 to skip)
rate            = 5;            
dotSize         = 15;             
expansionDuration  = durations.greenCue;  
expansionIntensity = 1.5;                 % 1=no zoom; >1 zoom in
purpleDegOffset     = 8;          % degrees visual angle from center
purpleDotRGB        = [128 0 128];
p.Fs  = Fs; p.a = 0.0875; p.k  = 10; p.d0 = 1; p.c  = 345;
p.doppler = 0; p.itd = 1; p.ild = 1; p.inverseSquareLaw = 0;
labels.fractal     = {'expand','contract','neutral'};
labels.hemifields  = {'left','right'};
labels.soundOrders = {'LR','RL'};     % first burst location -> second
fractalConditions  = 1:3;
hemifields         = 1:2;
soundOrders        = 1:2;

n_trials_per_cond  = 3;

%       CONDITION MATRIX
condMat = expmat(fractalConditions, hemifields, soundOrders);  
[block,~] = size(condMat);
condMat   = repmat(condMat, n_trials_per_cond, 1);             
[n_trials, ~] = size(condMat);

% Randomized sequence with balancing within each original block
[seq, ~] = randseq(condMat, block);

%     PSYCHTOOLBOX SETUP
Screen('Preference','SkipSyncTests',1); 
sca;
PsychDefaultSetup(2);

screenNumber = max(Screen('Screens'));
[win, winRect] = PsychImaging('OpenWindow', screenNumber, 0);
HideCursor;
[white, black] = deal(WhiteIndex(win), BlackIndex(win));
[xCenter, yCenter] = RectCenter(winRect);
baseRect = winRect;

% Full-screen pink noise texture size
baseSizeX = winRect(3);
baseSizeY = winRect(4);
baseSize  = max(baseSizeX, baseSizeY);

% Store core params
params = struct();
params.win         = win;
params.white       = white;
params.black       = black;
params.rate        = rate;
params.dotSize     = dotSize;
params.durations   = durations;
params.baseSize    = baseSize;
params.baseRect    = baseRect;
params.p           = p;
params.Fs          = Fs;
params.toneDur     = toneDur;
params.silenceDur  = silenceDur;
params.expansionDuration  = expansionDuration;
params.expansionIntensity = expansionIntensity;

% Physical display settings
display = struct();
display.width = 30.2;   
display.dist  = 75;      
res = Screen('Resolution', screenNumber);
display.resolution = [res.width, res.height];
display.pix = angle2pix(display, 1);      
display.centerDot = [xCenter, yCenter];
display.baseRect  = baseRect;

numFlashFrames = max(1, round(durations.fractalFlash*rate));
fractalTexturesFlash = cell(1, numFlashFrames);
for i = 1:numFlashFrames
    pink = GeneratePinkNoise(baseSize);               
    fractalTexturesFlash{i} = Screen('MakeTexture', win, pink);
end
params.fractalTexturesFlash = fractalTexturesFlash;

%          AUDIO SETUP
InitializePsychSound(1);  % 1 = try for low latency

t     = linspace(0, toneDur, round(Fs*toneDur))';
tone  = sin(2*pi*freqPureTone*t);
rampN = round(Fs*0.02);
env   = ones(size(tone));
env(1:rampN) = linspace(0,1,rampN);
env(end-rampN+1:end) = linspace(1,0,rampN);
tone  = 0.8 * (tone .* env);  
pureToneStereo = [tone tone];  
params.pureToneStereo = pureToneStereo;

devices = PsychPortAudio('GetDevices');
deviceID = [];
for i = 1:numel(devices)
    if devices(i).NrOutputChannels >= 2
        deviceID = devices(i).DeviceIndex;
        break;
    end
end
if isempty(deviceID)
    sca; error('No suitable audio output device found.');
end

pahandle = PsychPortAudio('Open', deviceID, 1, 1, Fs, 2, [], [], [], 0);
params.pahandle = pahandle;

% INSTRUCTIONS
ShowInstructions(win, white, black, xCenter, yCenter);

%         TRIAL LOOP
% results columns:
% 1 Trial, 2 VisualManip, 3 Hemifield, 4 AudioOrder, 5 Response, 6 RT(s)
results = cell(n_trials, 6);

try
    for k = 1:numel(seq)
        trialIdx   = seq(k);
        cond       = condMat(trialIdx, :);
        fractalLab = labels.fractal{cond(1)};
        hemiLab    = labels.hemifields{cond(2)};
        orderLab   = labels.soundOrders{cond(3)};

        fprintf('Trial %d / %d: Visual=%s, Hemi=%s, Audio=%s\n', ...
            k, numel(seq), fractalLab, hemiLab, orderLab);
        % Run trial 
        [trialHemifield, trialSoundOrder, resp] = ...
            runSingleTrial(fractalLab, params, display, hemiLab, orderLab);

        results{k,1} = k;
        results{k,2} = fractalLab;
        results{k,3} = trialHemifield;
        results{k,4} = trialSoundOrder;
        results{k,5} = resp.response;
        results{k,6} = resp.RT;
    end
    saveResultsCSV(results);

catch ME
    fprintf('\nExperiment terminated early: %s\nSaving partial results...\n', ME.message);
    saveResultsCSV(results);
    PsychPortAudio('Close', pahandle);
    sca;
    rethrow(ME);
end

% Clean close
PsychPortAudio('Close', pahandle);
sca;

end 

% =======================================================================
%                            runSingleTrial
% =======================================================================
function [trialHemifield, trialSoundOrder, resp] = runSingleTrial(fractalCondition, params, display, hemifield, soundOrder)

win         = params.win;
white       = params.white;
black       = params.black;
rate        = params.rate;
dotSize     = params.dotSize;
dur         = params.durations;
baseRect    = params.baseRect;

intensity   = params.expansionIntensity;
durGreen    = params.expansionDuration;

Fs              = params.Fs;
pahandle        = params.pahandle;
pureToneStereo  = params.pureToneStereo;
toneDur         = params.toneDur;
silenceDur      = params.silenceDur;

redFixFrames     = 1 : round(dur.fixation * rate);
fractalFlashFrames = redFixFrames(end)+1 : redFixFrames(end) + round(dur.fractalFlash * rate);
yellowCueFrames  = fractalFlashFrames(end)+1 : fractalFlashFrames(end) + round(dur.yellowCue * rate);
nFramesGreen     = max(1, round(durGreen * rate));
greenCueFrames   = yellowCueFrames(end)+1 : yellowCueFrames(end) + nFramesGreen;
waitFrames       = greenCueFrames(end)+1 : greenCueFrames(end) + round(dur.wait * rate);
if isempty(waitFrames), waitFrames = greenCueFrames(end) : greenCueFrames(end); end
totalFrames      = waitFrames(end);

degOffset   = 8;  
pxOffset    = round(display.pix * degOffset);
cx          = display.centerDot(1);
cy          = display.centerDot(2);
if strcmpi(hemifield, 'left')
    purplePos = [cx - pxOffset, cy];
else
    purplePos = [cx + pxOffset, cy];
end

fractalTexturesFlash = params.fractalTexturesFlash;
basePinkGreenTex = [];     

if strcmpi(fractalCondition, 'neutral')
    fractalTexturesGreen = params.fractalTexturesFlash;
    zoomLevels = [];
else
    if isempty(basePinkGreenTex)
        pink = GeneratePinkNoise(params.baseSize);
        basePinkGreenTex = Screen('MakeTexture', win, pink);
    end
    fractalTexturesGreen = repmat({basePinkGreenTex}, 1, nFramesGreen);
    if strcmpi(fractalCondition, 'expand')
        zoomLevels = linspace(1, intensity, nFramesGreen);
    else
        zoomLevels = linspace(intensity, 1, nFramesGreen);
    end
end

depth_m     = display.dist/100;             
xCenter_m   = depth_m * tand(degOffset);    
offset_m    = 0.10;                         

if strcmpi(soundOrder, 'LR')
    sound1x = xCenter_m - offset_m;
    sound2x = xCenter_m + offset_m;
else
    sound1x = xCenter_m + offset_m;
    sound2x = xCenter_m - offset_m;
end

burst1 = spatializeBurst(pureToneStereo, sound1x, depth_m, Fs);
burst2 = spatializeBurst(pureToneStereo, sound2x, depth_m, Fs);

silence = zeros(round(silenceDur*Fs), 2);
combinedSound = [burst1; silence; burst2];           
PsychPortAudio('FillBuffer', pahandle, combinedSound');

totalAudioDur = size(combinedSound,1) / Fs;

soundPlayed   = false;
soundStartSec = NaN;
promptShown   = false;

flipWhen = Screen('Flip', win);
for frame = 1:totalFrames
    if checkForEscape()
        error('ESC pressed');
    end

    tex = fractalTexturesFlash{mod(frame-1, numel(fractalTexturesFlash))+1};
    srcRect = [];  
    dstRect = baseRect;

    if ismember(frame, greenCueFrames)
        idx = frame - greenCueFrames(1) + 1;
        tex = fractalTexturesGreen{idx};
        if ~strcmpi(fractalCondition, 'neutral')
            [texW, texH] = queryTextureSize(tex);  
            zoom = zoomLevels(idx);   
            cropW = texW / zoom;
            cropH = texH / zoom;
            srcRect = CenterRectOnPoint([0 0 cropW cropH], texW/2, texH/2);
        end
    end

    Screen('DrawTexture', win, tex, srcRect, dstRect);

    if ismember(frame, redFixFrames)
        DrawFixation(win, [], [], display.centerDot, dotSize, [255 0 0]);   
    elseif ismember(frame, yellowCueFrames)
        DrawFixation(win, [], [], display.centerDot, dotSize, [255 255 0]); 
        DrawFixation(win, purplePos, [], [], dotSize, [128 0 128]);         
    elseif ismember(frame, greenCueFrames)
        DrawFixation(win, [], [], display.centerDot, dotSize, [0 255 0]);   
        if frame == greenCueFrames(1)
            DrawFixation(win, purplePos, [], [], dotSize, [128 0 128]);     
        end
    else
        DrawFixation(win, [], [], display.centerDot, dotSize, [255 0 0]);   
    end

    if soundPlayed && ~promptShown && (GetSecs - soundStartSec) >= totalAudioDur
        Screen('FillRect', win, black);
        DrawFormattedText(win, 'Press LEFT or RIGHT arrow key', 'center', 'center', white);
        promptShown = true;  
    elseif promptShown
        Screen('FillRect', win, black);
        DrawFormattedText(win, 'Press LEFT or RIGHT arrow key', 'center', 'center', white);
    end

    flipWhen = Screen('Flip', win, flipWhen + 0.5/rate);

    if frame == greenCueFrames(1) && ~soundPlayed
        PsychPortAudio('Start', pahandle, 1, 0, 1);
        soundStartSec = GetSecs;
        soundPlayed   = true;
    end
end

resp.response = 'none'; resp.RT = NaN;

KbName('UnifyKeyNames');
leftKeys  = [KbName('LeftArrow'),  KbName('l')]; 
rightKeys = [KbName('RightArrow'), KbName('r')];

while true
    if checkForEscape()
        error('ESC pressed');
    end
    [down, ts, kc] = KbCheck;
    if down
        if any(kc(leftKeys))
            resp.response = 'left';
            resp.RT = ts - soundStartSec;
            break;
        elseif any(kc(rightKeys))
            resp.response = 'right';
            resp.RT = ts - soundStartSec;
            break;
        end
    end
end

trialHemifield   = hemifield;
trialSoundOrder  = soundOrder;

end 

% =======================================================================
%                          Helper: queryTextureSize
% =======================================================================
function [w, h] = queryTextureSize(tex)
r = Screen('Rect', tex);  % [0 0 w h]
w = r(3); h = r(4);
end

% =======================================================================
%                      Helper: spatializeBurst (light)
% =======================================================================
function y = spatializeBurst(stereoDry, x_m, depth_m, Fs)
y = stereoDry;
maxILDdB = 3;
scale = max(-1, min(1, x_m / 0.2));
ildL = 10.^((-scale*maxILDdB)/20);
ildR = 10.^(( scale*maxILDdB)/20);
y(:,1) = y(:,1) * ildL;
y(:,2) = y(:,2) * ildR;
maxITD = 0.0006;  
itd = scale * maxITD;  
shiftSamples = round(itd * Fs);

if shiftSamples > 0
    y(:,2) = [zeros(shiftSamples,1); y(1:end-shiftSamples,2)];
elseif shiftSamples < 0
    s = abs(shiftSamples);
    y(:,1) = [zeros(s,1); y(1:end-s,1)];
end

dist = sqrt(x_m.^2 + depth_m.^2);
att  = 1 ./ max(1, dist);  
y = y * att;
end




