classdef ClassScrambler < handle
    
    methods
        function scrambledBB = scrambleBB(obj, bbFrameBits)
            reg = [1 0 0 1 0 1 0 1 0 0 0 0 0 0 0];
            len = length(bbFrameBits);
            prbs = zeros(1, len);
            
            for i = 1:len
                newBit = xor(reg(14), reg(15));
                prbs(i) = newBit;
                reg = [newBit, reg(1:end-1)]; % Сдвиг
            end
            
            scrambledBB = xor(bbFrameBits, prbs);
        end
        
        function scrambledPL = scramblePL(obj, symbols)
            len = length(symbols);
            
            regX = [1, zeros(1, 17)];
            regY = ones(1, 18);
            
            x_seq = zeros(1, 2^18 - 1);
            y_seq = zeros(1, 2^18 - 1);
            
            for i = 1:(2^18 - 1)
                x_seq(i) = regX(18);
                y_seq(i) = regY(18);
                
                fbX = xor(regX(7), regX(18));
                regX = [fbX, regX(1:end-1)];
                
                fbY = xor(xor(xor(regY(5), regY(7)), regY(10)), regY(18));
                regY = [fbY, regY(1:end-1)];
            end
            
            z0 = xor(x_seq, y_seq);
            z_shift = circshift(z0, -131072);
            
            Rn = zeros(1, len);
            for i = 1:len
                idx = mod(i-1, 2^18 - 1) + 1;
                Rn(i) = 2 * z_shift(idx) + z0(idx);
            end
            
            C = exp(1j * Rn * pi / 2);
            scrambledPL = symbols .* C;
        end
    end
end