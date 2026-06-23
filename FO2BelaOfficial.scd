s = Server.default;

s.options.numAnalogInChannels = 10;
s.options.numAnalogOutChannels = 10;
s.options.speakerMuted = 1;
s.options.numMultiplexChannels = 0;
s.options.numDigitalChannels = 16;
s.options.blockSize = 64;
s.options.hardwareBufferSize = 64;
s.options.numInputBusChannels = 10;
s.options.numOutputBusChannels = 10;
s.options.headphoneLevel = 0;
s.options.pgaGainLeft = 25;
s.options.pgaGainRight = 25;
s.options.memSize = 65536;
s.options.sampleRate = 44100;
s.options.postln;

s.waitForBoot({

    ~fxBus     = Bus.audio(s, 2);
    ~analogBus = Bus.audio(s, 2);

    ~a0 = Bus.control(s, 1);
    ~a1 = Bus.control(s, 1);
    ~a2 = Bus.control(s, 1);
    ~a3 = Bus.control(s, 1);
    ~d6 = Bus.control(s, 1);
    ~d1 = Bus.control(s, 1);

    SynthDef(\MasterAnalogIn, {
        var a0 = AnalogIn.kr(0).linlin(0.2,0.7,0.0,1.05);
        var a1 = AnalogIn.kr(1).linlin(0.2,0.7,0.0,1.05);
        var a2 = AnalogIn.kr(2).linlin(0.2,0.65,1.05,0.0);
        var a3 = AnalogIn.kr(3).linlin(0.2,0.7,0.0,1.05);
        var d6 = DigitalIn.kr(6);
        var d1 = DigitalIn.kr(10);

        Out.kr(~a0, a0);
        Out.kr(~a1, a1);
        Out.kr(~a2, a2);
        Out.kr(~a3, a3);
        Out.kr(~d6, d6);
        Out.kr(~d1, d1);
    }).add;

    s.sync;
    ~ioMaster = Synth.head(s, \MasterAnalogIn);

    SynthDef(\analogPatch, {
        var in0 = SoundIn.ar(0) * 15;
        var in1 = SoundIn.ar(1) * 15;

        var a0 = In.kr(~a0);  var a1 = In.kr(~a1);
        var a2 = In.kr(~a2);  var a3 = In.kr(~a3);
        var but12 = In.kr(~d6);
        var but13 = In.kr(~d1);

        var comb1 = CombC.ar(in0, 0.2, a0.exprange(0.9, 0.0005), 4);
        var comb3 = CombC.ar(in1, 0.2, a2.exprange(0.9, 0.0005), 4);
        var snoise = PinkNoise.ar(5).range(0.05, 0.1);
        var rightm  = RLPF.ar(comb1 * but12, a1.exprange(1.0, 4000.0), 0.1);
        var leftm = RLPF.ar(comb3 * but13, a3.exprange(1.0, 4000.0), 0.1);
        var left   = leftm + snoise;
        var right  = rightm + snoise;
        Out.ar(0, [leftm.tanh, rightm.tanh]);
        Out.ar(~analogBus, [right.tanh, left.tanh]);
    }).add;

    SynthDef(\RingzAnalog, {
        var inR = SoundIn.ar(0) * 20;
        var inL = SoundIn.ar(1) * 20;
        var a0 = In.kr(~a0), a1 = In.kr(~a1), a2 = In.kr(~a2), a3 = In.kr(~a3);
        var but12 = In.kr(~d6), but13 = In.kr(~d1);
        var freqR = a1.exprange(300, 1),  freqL = a3.exprange(300, 1);
        var ringFreqR = a0.exprange(1, 900), ringFreqL = a2.exprange(1, 1000);
        var decayL = a0.exprange(10, 1), decayR = a2.exprange(10, 1);
        var impL = Impulse.ar(freqL, 0, 1) * inL;
        var impR = Impulse.ar(freqR, 0, 1) * inR;
        var leftm  = Ringz.ar(impL, ringFreqL, decayL, 5) * but13;
        var rightm = Ringz.ar(impR, ringFreqR, decayR, 5) * but12;
		var snoise = PinkNoise.ar(5).range(0.05, 0.1);
        Out.ar(0, [leftm.tanh, rightm.tanh]);
        Out.ar(~analogBus, [(rightm*3+snoise), (leftm*3+snoise)]);
    }).add;

  SynthDef(\WrapSummerRingModAnalog, {
        var rmR = SoundIn.ar(0);
        var rmL = SoundIn.ar(1);
        var a0 = In.kr(~a0), a1 = In.kr(~a1), a2 = In.kr(~a2), a3 = In.kr(~a3);
        var but12 = In.kr(~d6), but13 = In.kr(~d1);
        var baseTrigR = a1.range(0.0001, 10);
        var baseTrigL = a3.range(0.0001, 10);
        var freqL = LFNoise0.kr(baseTrigL, 1).range(0.001, 2.0) * a2.range(10.0, 5000.0);
        var freqR = LFNoise0.kr(baseTrigR, 1).range(0.001, 2.0) * a0.range(10.0, 5000.0);
        var dryL = LFSaw.ar(freqL, 0, 3);
        var dryR = LFSaw.ar(freqR, 0, 3);
        var leftm  = RLPF.ar(dryL, a3.linlin(0.0,1.0,150.0,900.0), 0.3, 1.4) * but13;
        var rightm = RLPF.ar(dryR, a1.linlin(0.0,1.0,150.0,900.0), 0.3, 1.4) * but12;
        Out.ar(0, [leftm.tanh, rightm.tanh]);
        Out.ar(~analogBus, [rightm.tanh, leftm.tanh]);
    }).add;

    SynthDef(\GaussTrigAnalog, { |out = 0|
        var in1 = (SoundIn.ar(0) * 10).tanh;
        var in0 = (SoundIn.ar(1) * 10).tanh;
        var a0 = In.kr(~a0), a1 = In.kr(~a1), a2 = In.kr(~a2), a3 = In.kr(~a3);
        var but12 = In.kr(~d6), but13 = In.kr(~d1);
        var rateL = a2.range(0.01, 60),  rateR = a0.range(0.01, 60);
        var decayL = a3.exprange(0.001, 1.0), decayR = a1.exprange(0.001, 1.0);
        var centerL = a2.exprange(10, 3000), centerR = a0.exprange(10, 3000);
        var trigL = GaussTrig.kr(rateL, 0, 0.5);
        var envL  = Decay.kr(trigL, decayL, 1);
        var srcL  = BrownNoise.ar(envL) * in0;
        var leftm = Ringz.ar(srcL, centerL, 0.02) * but13;
        var trigR = GaussTrig.kr(rateR, 0, 0.5);
        var envR  = Decay.kr(trigR, decayR, 1);
        var srcR  = BrownNoise.ar(envR) * in1;
        var rightm = Ringz.ar(srcR, centerR, 0.02) * but12;
		var snoise = PinkNoise.ar(5).range(0.005, 0.05);
        Out.ar(out, [RLPF.ar(leftm,1000).tanh, RLPF.ar(rightm,1000).tanh]);
        Out.ar(~analogBus, [(rightm+snoise), (leftm+snoise)]);
    }).add;

    SynthDef(\GendyResCombAnalog, {
        var in0 = SoundIn.ar(0);
        var in1 = SoundIn.ar(1);
        var a0 = In.kr(~a0), a1 = In.kr(~a1), a2 = In.kr(~a2), a3 = In.kr(~a3);
        var but12 = In.kr(~d6), but13 = In.kr(~d1);
        var maxFreqR = a0.exprange(10, 3000);
        var maxFreqL = a2.exprange(10, 3000);
        var resFreqR = a1.exprange(50, 6000);
        var resFreqL = a3.exprange(50, 6000);
        var gendyL = Gendy1.ar(2, 3, minfreq: 1, maxfreq: maxFreqL, durscale: 0.1, initCPs: 10);
        var resL   = Resonz.ar(gendyL, resFreqL, 0.1);
        var combL  = CombN.ar(resL + in1, 0.1, 0.1, 5, 2);
        var leftm  = combL * but13;
        var gendyR = Gendy1.ar(2, 3, minfreq: 1, maxfreq: maxFreqR, durscale: 0.1, initCPs: 10);
        var resR   = Resonz.ar(gendyR, resFreqR, 0.1);
        var combR  = CombN.ar(resR + in0, 0.1, 0.1, 5, 2);
        var rightm = combR * but12;
        Out.ar(0, [leftm.tanh, rightm.tanh]);
        Out.ar(~analogBus, [rightm.tanh, leftm.tanh]);
    }).add;

    SynthDef(\analogMaster, {
        var sum = In.ar(~analogBus, 2) + In.ar(~fxBus, 2);
        var but12 = In.kr(~d6);
        var but13 = In.kr(~d1);
        sum = sum;
        sum = sum.abs;
        sum = sum.linlin(0.001, 1.0, 0.40, 1.0);
        Out.ar(8, sum[0] * but12);
        Out.ar(6, sum[1] * but13);
    }).add;

    SynthDef(\combdel, { |out=0, delt=0.01, gate=1, att=0.005, rel=0.03|
        var in  = SoundIn.ar(0) + SoundIn.ar(1);
        var sig = CombC.ar(in.tanh, 0.9, delt, 5, 0.6);
        var env = EnvGen.kr(Env.asr(att, 1, rel), gate, doneAction: 2);
        sig = sig * env;
        Out.ar(out, LPF.ar((sig!2),3000).tanh);
        Out.ar(~fxBus, sig!2);
    }).add;

SynthDef(\magFreeze, { |out=0, freeze=0, amp=1, gate=1, att=0.005, rel=0.03|
    var in = SoundIn.ar(0) + SoundIn.ar(1);
    var chain = FFT(LocalBuf(1024), in);
    var sig, env;
    chain = PV_Freeze(chain, freeze);
    sig = IFFT(chain).dup * amp;
    env = EnvGen.kr(Env.asr(att, 1, rel), gate, doneAction: 2);
    sig = sig * env * freeze;
    Out.ar(out, sig!2); Out.ar(~fxBus, sig!2);
}).add;

    SynthDef(\stutterBuf, { |out=0, bufnum=0,
        wet=1, wetLag=0.12,
        tresh=0.4, durrand=0.9, maxdel=500.0, xfade=0.03, postLPF=3000|
        var snd = SoundIn.ar(0) + SoundIn.ar(1);
        var reset, phase, phmod, phmodPrev, fragment, fragmentTrig;
        var delNew, delOld;
        var pos, sigNew, sigOld, xf, sig, env;
        reset = Onsets.kr(FFT(LocalBuf(512), snd), tresh);
        phase = Sweep.kr(reset).clip(0, maxdel);
        phmod     = (phase / durrand.max(0.0001)) % 1;
        phmodPrev = Delay1.kr(phmod);
        fragment     = (phmod - phmodPrev) < 0;
        fragmentTrig = Trig1.kr(fragment, 0.001);
        delNew = Latch.kr(phase, fragmentTrig).clip(0, maxdel);
        delOld = Delay1.kr(delNew);
        pos = DelTapWr.ar(bufnum, snd);
        sigNew = DelTapRd.ar(bufnum, pos, delNew);
        sigOld = DelTapRd.ar(bufnum, pos, delOld);
        xf  = EnvGen.ar(Env([0, 1], [xfade.max(0.0001)], \lin), fragmentTrig);
        sig = SelectX.ar(xf, [sigOld, sigNew]);
        sig = LeakDC.ar(sig);
        sig = LPF.ar(sig, postLPF);
        env = Lag.kr(wet.clip(0, 1), wetLag);
		sig = (sig * env).tanh ! 2;
		Out.ar(out, sig * (wet > 0));
		Out.ar(~fxBus, sig * (wet > 0));
    }).add;

    ~buf = Buffer.alloc(s, s.sampleRate * 0.6, 1);

    SynthDef(\multiDelay, { |out=0, bufnum=0, gate=1, att=0.01, rel=0.03|
        var in = SoundIn.ar(0) + SoundIn.ar(1);
        var pos, snd, tap1, tap2, env;
        snd = LocalIn.ar(1);
        pos = DelTapWr.ar(bufnum, snd);
        tap1 = DelTapRd.ar(bufnum, pos,
            { rrand(0.05, 0.2) + (LFNoise2.kr(rrand(0.5, 1.5)) * 0.005) } ! 14
        ).sum * 0.3;
        snd = in.tanh + tap1;
        snd = (snd + 0.1).tanh;
        snd = LeakDC.ar(snd);
        LocalOut.ar(snd);
        tap2 = Splay.ar(DelTapRd.ar(bufnum, pos, { rrand(0.05, 0.2) } ! 20));
        snd = (tap2 + FreeVerb.ar(tap2, 0.8, 0.5, 0.3));
        snd = (snd * 1.5).tanh;
        snd = snd ! 2;
        env = EnvGen.kr(Env.asr(att, 1, rel), gate, doneAction: 2);
        snd = snd * env;
        Out.ar(out, RLPF.ar(((snd!2)),1400).tanh); Out.ar(~fxBus, snd!2);
    }).add;

    ~bufDur = 1.0;
    ~buf2 = Buffer.alloc(s, s.sampleRate * ~bufDur, 1);
    ~buf3 = Buffer.alloc(s, s.sampleRate * ~bufDur, 1);

    SynthDef(\ringrec,  { |bufnum, run=1| RecordBuf.ar(SoundIn.ar(0)+SoundIn.ar(1), bufnum, loop: 1, run: run); }).add;
    SynthDef(\ringrec2, { |bufnum, run=1| RecordBuf.ar(SoundIn.ar(0)+SoundIn.ar(1), bufnum, loop: 1, run: run); }).add;

    SynthDef(\randSegmentLoop, { |bufnum, startPos=0, endPos=1, amp=1.5, rate=1|
        var segStart = startPos * BufSampleRate.ir(bufnum);
        var segEnd   = endPos   * BufSampleRate.ir(bufnum);
        var phasor = Phasor.ar(rate: rate, start: segStart, end: segEnd, resetPos: segStart);
        var sig = BufRd.ar(1, bufnum, phasor, loop: 1) * amp;
        Out.ar(0, sig.tanh!2); Out.ar(~fxBus, sig.tanh!2);
    }).add;

    SynthDef(\randSegmentLoop2, { |bufnum, startPos=0, endPos=1, amp=1.5, rate=1|
        var segStart = startPos * BufSampleRate.ir(bufnum);
        var segEnd   = endPos   * BufSampleRate.ir(bufnum);
        var phasor = Phasor.ar(rate: rate, start: segStart, end: segEnd, resetPos: segStart);
        var sig = BufRd.ar(1, bufnum, phasor, loop: 1) * amp;
        Out.ar(0, sig.tanh!2); Out.ar(~fxBus, sig.tanh!2);
    }).add;

    SynthDef(\magMul, { |out=0, freq2=220, amp=2|
        var inA = SoundIn.ar(0) + SoundIn.ar(1);
        var inB = LFSaw.ar(freq2, 0, 0.5);
        var chainA = FFT(LocalBuf(512), inA);
        var chainB = FFT(LocalBuf(512), inB);
        var sig = amp * IFFT(PV_MagMul(chainA, chainB));
        Out.ar(out, sig.tanh!2); Out.ar(~fxBus, sig.tanh!2);
    }).add;

    SynthDef(\waveLoss, { |out=0, time=40|
        var sig = SoundIn.ar(0) + SoundIn.ar(1);
        sig = WaveLoss.ar(sig, time, 40, 1, mul: 10);
        Out.ar(out, sig.tanh!2); Out.ar(~fxBus, sig.tanh!2);
    }).add;

    SynthDef(\randomN, { |csc=2|
        var snd, n=8;
        snd = SoundIn.ar(0) + SoundIn.ar(1);
        snd = Integrator.ar(snd, 0.99);
        snd = snd * ({ { Rand(-1, 1) * 1000 } ! n+csc } ! 2);
        snd = snd.sum;
        snd = LeakDC.ar(snd).clip2(1);
        Out.ar(0, (snd[0,1]*0.2).tanh); Out.ar(~fxBus, (snd[0,1]*0.2).tanh);
    }).add;

    SynthDef(\grey, { |out=0, revtime=1, damping=0.6, gate=1, att=0.005, rel=0.03|
        var in0 = SoundIn.ar(0);
        var in1 = SoundIn.ar(1);
        var sig = FreeVerb2.ar(in0, in1, 1, revtime, damping, 6).tanh;
        sig = ((sig*2));
        Out.ar(out, sig.tanh); Out.ar(~fxBus, sig);
    }).add;

    s.sync;

    ~freezeSynth   = Synth(\magFreeze, [\freeze, 0]);
    ~recSynth      = Synth(\ringrec,  [\bufnum, ~buf2]);
    ~recSynth2     = Synth(\ringrec2, [\bufnum, ~buf3]);
    ~playSynth     = nil;
    ~playSynth2    = nil;
    ~stutMax  = 50.0;
    ~stutBuf1 = Buffer.alloc(s, (s.sampleRate * (~stutMax + 0.1)).asInteger, 1);
    ~stutterSynth = Synth(\stutterBuf, [
        \bufnum, ~stutBuf1.bufnum, \maxdel, ~stutMax, \wet, 0
    ]);
    ~stutter_lastVal = 0;
    ~masterSynth   = Synth.tail(s, \analogMaster);
    ~playRandSegment = { |start, end, rate=1|
        if(~playSynth.notNil) { ~playSynth.free; ~playSynth = nil; };
        ~recSynth.set(\run, 0);
        ~playSynth = Synth(\randSegmentLoop, [\bufnum, ~buf2, \startPos, start, \endPos, end, \rate, rate]);
    };
    ~stopRandSegment = {
        if(~playSynth.notNil) { ~playSynth.free; ~playSynth = nil; ~recSynth.set(\run, 1); };
    };

    ~playRandSegment2 = { |start, end, rate=1|
        if(~playSynth2.notNil) { ~playSynth2.free; ~playSynth2 = nil; };
        ~recSynth2.set(\run, 0);
        ~playSynth2 = Synth(\randSegmentLoop2, [\bufnum, ~buf3, \startPos, start, \endPos, end, \rate, rate]);
    };
    ~stopRandSegment2 = {
        if(~playSynth2.notNil) { ~playSynth2.free; ~playSynth2 = nil; ~recSynth2.set(\run, 1); };
    };

    SynthDef(\buttonWatcher, {
        var ids = [4,5,2,15,3,0,11,12,14,7];
        var bs  = ids.collect { |i| DigitalIn.kr(i) };
        var dz  = bs.collect { |b| HPZ1.kr(b) };
        var rise = dz.collect { |d| Trig1.kr((d > 0), 0.002) };
        var fall = dz.collect { |d| Trig1.kr((d < 0), 0.002) };
        var bases = [100,110,120,130,140,190,160,150,170,180];
        (0..(ids.size-1)).do { |i|
            SendTrig.kr(rise[i], bases[i]+0, 1);
            SendTrig.kr(fall[i], bases[i]+1, 0);
        };
    }).add;

    SynthDef(\switchWatcher, {
        var up    = DigitalIn.kr(1);
        var down  = DigitalIn.kr(8);
        var upR   = Trig1.kr(HPZ1.kr(up)   > 0, 0.002);
        var downR = Trig1.kr(HPZ1.kr(down) > 0, 0.002);
        SendTrig.kr(upR,   200, 1);
        SendTrig.kr(downR, 201, 1);
    }).add;

    s.sync;
    ~watcher     = Synth(\buttonWatcher);
    ~switchWatch = Synth(\switchWatcher);
    ~combdelSynth    = nil;
    ~multiDelaySynth = nil;
    ~magMulSynth     = nil;
    ~waveLossSynth   = nil;
    ~greySynth       = nil;
    ~randomNSynth    = nil;
    ~fxMutex = nil;

    OSCdef(\belaButtons, { |msg|
        var trigID = msg[2].asInteger;
        switch(trigID,
            100, { if(~combdelSynth.isNil)  { ~combdelSynth  = Synth(\combdel, [\delt, exprand(0.009, 0.09)]); } },
            101, { if(~combdelSynth.notNil) { ~combdelSynth.free; ~combdelSynth = nil; } },
            110, { ~freezeSynth.set(\freeze, 1) },
            111, { ~freezeSynth.set(\freeze, 0) },
            120, {
                var minSeg = 0.01, maxSeg = 0.2, segLen = rrand(minSeg, maxSeg);
                var start = rrand(0, ~bufDur - segLen);
                var end = start + segLen;
                ~playRandSegment.(start, end, 1);
            },
            121, { ~stopRandSegment.() },
            130, {
                var minSeg = 0.01, maxSeg = 0.6, segLen = rrand(minSeg, maxSeg);
                var end = rrand(0, ~bufDur - segLen);
                var start = end + segLen;
                ~playRandSegment2.(start, end, -1);
            },
            131, { ~stopRandSegment2.() },
            140, {
                if(~fxMutex.isNil or: { ~fxMutex == \randomN }) {
                    if(~randomNSynth.isNil) {
                        ~randomNSynth = Synth(\randomN, [\csc, rrand(1, 15)]);
                        ~fxMutex = \randomN;
                        "[FX] randomN ON".postln;
                    };
                }{
                    "[FX] BLOCKED: multiDelay active.".postln;
                };
            },
            141, {
                if(~randomNSynth.notNil) {
                    ~randomNSynth.free; ~randomNSynth = nil;
                    "[FX] randomN OFF".postln;
                };
                if(~fxMutex == \randomN) { ~fxMutex = nil; };
            },

            150, { if(~greySynth.isNil)  { ~greySynth  = Synth(\grey, [\revtime, rrand(0.7, 1.0)]); } },
            151, { if(~greySynth.notNil) { ~greySynth.free; ~greySynth = nil; } },
            160, { ~stutterSynth.set(\wet, 1, \tresh, 0.4, \durrand, exprand(0.09, 0.3)); },
            161, { ~stutterSynth.set(\wet, 0); },
            170, {
                if(~fxMutex.isNil or: { ~fxMutex == \multiDelay }) {
                    if(~multiDelaySynth.isNil) {
                        ~multiDelaySynth = Synth(\multiDelay, [\bufnum, ~buf.bufnum]);
                        ~fxMutex = \multiDelay;
                        "[FX] multiDelay ON".postln;
                    };
                }{
                    "[FX] BLOCKED: randomN active.".postln;
                };
            },
            171, {
                if(~multiDelaySynth.notNil) {
                    ~multiDelaySynth.free; ~multiDelaySynth = nil;
                    "[FX] multiDelay OFF".postln;
                };
                if(~fxMutex == \multiDelay) { ~fxMutex = nil; };
            },
            180, { if(~magMulSynth.isNil)  { ~magMulSynth  = Synth(\magMul, [\freq2, exprand(5, 310)]); } },
            181, { if(~magMulSynth.notNil) { ~magMulSynth.free; ~magMulSynth = nil; } },
            190, { if(~waveLossSynth.isNil)  { ~waveLossSynth  = Synth(\waveLoss, [\time, rrand(15.0, 40.0)]); } },
            191, { if(~waveLossSynth.notNil) { ~waveLossSynth.free; ~waveLossSynth = nil; } },
        );
    }, '/tr');
    ~voiceOrder = [\analogPatch, \RingzAnalog, \WrapSummerRingModAnalog, \GendyResCombAnalog,\GaussTrigAnalog];
    ~voiceIndex = 0;
    ~voiceSynth = nil;
    ~startVoice = { |idx|
        var i = idx.clip(0, ~voiceOrder.size - 1);
        if(~voiceSynth.notNil) { ~voiceSynth.free; ~voiceSynth = nil; };
        ~voiceSynth = Synth(~voiceOrder[i]);
        ("[VOICE] -> " ++ ~voiceOrder[i].asString).postln;
    };
    OSCdef(\voiceSwitch, { |msg|
        var trigID = msg[2].asInteger;
        if(trigID == 200, {
            ~voiceIndex = ((~voiceIndex + 1) % ~voiceOrder.size);
            ~startVoice.(~voiceIndex);
        });
        if(trigID == 201, {
            ~voiceIndex = ((~voiceIndex - 1) % ~voiceOrder.size);
            if(~voiceIndex < 0) { ~voiceIndex = ~voiceOrder.size + ~voiceIndex; };
            ~startVoice.(~voiceIndex);
        });
    }, '/tr');
});

ServerQuit.add({ 0.exit });