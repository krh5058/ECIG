function ecig

% ECIG
% As requested by Travis Nichols
% 5/5/13
%
% Author: Ken Hwang
% SLEIC, PSU

if ~ispc
    error('ecig.m:PC support only.')
end

% Directory initialization
try
    fprintf('ecig.m: Directory initialization...\n')
    
    mainpath = which('main.m');
    if ~isempty(mainpath)
        [mainext,~,~] = fileparts(mainpath);
        rmpath(mainext);
    end
    
    p = mfilename('fullpath');
    [ext,~,~] = fileparts(p);
    [~,d] = system(['dir /ad-h/b ' ext]);
    d = regexp(strtrim(d),'\n','split');
    cellfun(@(y)(addpath([ext filesep y])),d);
    fprintf('ecig.m: Directory initialization success!.\n')
catch ME
    throw(ME)
end

try
    fprintf('ecig.m: Object Handling...\n')
    % Object Handling
    obj = main(ext,d);
    p_obj = pres(obj);
    obj.addl(p_obj);
    fprintf('ecig.m: Object Handling success!.\n')
catch ME
    throw(ME)
end

try
    fprintf('ecig.m: Window initialization...\n')
    % Open and format window
    obj.monitor.w = Screen('OpenWindow',obj.monitor.whichScreen,obj.monitor.black);
    Screen('BlendFunction',obj.monitor.w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    Screen('TextSize',obj.monitor.w,30);
    fprintf('ecig.m: Window initialization success!.\n')
catch ME
    throw(ME)
end

try
    fprintf('ecig.m: Loading video content...\n')
    % Movie set-up
    obj.videoload();
    fprintf('ecig.m: Loading video content success!.\n')
catch ME
    throw(ME)
end

fprintf('ecig.m: Beginning presentation sequence...\n')
ListenChar(2);
HideCursor;
ShowHideFullWinTaskbarMex(0);

% Wait for instructions
RestrictKeysForKbCheck(p_obj.keys.spacekey);
obj.dat.txt = obj.exp.intro;
notify(obj,'txt');
KbStrokeWait; % Spacebar to continue

if obj.exp.skip
    ind = 2;
else
    ind = 1:2;
end

for i = ind
    
    % Triggering
    if obj.exp.trig % Auto-trigger
        RestrictKeysForKbCheck(p_obj.keys.tkey);
        obj.dat.fix_color = obj.monitor.gray;
        notify(obj,'fix');
        KbStrokeWait; % Waiting for first trigger pulse
        obj.dat.fix_color = obj.monitor.white;
    else % Manual trigger
        RestrictKeysForKbCheck(p_obj.keys.spacekey);
        obj.dat.fix_color = obj.monitor.gray;
        notify(obj,'fix');
        KbStrokeWait; % Waiting for scanner operator
        obj.dat.fix_color = obj.monitor.gray2;
        notify(obj,'fix');
        pause(obj.exp.DisDaq); % Simulating DisDaq
        obj.dat.fix_color = obj.monitor.white;
    end
    
    RestrictKeysForKbCheck([p_obj.keys.esckey]);
    obj.cycle(i);
    
    if obj.abort
        break;
    end
    
end

% Clean up
ListenChar(0);
ShowCursor;
ShowHideFullWinTaskbarMex(1);
Screen('Preference','VisualDebugLevel',obj.monitor.oldVisualDebugLevel);
Screen('Preference','VisualDebugLevel',obj.monitor.oldOverrideMultimediaEngine);
Screen('CloseAll');

end