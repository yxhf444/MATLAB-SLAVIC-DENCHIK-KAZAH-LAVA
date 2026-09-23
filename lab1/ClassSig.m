classdef ClassSig < handle
    properties (SetAccess = private)
        isTransparent;
        Rolloff;
        Span;
        SPS;
        LogLanguage;
    end
    properties (SetAccess = private)
        RRC;
        Delay;
    end
    methods
        function obj = ClassSig(Params, LogLanguage)
            Sig = Params.Sig;
            obj.isTransparent = Sig.isTransparent;
            obj.Rolloff = Sig.Rolloff;
            obj.Span = Sig.Span;
            obj.SPS = Sig.SPS;
            obj.LogLanguage = LogLanguage;

            if ~obj.isTransparent
                obj.RRC = rcosdesign(obj.Rolloff, obj.Span, obj.SPS, 'sqrt');
                obj.Delay = (length(obj.RRC) - 1) / 2;
            end
        end
        function OutData = StepTx(obj, InData)
            if obj.isTransparent
                OutData = InData;
                return
            end
            OutData = upfirdn(InData, obj.RRC, obj.SPS, 1);
        end
        function OutData = StepRx(obj, InData)
            if obj.isTransparent
                OutData = InData;
                return
            end
            OutData = conv(InData, obj.RRC, 'full');
            OutData = OutData(2*obj.Delay + 1 : end);
            OutData = OutData(1 : obj.SPS : end);
        end
    end
end