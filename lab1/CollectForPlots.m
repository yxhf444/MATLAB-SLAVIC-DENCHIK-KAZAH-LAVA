function R = CollectForPlots(Params, Objs)
    R.beta     = Params.Sig.Rolloff;
    R.sps      = Params.Sig.SPS;
    R.span     = Params.Sig.Span;
    R.M        = Params.Mapper.ModulationOrder;
    R.k        = log2(R.M);
    R.phaseOff = Params.Mapper.PhaseOffset;
    R.T        = 1;
    R.Fs       = R.sps / R.T;
    R.Nfft     = 2048;
    R.rrc      = Objs.Sig.RRC;
    R.EbN0_dB  = 0:2:10;
    R.numbits  = 5000000;

    rng(0);
    bits = randi([0 1], R.numbits, 1);
    symbols = bi2de(reshape(bits, R.k, []).', 'left-msb');
    modSymbs = pskmod(symbols, R.M, R.phaseOff, 'gray');

    sig = upfirdn(modSymbs, R.rrc, R.sps, 1);

    R.bits     = bits;
    R.modSymbs = modSymbs;
    R.sig      = sig;

    EbN0_lin = 10.^(R.EbN0_dB/10);
    Ps = mean(abs(sig).^2);
    R.BER_sim   = zeros(1, length(R.EbN0_dB));
    R.BER_theor = berawgn(R.EbN0_dB, 'psk', R.M, 'nondiff');

    for j = 1:length(R.EbN0_dB)
        Rb = R.k / R.T;
        N0 = Ps / (EbN0_lin(j) * Rb);
        sigma2 = N0 * R.Fs / 2;

        noise = sqrt(sigma2) * (randn(size(sig)) + 1j*randn(size(sig)));
        r = sig + noise;

        y = conv(r, R.rrc, 'full');
        Lr = length(R.rrc);
        delay = (Lr - 1);
        y = y(delay+1 : end);
        y_sym = y(1 : R.sps : end);
        y_sym = y_sym(1:length(modSymbs));

        recSymbs = pskdemod(y_sym, R.M, R.phaseOff, 'gray');
        recBits = de2bi(recSymbs, R.k, 'left-msb').';
        recBits = recBits(:);

        bits_ref = bits(1:length(recBits));
        R.BER_sim(j) = mean(recBits ~= bits_ref);
    end
end