function Params = SetParams(inParams, ParamsNumber, LogLanguage)
    Params = inParams;

    FieldNames = { ...
        'Source', ...
        'Encoder', ...
        'Interleaver', ...
        'Mapper', ...
        'Sig', ...
        'Channel', ...
        'BER', ...
        'Common' ...
    };

    for n = 1:length(FieldNames)
        if ~isfield(Params, FieldNames{n})
            Params.(FieldNames{n}) = [];
        end
        Fun = str2func(['SetParams', FieldNames{n}]);
        Params.(FieldNames{n}) = Fun(Params.(FieldNames{n}), ...
            ParamsNumber, LogLanguage);
    end
end

function Source = SetParamsSource(inSource, ParamsNumber, LogLanguage)
    Source = inSource;
    if ~isfield(Source, 'NumBitsPerFrame')
        Source.NumBitsPerFrame = 1000;
    else
        if Source.NumBitsPerFrame < 1
            if strcmp(LogLanguage, 'Russian')
                error('Недопустимое значение Source.NumBitsPerFrame');
            else
                error('Invalid value Source.NumBitsPerFrame');
            end
        end
    end
end

function Encoder = SetParamsEncoder(inEncoder, ParamsNumber, LogLanguage)
    Encoder = inEncoder;
    if ~isfield(Encoder, 'isTransparent')
        Encoder.isTransparent = true;
    else
    end
end

function Interleaver = SetParamsInterleaver(inInterleaver, ParamsNumber, LogLanguage)
    Interleaver = inInterleaver;
    if ~isfield(Interleaver, 'isTransparent')
        Interleaver.isTransparent = true;
    else
    end
end

function Mapper = SetParamsMapper(inMapper, ParamsNumber, LogLanguage)
    Mapper = inMapper;
    if ~isfield(Mapper, 'isTransparent')
        Mapper.isTransparent = true;
    else
    end
    if ~isfield(Mapper, 'Type')
        Mapper.Type = 'QAM';
    else
        if ~(strcmp(Mapper.Type, 'QAM') || strcmp(Mapper.Type, 'PSK'))
            if strcmp(LogLanguage, 'Russian')
                error('Недопустимое значение Mapper.Type');
            else
                error('Invalid value Mapper.Type');
            end
        end
    end
    if ~isfield(Mapper, 'ModulationOrder')
        Mapper.ModulationOrder = 4;
    else
    end
    if ~isfield(Mapper, 'PhaseOffset')
        if strcmp(Mapper.Type, 'PSK')
            Mapper.PhaseOffset = pi/4;
        else
            Mapper.PhaseOffset = 0;
        end
    else
    end
    if ~isfield(Mapper, 'SymbolMapping')
        Mapper.SymbolMapping = 'Gray';
    else
        if ~(strcmp(Mapper.SymbolMapping, 'Binary') || ...
                strcmp(Mapper.SymbolMapping, 'Gray'))
            if strcmp(LogLanguage, 'Russian')
                error('Недопустимое значение Mapper.SymbolMapping');
            else
                error('Invalid value Mapper.SymbolMapping');
            end
        end
    end
    if ~isfield(Mapper, 'DecisionMethod')
        Mapper.DecisionMethod = 'Approximate log-likelihood ratio';
    else
        if ~(strcmp(Mapper.DecisionMethod, 'Hard decision') || ...
                strcmp(Mapper.DecisionMethod, ...
                'Log-likelihood ratio') || ...
                strcmp(Mapper.DecisionMethod, ...
                'Approximate log-likelihood ratio'))
            if strcmp(LogLanguage, 'Russian')
                error('Недопустимое значение Mapper.DecisionMethod');
            else
                error('Invalid value Mapper.DecisionMethod');
            end
        end
    end
end

