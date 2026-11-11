classdef ClassPLHeader < handle
    properties (SetAccess = private)
        SOF_SEQ
        PLS_SCRAMBLING
        G
        MODCOD
        TYPE
    end

    methods
        function obj = ClassPLHeader()
            obj.MODCOD = 4;
            obj.TYPE   = 1;
            decVal = hex2dec('18D2E82');
            obj.SOF_SEQ = double(dec2bin(decVal, 26)) - '0';

            obj.PLS_SCRAMBLING = [ ...
                0 1 1 1 0 0 0 1 1 0 0 1 1 1 0 1, ...
                1 0 0 0 0 0 1 1 1 1 0 0 1 0 0 1, ...
                0 1 0 1 0 0 1 1 0 1 0 0 0 0 1 0, ...
                0 0 1 0 1 1 0 1 1 1 1 1 1 0 1 0];

            g1 = repmat([0 1], 1, 16);
            g2 = repmat([0 0 1 1], 1, 8);
            g3 = repmat([0 0 0 0 1 1 1 1], 1, 4);
            g4 = repmat([0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1], 1, 2);
            g5 = [zeros(1,16), ones(1,16)];
            g6 = ones(1,32);
            obj.G = [g1; g2; g3; g4; g5; g6];
        end

        function Symbols = Step(obj)
            inputBits = [obj.dec2binArr(obj.MODCOD, 5), ...
                         obj.dec2binArr(obj.TYPE,   2)];
            plsCode = obj.EncodePLS(inputBits);
            plsCode = xor(plsCode, obj.PLS_SCRAMBLING);
            plHeaderBits = [obj.SOF_SEQ, plsCode];

            y = plHeaderBits;
            a = 1/sqrt(2);
            Symbols = zeros(1, 90);
            for i = 1:45
                y1 = y(2*i - 1);
                y2 = y(2*i);
                Symbols(2*i - 1) = a*(1-2*y1) + 1j * a*(1-2*y1);
                Symbols(2*i)     = -a*(1-2*y2) + 1j * a*(1-2*y2);
            end
        end

        % --- ОБНОВЛЕННАЯ ФУНКЦИЯ ДЕКОДИРОВАНИЯ ---
        function [modcod, type] = decode(obj, rxSym)
            % 1. Демодуляция pi/2-BPSK в мягкие LLR (по стр. 9 методички)
            L = zeros(1, 90);
            for k = 1:90
                if mod(k, 2) == 1
                    L(k) = real(rxSym(k) * exp(-1j*pi/4));
                else
                    L(k) = -real(rxSym(k) * exp( 1j*pi/4));
                end
            end
            
            % 2. Берем только PLS (пропускаем SOF)
            plsRxLLR = L(27:90);
            
            % 3. Дескремблирование LLR (по стр. 10 методички)
            % p_k = 1 -> меняем знак, модуль оставляем
            plsDescrambledLLR = (1 - 2*obj.PLS_SCRAMBLING) .* plsRxLLR;
            
            % 4. Декодируем мягкие решения
            [modcod, type] = obj.decodePLS(plsDescrambledLLR);
        end
    end

    methods (Access = private)
        function bits = dec2binArr(~, val, numBits)
            bits = zeros(1, numBits);
            for i = 1:numBits
                bits(i) = bitget(val, numBits - i + 1);
            end
        end

        function outBits = EncodePLS(obj, inBits)
            b1_6 = inBits(1:6);
            b7   = inBits(7);
            y = mod(b1_6 * obj.G, 2);
            outBits = zeros(1, 64);
            for i = 1:32
                if b7 == 0
                    outBits(2*i - 1) = y(i);
                    outBits(2*i)     = y(i);
                else
                    outBits(2*i - 1) = y(i);
                    outBits(2*i)     = ~y(i);
                end
            end
        end


        function [modcod, type] = decodePLS(obj, plsLLR)

            S = sum(plsLLR(1:2:end) .* plsLLR(2:2:end));
            
            if S >= 0
                b7 = 0; 
                Lp = plsLLR(1:2:end) + plsLLR(2:2:end);
            else
                b7 = 1; 
                Lp = plsLLR(1:2:end) - plsLLR(2:2:end);
            end
        
            bestMetric = -inf; 
            bestIdx = 0;
            
            for idx = 1:64
                b1_6 = double(dec2bin(idx-1, 6)) - '0';
                c = mod(b1_6 * obj.G, 2); 
                

                metric = sum((1 - 2*c) .* Lp);
                
                if metric > bestMetric
                    bestMetric = metric; 
                    bestIdx = idx;
                end
            end
            
            b1_6 = double(dec2bin(bestIdx-1, 6)) - '0';
            modcod = bin2dec(char(b1_6(1:5) + '0'));
            type   = bin2dec(char([b1_6(6), b7] + '0'));
        end
    end
end
