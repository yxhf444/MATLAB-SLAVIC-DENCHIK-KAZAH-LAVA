clear; clc; close all;


R_ldpc = 1/2;
N_ldpc = 64800;
K_bch  = 32208;

MODCOD     = 4;
MOD_TYPE   = 'QPSK';
HAS_PILOTS = true;
TYPE_VAL   = 1;

MPEG_packet_len_bits = 188 * 8;
Data_field_len_bits  = 1496;

Max_DFL     = K_bch - 80;
num_packets = floor(Max_DFL / MPEG_packet_len_bits);
DFL         = num_packets * MPEG_packet_len_bits;

fprintf('MPEG-TS packets: %d, DFL = %d bits\n', num_packets, DFL);


src = ClassSource();
mpegBits = src.generateData();
fprintf('Source bits: %d\n', length(mpegBits));


enc = ClassEncoder();
dataField = enc.adaptPacketsAndCRC(mpegBits);
fprintf('dataField after CRC: %d (expected %d)\n', length(dataField), DFL);


hdr = ClassHeader();
bbFrame = hdr.createBBFrame(dataField, K_bch);
fprintf('BBFRAME length: %d (expected %d)\n', length(bbFrame), K_bch);


scr = ClassScrambler();
scrambledFrame = scr.scrambleBB(bbFrame);
fprintf('BB scrambling done, length: %d\n', length(scrambledFrame));


bchParity  = zeros(1, 192);
ldpcParity = zeros(1, N_ldpc - K_bch - 192);
fecFrame = [scrambledFrame, bchParity, ldpcParity];
fprintf('FECFRAME (stub) length: %d (expected %d)\n', length(fecFrame), N_ldpc);


il = ClassBitInterleaver();
interleavedBits = il.StepTx(fecFrame);
fprintf('Interleaving (QPSK transparent), length: %d\n', length(interleavedBits));


bitsI = interleavedBits(1:2:end);
bitsQ = interleavedBits(2:2:end);
symI  = (1 - 2*bitsI) / sqrt(2);
symQ  = (1 - 2*bitsQ) / sqrt(2);
xFecFrameSymbols = symI + 1j * symQ;

fprintf('QPSK symbols in XFECFRAME: %d\n', length(xFecFrameSymbols));
fprintf('Slots of 90 symbols: %d\n', floor(length(xFecFrameSymbols)/90));


plh = ClassPLHeader();
plHeaderSym = plh.Step();
fprintf('PLHEADER length: %d symbols\n', length(plHeaderSym));


plf = ClassPLFramer();
[xFecPilots, pilotFlags, numSlots] = plf.insertPilots( ...
    xFecFrameSymbols, HAS_PILOTS);
fprintf('XFECFRAME with pilots: %d symbols (pilots: %d)\n', ...
        length(xFecPilots), sum(pilotFlags));


scrambledXFec = scr.scramblePL(xFecPilots, 0, 0);
fprintf('PL scrambling done, length: %d\n', length(scrambledXFec));


plFrame = [plHeaderSym, scrambledXFec];
fprintf('PLFRAME total: %d symbols\n', length(plFrame));


beta = 0.35;
span = 10;
sps  = 4;
rrc  = rcosdesign(beta, span, sps, 'sqrt');
waveform = upfirdn(plFrame, rrc, sps, 1);
fprintf('RRC output: %d samples\n', length(waveform));


figure('Name', 'PLFRAME: constellation', 'Position', [100 100 900 900]);

hData  = plot(real(plFrame), imag(plFrame), 'b.', ...
    'MarkerSize', 10, 'Color', [0.3 0.5 1 0.35]);
hold on;
hHdr   = plot(real(plHeaderSym), imag(plHeaderSym), 'o', ...
    'MarkerSize', 9, 'LineWidth', 1.5, ...
    'MarkerEdgeColor', [0.85 0 0], 'MarkerFaceColor', 'none');
hPilot = plot(real(scrambledXFec(pilotFlags==1)), ...
              imag(scrambledXFec(pilotFlags==1)), '+', ...
    'MarkerSize', 11, 'LineWidth', 1.8, 'Color', [0 0.7 0]);
hold off;

grid on; box on;
pbaspect([1 1 1]);
xlim([-1.25 1.25]);
ylim([-1.25 1.25]);
set(gca, 'XTick', [-1 -0.7071 0 0.7071 1], ...
         'XTickLabel', {'-1','-0.707','0','0.707','1'}, ...
         'YTick', [-1 -0.7071 0 0.7071 1], ...
         'YTickLabel', {'-1','-0.707','0','0.707','1'});
xlabel('I'); ylabel('Q');
title('PLFRAME constellation (no noise)');
legend([hData, hHdr, hPilot], ...
    {'XFECFRAME data', 'PLHEADER (pi/2-BPSK)', 'Pilots'}, ...
    'Location', 'southeastoutside');

text( 0.707,  0.707, ' 00', 'FontSize', 10, 'Color', 'k');
text( 0.707, -0.707, ' 01', 'FontSize', 10, 'Color', 'k');
text(-0.707, -0.707, ' 11', 'FontSize', 10, 'Color', 'k');
text(-0.707,  0.707, ' 10', 'FontSize', 10, 'Color', 'k');


figure('Name', 'PLFRAME: zoom on vertex 00', ...
       'Position', [150 150 700 700]);

tol = 0.2;
maskData  = abs(real(plFrame) - 0.707) < tol & abs(imag(plFrame) - 0.707) < tol;
maskHdr   = abs(real(plHeaderSym) - 0.707) < tol & abs(imag(plHeaderSym) - 0.707) < tol;
maskPilot = pilotFlags == 1;
tmpPilot  = scrambledXFec(maskPilot);
maskPilot = abs(real(tmpPilot) - 0.707) < tol & abs(imag(tmpPilot) - 0.707) < tol;

jit = 0.015;
plot(real(plFrame(maskData)) + jit*randn(sum(maskData),1), ...
     imag(plFrame(maskData)) + jit*randn(sum(maskData),1), ...
     'b.', 'MarkerSize', 12);
hold on;
plot(real(plHeaderSym(maskHdr)) + jit*randn(sum(maskHdr),1), ...
     imag(plHeaderSym(maskHdr)) + jit*randn(sum(maskHdr),1), ...
     'ro', 'MarkerSize', 10, 'LineWidth', 1.5);
tmpP = tmpPilot(maskPilot);
plot(real(tmpP) + jit*randn(sum(maskPilot),1), ...
     imag(tmpP) + jit*randn(sum(maskPilot),1), ...
     'g+', 'MarkerSize', 12, 'LineWidth', 1.8);
hold off;

grid on; box on;
pbaspect([1 1 1]);
xlim([0.707-3*tol, 0.707+3*tol]);
ylim([0.707-3*tol, 0.707+3*tol]);
xlabel('I'); ylabel('Q');
title(sprintf('Zoom vertex 00: %d data, %d PLHEADER, %d pilots', ...
    sum(maskData), sum(maskHdr), sum(maskPilot)));
legend({'Data', 'PLHEADER', 'Pilots'}, 'Location', 'best');


figure('Name', 'RRC output spectrum');
Nfft = 4096;
S = fftshift(fft(waveform, Nfft));
f = (-Nfft/2 : Nfft/2-1) * (sps / Nfft);
plot(f, 10*log10(abs(S).^2 / max(abs(S).^2) + eps));
grid on; xlim([-2 2]); ylim([-80 5]);
xlabel('f / (1/T)'); ylabel('Normalized PSD, dB');
title(sprintf('PLFRAME spectrum after RRC, beta = %.2f', beta));
