function results = ImagingDistortions(stereoMode, usedatapixx, writeMovie, reduceCrossTalkGain)
% ImagingStereoDemo([stereoMode=8][, usedatapixx = 0][, writeMovie = 0][, reduceCrossTalkGain = 0])
%
% Demo on how to use OpenGL-Psychtoolbox to present stereoscopic stimuli
% when the Psychtoolbox imaging pipeline is enabled. Use of the imaging
% pipeline allows for more flexible and high quality stereo display modes,
% but it requires graphics hardware with support for at least framebuffer
% objects and Shadermodel 2.0. Any half-way recent graphics card provides
% those features as part of OpenGL 2.0. See the Psychtoolbox Wiki about
% gfx-hardware recommendations. The demo also shows how to configure the
% pipeline to restrict image processing to some subregion of the display,
% e.g., to save some computation time on low-end hardware.
%
% Press escape key to abort demo, space key to toggle modes of specific
% algorithms.
%
% Optional parameters:
%
% 'stereoMode' specifies the type of stereo display algorithm to use:
%
% 0 == Mono display - No stereo at all.
%
% 1 == Flip frame stereo (temporally interleaved) - You'll need shutter
% glasses that are supported by the operating system, e.g., the
% CrystalEyes-Shutterglasses. Psychtoolbox will automatically generate blue
% sync lines at the bottom of the display.
%
% 2 == Top/bottom image stereo with lefteye=top also for use with special
% CrystalEyes-hardware. Also used by the ViewPixx Inc. DataPixx device for
% frame-sequential stereo with shutter glasses, and with various other products.
%
% 3 == Same, but with lefteye=bottom.
%
% 4 == Free fusion (lefteye=left, righteye=right): Left-eye view displayed
% in left half of window, right-eye view displayed in right-half of window.
% Use this for dual-display setups (binocular video goggles, haploscopes,
% polarized stereo setups etc.)
%
% 5 == Cross fusion (lefteye=right ...): Like mode 4, but with views
% switched.
%
% 6-9 == Different modes of anaglyph stereo for color filter glasses:
%
% 6 == Red-Green
% 7 == Green-Red
% 8 == Red-Blue
% 9 == Blue-Red
%
% If you have a different set of filter glasses, e.g., red-magenta, you can
% simply select one of above modes, then use the
% SetStereoAnglyphParameters() command to change color gain settings,
% thereby implementing other anaglyph color combinations.
%
% 10 == Like mode 4, but for use on Mac OS/X with dualhead display setups.
%
% 11 == Like mode 1 (frame-sequential) but using Screen's built-in method,
% instead of the native method supported by your graphics card.
%
% 100 == Interleaved line stereo: Left eye image is displayed in even
% scanlines, right eye image is displayed in odd scanlines.
%
% 101 == Interleaved column stereo: Left eye image is displayed in even
% columns, right eye image is displayed in odd columns. Typically used for
% auto-stereoscopic displays, e.g., lenticular sheet or parallax barrier
% displays.
%
% 102 == PsychImaging('AddTask', 'General', 'SideBySideCompressedStereo');
% Side-by-side compressed stereo, popular with HDMI stereo display devices.
%
% 103 == Setup for stereo display on a VR HMD.
%
% 'usedatapixx' If provided and set to a non-zero value, will setup a
% connected VPixx DataPixx device for stereo display.
%
% 'writeMovie' If provided and set to a non-zero value, will write a movie
% file 'MyTestMovie.mov' into the current working directory which captures
% the full performance of this demo. A setting of 1 will only write video,
% a setting of 2 will also write an audio track with a sequence of ten
% successive beep tones of 1 sec duration.
%
% 'reduceCrossTalkGain' If provided and set to a greater than zero value, will
% make background 50% gray and demo the crosstalk reduction shader.
%
% Authors:
% Finnegan Calabro  - fcalabro@bu.edu
% Mario Kleiner  - mario.kleiner.de at gmail.com
%
Screen('Preference', 'SkipSyncTests', 1);
% We start of with non-inverted display:
inverted = 0;

% Default to stereoMode 8 -- Red-Green stereo:
if nargin < 1
    stereoMode = [];
end

