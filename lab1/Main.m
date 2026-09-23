function Main(FirstParamsNum, Step4ParamsNum, LogLanguage)
    clc;
    close all;

    if ~(nargin >= 0 && nargin <= 3)
        error(['Количество входных переменных Main должно быть ', ...
            '0, 1, 2 или 3. The number of input arguments to the ', ...
            'Main should be equal to 0, 1, 2 or 3.']);
    end

    if nargin >= 0 && nargin <= 2
        LogLanguage = 'Russian';
    else
        if ~(strcmp(LogLanguage, 'Russian') || ...
                strcmp(LogLanguage, 'English'))
            error(['Недопустимое значение переменной ', ...
                'LogLanguage! Допустимые значения ''Russian'' и ', ...
                '''English''. Invalid value of LogLanguage! ', ...
                'Valid values are ''Russian'' and ''English''.']);
        end
    end

    if nargin == 0
        FirstParamsNum = 1;
        Step4ParamsNum = 1;
    elseif nargin == 1
        Step4ParamsNum = 1;
    else
    end

    Params = ReadSetup(LogLanguage);

    NumParams = length(Params);
    if nargin == 1
        kVals = FirstParamsNum;
    else
        kVals = FirstParamsNum : Step4ParamsNum : NumParams;
    end

    if (min(kVals) < 1) || (max(NumParams) > NumParams)
        if strcmp(LogLanguage, 'Russian')
            error('Недопустимое значение номера набора парметров');
        else
            error('Invalid value of number for parameters set');
        end
    end

    AllResults = cell(0);

    for k = kVals
        Params{k} = SetParams(Params{k}, k, LogLanguage);
        Params{k} = CalcAndCheckParams(Params{k}, LogLanguage);
        [Objs, Ruler] = PrepareObjects(Params{k}, k, NumParams, LogLanguage);
        Ruler.StartParallel();
        Ruler.ResetRandStreams();

        while ~Ruler.isStop
            if Ruler.NumWorkers > 1
                parfor n = 1:Ruler.NumWorkers
                    Objs{n} = LoopFun(Objs{n}, Ruler, n);
                end
            else
                Objs{1} = LoopFun(Objs{1}, Ruler, 1);
            end
            isPointFinished = Ruler.Step(Objs);
            if isPointFinished
                Ruler.Saves(Objs, Params{k});
            end
        end

        if isequal(k, kVals(end))
            Ruler.StopParallel();
        end

        AllResults{end+1} = CollectForPlots(Params{k}, Objs{1});

        DeleteObjects(Objs, Ruler);
    end

    DrawLabPlots(AllResults);
end

function Objs = LoopFun(inObjs, Ruler, WorkerNum)
    Objs = inObjs;

    for k = 1:Ruler.OneWorkerNumOneIterFrames(WorkerNum)
        Frame.TxData       = Objs.Source.Step();
        Frame.TxEncData    = Objs.Encoder.StepTx(Frame.TxData);
        Frame.TxIntData    = Objs.Interleaver.StepTx(Frame.TxEncData);
        Frame.TxModSymbols = Objs.Mapper.StepTx(Frame.TxIntData);
        Frame.TxSignal     = Objs.Sig.StepTx(Frame.TxModSymbols);

        [Frame.RxSignal, InstChannelParams] = Objs.Channel.Step(...
            Frame.TxSignal, Ruler.h2dB);

        Frame.RxModSymbols = Objs.Sig.StepRx(Frame.RxSignal);
        Frame.RxIntData    = Objs.Mapper.StepRx(...
            Frame.RxModSymbols, InstChannelParams);
        Frame.RxEncData    = Objs.Interleaver.StepRx(Frame.RxIntData);
        Frame.RxData       = Objs.Encoder.StepRx(Frame.RxEncData);

        L = min(length(Frame.TxData), length(Frame.RxData));
        Frame.TxData = Frame.TxData(1:L);
        Frame.RxData = Frame.RxData(1:L);

        Objs.Stat.Step(Frame);
    end
end