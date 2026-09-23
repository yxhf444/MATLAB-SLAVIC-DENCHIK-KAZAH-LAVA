classdef ClassBERRuler < handle
    properties (SetAccess = private)
        SaveFileName;
        SaveDirName;
        NumOneIterFrames;
        NumWorkers;
        isRealTimeLog;
        h2Precision;
        BERPrecision;
        BERNumRateDigits;
        FERNumRateDigits;
        MinNumTrFrames;
        h2dBInit;
        h2dBInitStep;
        h2dBMaxStep;
        h2dBMinStep;
        h2dBMax;
        MinBER;
        MinNumErBits;
        MinFER;
        MinNumErFrames;
        MaxNumTrBits
        MaxNumTrFrames
        MaxBERRate;
        MinBERRate;
        LogLanguage;
    end
    properties (SetAccess = private)
        h2dB;
        isStop;
        OneWorkerNumOneIterFrames;
    end
    properties (SetAccess = private)
        strh2Precision;
        strh2NumDigits;
        strBERPrecision;
        strBERNumRateDigits;
        strFERNumRateDigits;
    end
    properties (SetAccess = private)
        h2dBs;
        NumTrBits;
        NumTrFrames;
        NumErBits;
        NumErFrames;
    end
    properties (SetAccess = private)
        isMainCalcFinished;
        h2dBStep;
        Addh2dBs;
        Log;
        FullSaveFileName;
        FullLogFileName;
    end
    methods
        function obj = ClassBERRuler(Params, ParamsNum, NumParams, LogLanguage)
            Common = Params.Common;
            BER    = Params.BER;

            obj.SaveFileName     = Common.SaveFileName;
            obj.SaveDirName      = Common.SaveDirName;
            obj.NumOneIterFrames = Common.NumOneIterFrames;
            obj.NumWorkers       = Common.NumWorkers;
            obj.isRealTimeLog(1) = Common.isRealTimeLogCWin;
            obj.isRealTimeLog(2) = Common.isRealTimeLogFile;

            obj.h2Precision      = BER.h2Precision;
            obj.BERPrecision     = BER.BERPrecision;
            obj.BERNumRateDigits = BER.BERNumRateDigits;
            obj.FERNumRateDigits = BER.FERNumRateDigits;

            obj.MinNumTrFrames   = BER.MinNumTrFrames;

            obj.h2dBInit         = BER.h2dBInit;
            obj.h2dBInitStep     = BER.h2dBInitStep;
            obj.h2dBMaxStep      = BER.h2dBMaxStep;
            obj.h2dBMinStep      = BER.h2dBMinStep;
            obj.h2dBMax          = BER.h2dBMax;

            obj.MinBER           = BER.MinBER;
            obj.MinNumErBits     = BER.MinNumErBits;
            obj.MinFER           = BER.MinFER;
            obj.MinNumErFrames   = BER.MinNumErFrames;

            obj.MaxNumTrBits     = BER.MaxNumTrBits;
            obj.MaxNumTrFrames   = BER.MaxNumTrFrames;

            obj.MaxBERRate       = BER.MaxBERRate;
            obj.MinBERRate       = BER.MinBERRate;

            obj.LogLanguage = LogLanguage;

            obj.h2dB   = obj.h2dBInit;
            obj.isStop = false;

            obj.strh2Precision      = sprintf('%d', obj.h2Precision);
            if obj.h2Precision == 0
                obj.strh2NumDigits      = sprintf('%d', ...
                    obj.h2Precision + 2);
            else
                obj.strh2NumDigits      = sprintf('%d', ...
                    obj.h2Precision + 3);
            end
            obj.strBERPrecision     = sprintf('%d', obj.BERPrecision);
            obj.strBERNumRateDigits = sprintf('%d', ...
                obj.BERNumRateDigits);
            obj.strFERNumRateDigits = sprintf('%d', ...
                obj.FERNumRateDigits);

            obj.h2dBInit     = obj.Round(obj.h2dBInit);
            obj.h2dBInitStep = obj.Round(obj.h2dBInitStep);
            obj.h2dBMaxStep  = obj.Round(obj.h2dBMaxStep);
            obj.h2dBMinStep  = obj.Round(obj.h2dBMinStep);
            obj.h2dBMax      = obj.Round(obj.h2dBMax);

            obj.OneWorkerNumOneIterFrames = zeros(1, ...
                Common.NumWorkers) + round(Common.NumOneIterFrames ...
                / Common.NumWorkers);
            obj.OneWorkerNumOneIterFrames(end) = ...
                Common.NumOneIterFrames - ...
                sum(obj.OneWorkerNumOneIterFrames(1:end-1));

            obj.h2dBs       = obj.h2dB;
            obj.NumTrBits   = 0;
            obj.NumTrFrames = 0;
            obj.NumErBits   = 0;
            obj.NumErFrames = 0;

            obj.isMainCalcFinished = false;
            obj.h2dBStep = obj.h2dBInitStep;
            obj.Addh2dBs = [];

            if ~isfolder(obj.SaveDirName)
                mkdir(obj.SaveDirName);
            end

            if isunix
                PathDelimiter = '/';
            elseif ispc
                PathDelimiter = '\';
            else
                if strcmp(obj.LogLanguage, 'Russian')
                    error('Не удаётся определить платформу!');
                else
                    error('Cannot recognize platform!');
                end
            end

            obj.FullLogFileName = [obj.SaveDirName, PathDelimiter, ...
                obj.SaveFileName, '.log'];

            obj.FullSaveFileName = [obj.SaveDirName, PathDelimiter, ...
                obj.SaveFileName, '.mat'];

            if strcmp(obj.LogLanguage, 'Russian')
                LogStr1 = sprintf(['%s Старт вычисления ', ...
                    'кривой %s (%d из %d).\n'], datestr(now), ...
                    obj.SaveFileName, ParamsNum, NumParams);
            else
                LogStr1 = sprintf(['%s Start of calculation ', ...
                    'the curve %s (%d of %d).\n'], ...
                    datestr(now), obj.SaveFileName, ParamsNum, ...
                    NumParams);
            end
            if strcmp(obj.LogLanguage, 'Russian')
                LogStr2 = sprintf(['%s   Старт основных ', ...
                    'вычислений.\n'], datestr(now));
            else
                LogStr2 = sprintf(['%s   Start of the ', ...
                    'main calculations.\n'], datestr(now));
            end

            obj.Log = cell(2, 1);
            obj.Log{1} = {LogStr1; LogStr2};
            obj.Log{2} = obj.Log{1};

            for k = 1:2
                if k == 1
                    obj.PrintLog(k, obj.isRealTimeLog(k));
                else
                    obj.PrintLog(k, 1);
                end
                if obj.isRealTimeLog(k)
                    obj.Log{k}{3} = '';
                else
                    obj.Log{k} = cell(0);
                end
            end
        end
        function isPointFinished = Step(obj, Objs)
            for k = 1:length(Objs)
                obj.NumTrBits(end)   = obj.NumTrBits(end)   + ...
                    Objs{k}.Stat.NumTrBits;
                obj.NumTrFrames(end) = obj.NumTrFrames(end) + ...
                    Objs{k}.Stat.NumTrFrames;

                obj.NumErBits(end)   = obj.NumErBits(end)   + ...
                    Objs{k}.Stat.NumErBits;
                obj.NumErFrames(end) = obj.NumErFrames(end) + ...
                    Objs{k}.Stat.NumErFrames;

                Objs{k}.Stat.Reset();
            end

            isComplexityExceeded = false;
            if (obj.NumTrBits(end) > obj.MaxNumTrBits) || ...
                    (obj.NumTrFrames(end) > obj.MaxNumTrFrames)
                isComplexityExceeded = true;
            end

            isPointFinished = false;
            if ((obj.NumErBits(end) >= obj.MinNumErBits) && ...
                    (obj.NumErFrames(end) >= obj.MinNumErFrames) && ...
                    (obj.NumTrFrames(end) >= obj.MinNumTrFrames)) || ...
                    isComplexityExceeded
                isPointFinished = true;
            end

            LogStr = sprintf(['%s     h2 = %', ...
                obj.strh2NumDigits, '.', obj.strh2Precision, ...
                'f дБ; h2Step = %', obj.strh2NumDigits, '.', ...
                obj.strh2Precision, 'f дБ; BER = %0.', ...
                obj.strBERPrecision, 'f = %', ...
                obj.strBERNumRateDigits, 'd/%', ...
                obj.strBERNumRateDigits, 'd; FER = %', ...
                obj.strFERNumRateDigits, 'd/%', ...
                obj.strFERNumRateDigits, 'd\n'], datestr(now), ...
                obj.h2dB, obj.h2dBStep, obj.NumErBits(end) / ...
                obj.NumTrBits(end), obj.NumErBits(end), ...
                obj.NumTrBits(end), obj.NumErFrames(end), ...
                obj.NumTrFrames(end));
            if strcmp(obj.LogLanguage, 'Russian')
            else
                LogStr = strrep(LogStr, 'дБ', 'dB');
            end

            if isPointFinished
                if strcmp(obj.LogLanguage, 'Russian')
                    SubS = ' Завершено';
                    if isComplexityExceeded
                        SubS = [SubS, ' (превышена сложность)'];
                    end
                else
                    SubS = ' Completed';
                    if isComplexityExceeded
                        SubS = [SubS, ' (complexity exceeded)'];
                    end
                end
                LogStr = [LogStr(1:end-1), SubS, LogStr(end)];
            end

            for k = 1:2
                if obj.isRealTimeLog(k)
                    obj.Log{k}{end} = LogStr;
                else
                    if isPointFinished
                        obj.Log{k} = {LogStr};
                    end
                end
            end

            isMainCalcJustFinished = false;
            if isPointFinished && ~obj.isMainCalcFinished
                BER = obj.NumErBits   ./ obj.NumTrBits;
                FER = obj.NumErFrames ./ obj.NumTrFrames;

                if ((BER(end) < obj.MinBER) && ...
                    (FER(end) < obj.MinFER)) || ...
                    isComplexityExceeded
                    obj.isMainCalcFinished = true;
                    obj.h2dBStep = nan;
                    isMainCalcJustFinished = true;
                end

                if length(BER) > 1
                    BERRate = BER(1:end-1) ./ BER(2:end);
                else
                    BERRate = 0.5*(obj.MinBERRate + obj.MaxBERRate);
                end
            end

            if isPointFinished && ~obj.isMainCalcFinished
                if BERRate(end) > obj.MaxBERRate
                    RRate = BERRate(end) / obj.MaxBERRate;
                    if                      (RRate <  4)
                        DecFact = 1/2;
                    elseif (RRate >=  4) && (RRate < 16)
                        DecFact = 1/4;
                    elseif (RRate >= 16) && (RRate < 64)
                        DecFact = 1/8;
                    elseif (RRate >= 64)
                        DecFact = 1/16;
                    end
                    Buf = obj.Round(DecFact*obj.h2dBStep);
                    obj.h2dBStep = max(Buf, obj.h2dBMinStep);
                elseif BERRate(end) < obj.MinBERRate
                    Buf = obj.Round(2*obj.h2dBStep);
                    obj.h2dBStep = min(Buf, obj.h2dBMaxStep);
                end
                obj.h2dB = obj.h2dB + obj.h2dBStep;
                if obj.h2dB > obj.h2dBMax
                    obj.isMainCalcFinished = true;
                    isMainCalcJustFinished = true;
                end
                if obj.h2dBStep < eps
                    obj.isMainCalcFinished = true;
                    isMainCalcJustFinished = true;
                end
            end

            if isMainCalcJustFinished
                if strcmp(obj.LogLanguage, 'Russian')
                    LogStr = '   Основные вычисления завершены.';
                    if obj.h2dB > obj.h2dBMax
                        LogStr = [LogStr, ' (Превышено ', ...
                            'максимальное ОСШ)'];
                    end
                    if obj.h2dBStep < eps
                        LogStr = [LogStr, ' (Получен нулевой шаг h2)'];
                    end
                else
                    LogStr = '   The main calculations are completed.';
                    if obj.h2dB > obj.h2dBMax
                        LogStr = [LogStr, ' (Maximum SNR is ', ...
                            'exceeded)'];
                    end
                    if obj.h2dBStep < eps
                        LogStr = [LogStr, ' (Zero h2 step obtained)'];
                    end
                end
                LogStr = sprintf('%s%s\n', datestr(now), LogStr);
                for k = 1:2
                    obj.Log{k}{end+1} = LogStr;
                end
            end

            if isPointFinished && obj.isMainCalcFinished && ...
                    isComplexityExceeded && ~isMainCalcJustFinished
                Poses = (obj.h2dBs <= obj.h2dB);
                obj.h2dBs       = obj.h2dBs      (Poses);
                obj.NumTrBits   = obj.NumTrBits  (Poses);
                obj.NumTrFrames = obj.NumTrFrames(Poses);
                obj.NumErBits   = obj.NumErBits  (Poses);
                obj.NumErFrames = obj.NumErFrames(Poses);
                NumDeleted1 = length(Poses) - sum(Poses);
                Poses = (obj.Addh2dBs <= obj.h2dB);
                obj.Addh2dBs = obj.Addh2dBs(Poses);
                NumDeleted2 = length(Poses) - sum(Poses);
                if strcmp(obj.LogLanguage, 'Russian')
                    LogStr = sprintf([ ...
                        '%s     Удалено %d точек из ', ...
                        'результатов основных вычислений и ', ...
                        'удалено %d значений h2, ', ...
                        'предполагавшихся к рассмотрению в ', ...
                        'дополнительных вычислениях.\n'], ...
                        datestr(now), NumDeleted1, NumDeleted2);
                else
                    LogStr = sprintf([ ...
                        '%s     %d results are deleted from ', ...
                        'main calculations and %d values of ', ...
                        'h2 are deleted from the set for ', ...
                        'additional calculations .\n'], ...
                        datestr(now), NumDeleted1, NumDeleted2);
                end
                for k = 1:2
                    obj.Log{k}{end+1} = LogStr;
                end
            end

            if isPointFinished && obj.isMainCalcFinished
                if isempty(obj.Addh2dBs)
                    [obj.h2dBs, I]  = sort(obj.h2dBs);
                    obj.NumTrBits   = obj.NumTrBits  (I);
                    obj.NumTrFrames = obj.NumTrFrames(I);
                    obj.NumErBits   = obj.NumErBits  (I);
                    obj.NumErFrames = obj.NumErFrames(I);
                    BER = obj.NumErBits ./ obj.NumTrBits;
                    if length(BER) > 1
                        BERRate = BER(1:end-1) ./ BER(2:end);
                    else
                        BERRate = 0.5*(obj.MinBERRate + ...
                            obj.MaxBERRate);
                    end
                    Poses = find(BERRate > obj.MaxBERRate);
                    obj.Addh2dBs = (obj.h2dBs(Poses+1) + ...
                        obj.h2dBs(Poses)) / 2;
                    obj.Addh2dBs = obj.Round(obj.Addh2dBs);
                    h2dBSteps = min([obj.Addh2dBs - ...
                        obj.h2dBs(Poses); ...
                        obj.h2dBs(Poses+1) - ...
                        obj.Addh2dBs]);
                    Poses = (h2dBSteps + 1000*eps >= ...
                        obj.h2dBMinStep);
                    obj.Addh2dBs = obj.Addh2dBs(Poses);
                    if ~isempty(obj.Addh2dBs)
                        LogStr = sprintf([' %0.', ...
                            obj.strh2Precision, 'f'], ...
                            obj.Addh2dBs);
                        if strcmp(obj.LogLanguage, 'Russian')
                            LogStr = sprintf([ ...
                                '%s   Старт ', ...
                                'дополнительных ', ...
                                'вычислений [%s].\n'], ...
                                datestr(now), LogStr(2:end));
                        else
                            LogStr = sprintf([ ...
                                '%s   Start of the ', ...
                                'additional calculations ', ...
                                '[%s].\n'], datestr(now), ...
                                LogStr(2:end));
                        end
                        for k = 1:2
                            obj.Log{k}{end+1} = LogStr;
                        end
                    end
                end

                if isempty(obj.Addh2dBs)
                    obj.isStop = true;

                    if ~isMainCalcJustFinished
                        if strcmp(obj.LogLanguage, 'Russian')
                            LogStr = sprintf(['%s   ', ...
                                'Дополнительные ', ...
                                'вычисления завершены.\n'], ...
                                datestr(now));
                        else
                            LogStr = sprintf(['%s   ', ...
                                'The additional ', ...
                                'calculations are ', ...
                                'completed.\n'], datestr(now));
                        end
                        for k = 1:2
                            obj.Log{k}{end+1} = LogStr;
                        end
                    end
                    if strcmp(obj.LogLanguage, 'Russian')
                        LogStr = sprintf(['%s ', ...
                            'Вычисления завершены.\n'], ...
                            datestr(now));
                    else
                        LogStr = sprintf(['%s ', ...
                            'Calculations are ', ...
                            'completed.\n'], datestr(now));
                    end
                    for k = 1:2
                        obj.Log{k}{end+1} = LogStr;
                        obj.Log{k}{end+1} = newline;
                    end
                else
                    obj.h2dB = obj.Addh2dBs(1);
                    obj.Addh2dBs = obj.Addh2dBs(2:end);
                end
            end

            if isPointFinished && ~obj.isStop
                obj.h2dBs       = [obj.h2dBs, obj.h2dB];
                obj.NumTrBits   = [obj.NumTrBits,   0];
                obj.NumTrFrames = [obj.NumTrFrames, 0];
                obj.NumErBits   = [obj.NumErBits,   0];
                obj.NumErFrames = [obj.NumErFrames, 0];
                obj.ResetRandStreams();
            end

            for k = 1:2
                obj.PrintLog(k, obj.isRealTimeLog(k));
                if obj.isRealTimeLog(k)
                    if isPointFinished && ~obj.isStop
                        obj.Log{k}{end+1} = '';
                    end
                else
                    obj.Log{k} = cell(0);
                end
            end
        end
        function Saves(obj, Objs, Params)
            Res.h2dBs       = obj.h2dBs;
            Res.NumErBits   = obj.NumErBits;
            Res.NumTrBits   = obj.NumTrBits;
            Res.NumErFrames = obj.NumErFrames;
            Res.NumTrFrames = obj.NumTrFrames;
            save(obj.FullSaveFileName, 'Res', 'Params');
        end
        function StartParallel(obj)
            P = gcp('nocreate');

            isOk = false;
            if ~isempty(P)
                if P.Connected
                    if isequal(P.NumWorkers, obj.NumWorkers)
                        isOk = true;
                    end
                end
            else
                if isequal(obj.NumWorkers, 1)
                    isOk = true;
                end
            end

            if ~isOk
                if ~isempty(P)
                    delete(P);
                end

                if obj.NumWorkers > 1
                    P = parpool(obj.NumWorkers);

                    isOk = false;
                    if P.Connected
                        if isequal(P.NumWorkers, obj.NumWorkers)
                            isOk = true;
                        end
                    end

                    if ~isOk
                        if strcmp(obj.LogLanguage, 'Russian')
                            error(['Не удалось запустить ', ...
                                'pool с заданными параметрами']);
                        else
                            error(['Failed to start the pool ', ...
                                'with the specified parameters']);
                        end
                    end
                end
            end
        end
        function StopParallel(obj)
            P = gcp('nocreate');
            if ~isempty(P)
                delete(P);
            end
        end
        function ResetRandStreams(obj)
            if obj.NumWorkers > 1
                spmd
                    Stream = RandStream.getGlobalStream;
                    reset(Stream);
                end
            else
                Stream = RandStream.getGlobalStream;
                reset(Stream);
            end
        end
        function PrintLog(obj, LogNum, isClear)
            if isempty(obj.Log{LogNum})
                return
            end

            if LogNum == 1
                if isClear
                    clc;
                end

                for k = 1:length(obj.Log{1})
                    fprintf('%s', obj.Log{1}{k});
                end
            elseif LogNum == 2
                if isClear
                    fileID = fopen(obj.FullLogFileName, 'w');
                else
                    fileID = fopen(obj.FullLogFileName, 'a');
                end

                if fileID < 0
                    if strcmp(obj.LogLanguage, 'Russian')
                        error(['Не удалось открыть файл для ', ...
                            'сохранения лога!']);
                    else
                        error('Failed to open file to save log!');
                    end
                end

                for k = 1:length(obj.Log{2})
                    fprintf(fileID, '%s\r\n', obj.Log{2}{k}(1:end-1));
                end

                fclose(fileID);
            end
        end
        function Out = Round(obj, In)
            Out = round(10^obj.h2Precision*In) / 10^obj.h2Precision;
        end
    end
end