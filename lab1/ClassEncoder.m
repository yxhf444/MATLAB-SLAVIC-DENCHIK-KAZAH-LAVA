classdef ClassEncoder < handle
    properties (SetAccess = private)
        isTransparent;
        LogLanguage;
    end
    properties (SetAccess = private)
    end
    methods
        function obj = ClassEncoder(Params, LogLanguage)
            Encoder = Params.Encoder;
            obj.isTransparent = Encoder.isTransparent;
            obj.LogLanguage = LogLanguage;
        end
        function OutData = StepTx(obj, InData)
            if obj.isTransparent
                OutData = InData;
                return
            end
            OutData = InData;
        end
        function OutData = StepRx(obj, InData)
            if obj.isTransparent
                OutData = InData;
                return
            end
            OutData = InData;
        end
    end
end