function Sig = SetParamsSig(inSig, ParamsNumber, LogLanguage)
    Sig = inSig;
    if ~isfield(Sig, 'isTransparent')
        Sig.isTransparent = true;
    else
    end
    if ~isfield(Sig, 'Rolloff')
        Sig.Rolloff = 0.5;
    else
        if Sig.Rolloff < 0 || Sig.Rolloff > 1
            if strcmp(LogLanguage, 'Russian')
                error('Недопустимое значение Sig.Rolloff');
            else
                error('Invalid value Sig.Rolloff');
            end
        end
    end
    if ~isfield(Sig, 'Span')
        Sig.Span = 8;
    else
        if Sig.Span < 1 || mod(Sig.Span, 1) ~= 0
            if strcmp(LogLanguage, 'Russian')
                error('Недопустимое значение Sig.Span');
            else
                error('Invalid value Sig.Span');
            end
        end
    end
    if ~isfield(Sig, 'SPS')
        Sig.SPS = 8;
    else
        if Sig.SPS < 1 || mod(Sig.SPS, 1) ~= 0
            if strcmp(LogLanguage, 'Russian')
                error('Недопустимое значение Sig.SPS');
            else
                error('Invalid value Sig.SPS');
            end
        end
    end
end

function Channel = SetParamsChannel(inChannel, ParamsNumber, LogLanguage)
    Channel = inChannel;
    if ~isfield(Channel, 'isTransparent')
        Channel.isTransparent = true;
    else
    end
    if ~isfield(Channel, 'Type')
        Channel.Type = 'AWGN';
    else
    end
    if ~isfield(Channel, 'FadingType')
        Channel.FadingType = '';
    else
    end
end

function BER = SetParamsBER(inBER, ParamsNumber, LogLanguage)
    BER = inBER;
    if ~isfield(BER, 'h2Precision')
        BER.h2Precision = 2;
    else
    end
    if ~isfield(BER, 'BERPrecision')
        BER.BERPrecision = 8;
    else
    end
    if ~isfield(BER, 'BERNumRateDigits')
        BER.BERNumRateDigits = 10;
    else
    end
    if ~isfield(BER, 'FERNumRateDigits')
        BER.FERNumRateDigits = 7;
    else
    end
    if ~isfield(BER, 'MinNumTrFrames')
        BER.MinNumTrFrames = 100;
    else
    end
    if ~isfield(BER, 'h2dBInit')
        BER.h2dBInit = 8.4;
    else
    end
    if ~isfield(BER, 'h2dBInitStep')
        BER.h2dBInitStep = 0.4;
    else
    end
    if ~isfield(BER, 'h2dBMaxStep')
        BER.h2dBMaxStep = 1.6;
    else
    end
    if ~isfield(BER, 'h2dBMinStep')
        BER.h2dBMinStep = 0.1;
    else
    end
    if ~isfield(BER, 'h2dBMax')
        BER.h2dBMax = 25;
    else
    end
    if ~isfield(BER, 'MinBER')
        BER.MinBER = 10^-4;
    else
    end
    if ~isfield(BER, 'MinNumErBits')
        BER.MinNumErBits = 5*10^2;
    else
    end
    if ~isfield(BER, 'MinFER')
        BER.MinFER = 1;
    else
    end
    if ~isfield(BER, 'MinNumErFrames')
        BER.MinNumErFrames = 10^2;
    else
    end
    if ~isfield(BER, 'MaxNumTrBits')
        BER.MaxNumTrBits = 10^8;
    else
    end
    if ~isfield(BER, 'MaxNumTrFrames')
        BER.MaxNumTrFrames = inf;
    else
    end
    if ~isfield(BER, 'MaxBERRate')
        BER.MaxBERRate = 5;
    else
    end
    if ~isfield(BER, 'MinBERRate')
        BER.MinBERRate = 2;
    else
    end
end

function Common = SetParamsCommon(inCommon, ParamsNumber, LogLanguage)
    Common = inCommon;
    if ~isfield(Common, 'SaveFileName')
        Common.SaveFileName = sprintf('Results%02d', ParamsNumber);
    else
    end
    if ~isfield(Common, 'SaveDirName')
        Common.SaveDirName = 'Results';
    else
    end
    if ~isfield(Common, 'NumOneIterFrames')
        Common.NumOneIterFrames = 100;
    else
    end
    if ~isfield(Common, 'NumWorkers')
        Common.NumWorkers = 1;
    else
    end
    if ~isfield(Common, 'isRealTimeLogCWin')
        Common.isRealTimeLogCWin = 1;
    else
    end
    if ~isfield(Common, 'isRealTimeLogFile')
        Common.isRealTimeLogFile = 0;
    else
    end
end