if isempty(stereoMode)
    stereoMode = 8;
end;

if nargin < 2
    usedatapixx = [];
end

if isempty(usedatapixx)
    usedatapixx = 0;
end

if nargin < 3
    writeMovie = [];
end

if isempty(writeMovie)
    writeMovie = 0;
end

if nargin < 4
    reduceCrossTalkGain = [];
end

% Check that Psychtoolbox is properly installed, switch to unified KbName's
% across operating systems, and switch color range to normalized 0 - 1 range:
PsychDefaultSetup(2);

% Define response key mappings:
space = KbName('space');
escape = KbName('ESCAPE');
leftArrow = KbName('LeftArrow');
rightArrow = KbName('RightArrow');
downArrow = KbName('DownArrow');
upArrow = KbName('UpArrow');
%PsychDebugWindowConfiguration(0,1);

%try
% Get the list of Screens and choose the one with the highest screen number.
% Screen 0 is, by definition, the display with the menu bar. Often when
% two monitors are connected the one without the menu bar is used as
% the stimulus display.  Chosing the display with the highest dislay number is
% a best guess about where you want the stimulus displayed.
scrnNum = max(Screen('Screens'));

% Increase level of verbosity for debug purposes:
%Screen('Preference', 'Verbosity', 6);

% Open double-buffered onscreen window with the requested stereo mode,
% setup imaging pipeline for additional on-the-fly processing:

% Prepare pipeline for configuration. This marks the start of a list of
% requirements/tasks to be met/executed in the pipeline:
PsychImaging('PrepareConfiguration');
bgColor = BlackIndex(scrnNum);
% Consolidate the list of requirements (error checking etc.), open a
% suitable onscreen window and configure the imaging pipeline for that
% window according to our specs. The syntax is the same as for
% Screen('OpenWindow'):
[windowPtr, windowRect] = PsychImaging('OpenWindow', scrnNum, bgColor, [], [], [], stereoMode);


% Stimulus settings:
numDots = 800;
vel = 1;   % pix/frames
dotSize = 10;
dots = zeros(3, numDots);

xmax = RectWidth(windowRect)/2;
ymax = RectHeight(windowRect)/2;
if stereoMode == 100
    xmax = xmax/4;
    ymax = ymax/2;
else
    xmax = min(xmax, ymax) / 2;
    ymax = xmax;
end

amp = 16;

a = rand(1, numDots)*2*pi;
r = ymax * sqrt(rand(1, numDots));

dots(1, :) = r .* cos(a);
dots(2, :) = r .* sin(a);

disparity = 24;

ldots = dots(1:2, :) + [ones(1, numDots)*disparity; zeros(1, numDots)];
rdots = dots(1:2, :) - [ones(1, numDots)*disparity; zeros(1, numDots)];

 
%dots(1, :) = 2*(xmax)*rand(1, numDots) - xmax;
%dots(2, :) = 2*(ymax)*rand(1, numDots) - ymax;

% Set color gains. This depends on the anaglyph mode selected. The
% values set here as default need to be fine-tuned for any specific
% combination of display device, color filter glasses and (probably)
% lighting conditions and subject. The current settings do ok on a
% MacBookPro flat panel.

SetAnaglyphStereoParameters('LeftGains', windowPtr, [0.4 0.0 0.0]);
SetAnaglyphStereoParameters('RightGains', windowPtr, [0.0 0.2 0.7]);

