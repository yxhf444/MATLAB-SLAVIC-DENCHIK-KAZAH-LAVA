classdef ClassSource < handle
    properties (SetAccess = private)
        NumBitsPerFrame;
        LogLanguage;
    end
    properties (SetAccess = private)
    end
    methods
        function obj = ClassSource(Params, LogLanguage)
            Source = Params.Source;
            obj.NumBitsPerFrame = Source.NumBitsPerFrame;
            obj.LogLanguage = LogLanguage;
        end
        function Bits = Step(obj)
            Bits = randi(2, obj.NumBitsPerFrame, 1) - 1;
        end
    end
end