% Set up alpha-blending for smooth (anti-aliased) drawing of dots:
Screen('BlendFunction', windowPtr, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

col1 = WhiteIndex(scrnNum);
col2 = col1;
center = [0 0];
sigma = 50;
xvel = 2*vel*rand(1,1)-vel;
yvel = 2*vel*rand(1,1)-vel;

Screen('Flip', windowPtr);

% Maximum number of animation frames to show:
nmax = 100000;


% Preallocate timing array for speed:
t = zeros(1, nmax);
count = 1;

% Perform a flip to sync us to vbl and take start-timestamp in t:
t(count) = Screen('Flip', windowPtr);
buttons = 0;

angle = [pi, 10*pi/180, -10*pi/180, 20*pi/180, -20*pi/180, 30*pi/180, -30*pi/180, 40*pi/180, -40*pi/180,...
         (-40+180)*pi/180, (-30+180)*pi/180, (-20+180)*pi/180, (-10+180)*pi/180, 0, ...
         (10+180)*pi/180, (20+180)*pi/180, (30+180)*pi/180, (40+180)*pi/180];
trial = 1;
while trial < 19
    % Run until a key is pressed or nmax iterations have been done:
    KbReleaseWait();
    %angle = pi*rand(1)-pi/2;
    ldotsR(1, :) = ldots(1, :) * cos(angle(trial)) - ldots(2, :) * sin(angle(trial));
    ldotsR(2, :) = ldots(1, :) * sin(angle(trial)) + ldots(2, :) * cos(angle(trial));
    rdotsR(1, :) = rdots(1, :) * cos(angle(trial)) - rdots(2, :) * sin(angle(trial));
    rdotsR(2, :) = rdots(1, :) * sin(angle(trial)) + rdots(2, :) * cos(angle(trial));
    disparity = 18;
    while 1 %(count < nmax) && ~any(buttons)
        % Demonstrate how mouse cursor position (or any other physical pointing
        % device location on the actual display) can be remapped to the
        % stereo framebuffer locations which correspond to those positions. We
        % query "physical" mouse cursor location, remap it to stereo
        % framebuffer locations, then draw some little marker-square at those
        % locations via Screen('DrawDots') below. At least one of the squares
        % locations should correspond to the location of the mouse cursor
        % image:
        [x,y, buttons] = GetMouse(windowPtr);
        [x,y] = RemapMouse(windowPtr, 'AllViews', x, y);
        
        lldots = dots(1:2, :) + [ones(1, numDots)*disparity; zeros(1, numDots)];
        rrdots = dots(1:2, :) - [ones(1, numDots)*disparity; zeros(1, numDots)];
        
        Screen('TextSize', windowPtr, 50);
        % Select left-eye image buffer for drawing:
        Screen('SelectStereoDrawBuffer', windowPtr, 0);
        Screen('DrawText', windowPtr, ['Pre-Trial number:',int2str(trial)], 100, 100, [255, 255, 255, 255]);
        %Screen('DrawLines', windowPtr, [windowRect(3)/2, windowRect(3)/2; 0, windowRect(4)],8, [255, 255, 255, 255]);
        % Draw left stim:
        Screen('DrawDots', windowPtr, lldots, dotSize, col1, [0.3*windowRect(3), windowRect(4)/2], 1);
        Screen('DrawDots', windowPtr, ldotsR, dotSize, col1, [0.7*windowRect(3), windowRect(4)/2], 1);
        Screen('FrameRect', windowPtr, [1 0 0], [], 5);
        Screen('DrawDots', windowPtr, [x ; y], 8, [1 0 0]);

        % Select right-eye image buffer for drawing:
        Screen('SelectStereoDrawBuffer', windowPtr, 1);

        % Draw right stim:
        Screen('DrawText', windowPtr, ['Pre-Trial number:',int2str(trial)], 100, 100, [255, 255, 255, 255]);
        Screen('DrawLines', windowPtr, [windowRect(3)/2, windowRect(3)/2; 0, windowRect(4)],8, [255, 255, 255, 255]);
        Screen('DrawDots', windowPtr, rrdots, dotSize, col2, [0.3*windowRect(3), windowRect(4)/2], 1);
        Screen('DrawDots', windowPtr, rdotsR, dotSize, col2, [0.7*windowRect(3), windowRect(4)/2], 1);
        Screen('FrameRect', windowPtr, [0 1 0], [], 5);
        Screen('DrawDots', windowPtr, [x ; y], 8, [0 1 0]);

        % Tell PTB drawing is finished for this frame:
        Screen('DrawingFinished', windowPtr);

        % Now all non-drawing tasks:

        % Compute dot positions and offsets for next frame:
        center = center; %+ [xvel yvel];

        %dots(3, :) = -amp.*exp(-(dots(1, :) - center(1)).^2 / (2*sigma*sigma)).*exp(-(dots(2, :) - center(2)).^2 / (2*sigma*sigma));

        % Keyboard queries and key handling:
        [pressed dummy keycode] = KbCheck; %#ok<ASGLU>
        if pressed
            % SPACE key toggles between non-inverted and inverted display:
            if keycode(space) && ismember(stereoMode, [6 7 8 9]);
                KbReleaseWait;
                inverted = 1 - inverted;
                if inverted
                    % Set inverted mode:
                    SetAnaglyphStereoParameters('InvertedMode', windowPtr);
                else
                    % Set standard mode:
                    SetAnaglyphStereoParameters('StandardMode', windowPtr);
                end
            end

            if keycode(leftArrow)
                disparity = disparity - 0.2;
            end

            if keycode(rightArrow)
                disparity = disparity + 0.2;
            end
            
            if keycode(downArrow) || keycode(upArrow)
                break;
            end
            % ESCape key exits the demo:
            if keycode(escape)
                break;
            end
           
        end
        % Flip stim to display and take timestamp of stimulus-onset after
        % displaying the new stimulus and record it in vector t:
        onset = Screen('Flip', windowPtr);

        % Log timestamp:
        count = count + 1;
        t(count) = onset;
    end 
    results(trial).angle = angle(trial)*180/pi;
    results(trial).disparity = disparity;
    if keycode(escape)
        break;
    end
    if keycode(upArrow) && trial > 1
        trial = trial - 1;
    elseif keycode(upArrow) && trial == 1
        continue;
    else
        trial = trial + 1;
    end
end

angle = [-40*pi/180, -30*pi/180, -20*pi/180, -10*pi/180, 0, 10*pi/180, 20*pi/180, 30*pi/180, 40*pi/180, ...
         (-40+180)*pi/180, (-30+180)*pi/180, (-20+180)*pi/180, (-10+180)*pi/180, pi, ...
         (10+180)*pi/180, (20+180)*pi/180, (30+180)*pi/180, (40+180)*pi/180, ...
         -40*pi/180, -30*pi/180, -20*pi/180, -10*pi/180, 0, 10*pi/180, 20*pi/180, 30*pi/180, 40*pi/180, ...
         (-40+180)*pi/180, (-30+180)*pi/180, (-20+180)*pi/180, (-10+180)*pi/180, pi, ...
         (10+180)*pi/180, (20+180)*pi/180, (30+180)*pi/180, (40+180)*pi/180];
     
angle = angle(randperm(length(angle)));
trial = 1;
while trial < length(angle) + 1
    % Run until a key is pressed or nmax iterations have been done:
    KbReleaseWait();
    %angle = pi*rand(1)-pi/2;
    ldotsR(1, :) = ldots(1, :) * cos(angle(trial)) - ldots(2, :) * sin(angle(trial));
    ldotsR(2, :) = ldots(1, :) * sin(angle(trial)) + ldots(2, :) * cos(angle(trial));
    rdotsR(1, :) = rdots(1, :) * cos(angle(trial)) - rdots(2, :) * sin(angle(trial));
    rdotsR(2, :) = rdots(1, :) * sin(angle(trial)) + rdots(2, :) * cos(angle(trial));
    disparity = 30;
    while 1 %(count < nmax) && ~any(buttons)
        % Demonstrate how mouse cursor position (or any other physical pointing
        % device location on the actual display) can be remapped to the
        % stereo framebuffer locations which correspond to those positions. We
        % query "physical" mouse cursor location, remap it to stereo
        % framebuffer locations, then draw some little marker-square at those
        % locations via Screen('DrawDots') below. At least one of the squares
        % locations should correspond to the location of the mouse cursor
        % image:
        [x,y, buttons] = GetMouse(windowPtr);
        [x,y] = RemapMouse(windowPtr, 'AllViews', x, y);
        
        lldots = dots(1:2, :) + [ones(1, numDots)*disparity; zeros(1, numDots)];
        rrdots = dots(1:2, :) - [ones(1, numDots)*disparity; zeros(1, numDots)];
      
        Screen('TextSize', windowPtr, 50);
        % Select left-eye image buffer for drawing:
        Screen('SelectStereoDrawBuffer', windowPtr, 0);
        Screen('DrawText', windowPtr, ['Trial number:',int2str(trial)], 100, 100, [255, 255, 255, 255]);
        %Screen('DrawLines', windowPtr, [windowRect(3)/2, windowRect(3)/2; 0, windowRect(4)],8, [255, 255, 255, 255]);
        % Draw left stim:
        Screen('DrawDots', windowPtr, lldots, dotSize, col1, [0.3*windowRect(3), windowRect(4)/2], 1);
        Screen('DrawDots', windowPtr, ldotsR, dotSize, col1, [0.7*windowRect(3), windowRect(4)/2], 1);
        Screen('FrameRect', windowPtr, [1 0 0], [], 5);
        Screen('DrawDots', windowPtr, [x ; y], 8, [1 0 0]);

        % Select right-eye image buffer for drawing:
        Screen('SelectStereoDrawBuffer', windowPtr, 1);
        Screen('DrawLines', windowPtr, [windowRect(3)/2, windowRect(3)/2; 0, windowRect(4)],8, [255, 255, 255, 255]);
        % Draw right stim:
        Screen('DrawText', windowPtr, ['Trial number:',int2str(trial)], 100, 100, [255, 255, 255, 255]);
        Screen('DrawDots', windowPtr, rrdots, dotSize, col2, [0.3*windowRect(3), windowRect(4)/2], 1);
        Screen('DrawDots', windowPtr, rdotsR, dotSize, col2, [0.7*windowRect(3), windowRect(4)/2], 1);
        Screen('FrameRect', windowPtr, [0 1 0], [], 5);
        Screen('DrawDots', windowPtr, [x ; y], 8, [0 1 0]);

        % Tell PTB drawing is finished for this frame:
        Screen('DrawingFinished', windowPtr);

        % Now all non-drawing tasks:

        % Compute dot positions and offsets for next frame:
        center = center; %+ [xvel yvel];

        %dots(3, :) = -amp.*exp(-(dots(1, :) - center(1)).^2 / (2*sigma*sigma)).*exp(-(dots(2, :) - center(2)).^2 / (2*sigma*sigma));

        % Keyboard queries and key handling:
        [pressed dummy keycode] = KbCheck; %#ok<ASGLU>
        if pressed
            % SPACE key toggles between non-inverted and inverted display:
            if keycode(space) && ismember(stereoMode, [6 7 8 9]);
                KbReleaseWait;
                inverted = 1 - inverted;
                if inverted
                    % Set inverted mode:
                    SetAnaglyphStereoParameters('InvertedMode', windowPtr);
                else
                    % Set standard mode:
                    SetAnaglyphStereoParameters('StandardMode', windowPtr);
                end
            end

            if keycode(leftArrow)
                disparity = disparity - 0.2;
            end

            if keycode(rightArrow)
                disparity = disparity + 0.2;
            end
            
            if keycode(downArrow) || keycode(upArrow)
                break;
            end
            % ESCape key exits the demo:
            if keycode(escape)
                break;
            end
           
        end
        % Flip stim to display and take timestamp of stimulus-onset after
        % displaying the new stimulus and record it in vector t:
        onset = Screen('Flip', windowPtr);

        % Log timestamp:
        count = count + 1;
        t(count) = onset;
    end 
    results(trial).angle = angle(trial)*180/pi;
    results(trial).disparity = disparity;
    if keycode(escape)
        break;
    end
    if keycode(upArrow) && trial > 1
        trial = trial - 1;
    elseif keycode(upArrow) && trial == 1
        continue;
    else
        trial = trial + 1;
    end
end

% Last Flip:
Screen('Flip', windowPtr);

% Done. Close the onscreen window:
Screen('CloseAll')

% Compute and show timing statistics:
t = t(1:count);
dt = t(2:end) - t(1:end-1);
disp(sprintf('N.Dots\tMean (s)\tMax (s)\t%%>20ms\t%%>30ms\n')); %#ok<DSPS>
disp(sprintf('%d\t%5.3f\t%5.3f\t%5.0f\t%5.0f\n', numDots, mean(dt), max(dt), sum(dt > 0.020)/length(dt)*100, sum(dt > 0.030)/length(dt)*100)); %#ok<DSPS>
% We're done.
return
