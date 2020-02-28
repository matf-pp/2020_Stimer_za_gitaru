using Alsa;

namespace Strings.Audio {
    public const uint CAPTURE_RATE = 44100;

    public errordomain RecordError {
        UNKNOWN_DEVICE_NAME,
        HW_PARAM_ALLOC_FAIL,
        SET_HW_PARAM_ACC_FAIL,
        SET_SAMPLE_RATE_FAIL,
        SET_HW_PARAMS_FAIL,
        PCM_PREPARE_FAIL
    }

    // Adapted from https://raw.githubusercontent.com/robelsharma/IdeaAudio/v1.0/IdeaLib/AudioAlsa.cpp
    public string[] get_pcm_device_names () {
        CardInfo card_info;
        PcmInfo pcm_info;
        CardInfo.alloc (out card_info);
        PcmInfo.malloc (out pcm_info);
        Array<string> names = new Array<string> ();
        int card_no = -1;
        while (snd_card_next (&card_no) >= 0 && card_no >= 0) {
            Posix.printf ("Card: %d\n", card_no);
            int err = 0;
            Card card;
            if ((err = Card.open (out card, "hw:%d".printf(card_no))) < 0) {
                continue;
            }
            if ((err = card.card_info (card_info)) < 0) {
                continue;
            }
            int dev = -1;
            while (snd_ctl_pcm_next_device(card, &dev) >= 0 && dev >= 0) {
                pcm_info.set_device (dev);
                pcm_info.set_subdevice (0);
                pcm_info.set_stream (PcmStream.CAPTURE);
                if ((err = snd_ctl_pcm_info(card, pcm_info)) < 0) {
                    continue;
                }
                names.append_val("plughw:%d,%d".printf (card_no, dev));
            }
        }
        if (names.length == 1) { return new string[] { "default" }; }
        return names.data;
    }

    public void record_from_device (string device_id, ref int[] buffer) throws RecordError {
        var buff_sz = buffer.length;
        assert (buff_sz != 0 && (buff_sz & (buff_sz - 1)) == 0);
        PcmDevice handle;
        PcmHardwareParams hw_params;
        PcmFormat format = PcmFormat.S16_LE;
        int err;
        if ((err = PcmDevice.open (out handle, device_id, PcmStream.CAPTURE)) < 0) {
            var msg = "cannot open audio device %s (%s)".printf (device_id, Alsa.strerror (err));
            throw new RecordError.UNKNOWN_DEVICE_NAME (msg);
        }

        if ((err = PcmHardwareParams.malloc (out hw_params)) < 0) {
            var msg = "cannot allocate hardware parameter structure (%s)".printf (Alsa.strerror (err));
            throw new RecordError.HW_PARAM_ALLOC_FAIL (msg);
        }

        if (handle.hw_params_set_access (hw_params, PcmAccess.RW_INTERLEAVED) < 0) {
            var msg = "cannot set access type (%s)".printf (Alsa.strerror (err));
            throw new RecordError.SET_HW_PARAM_ACC_FAIL (msg);
        }

        int capture_rate = (int) CAPTURE_RATE;
        if ((err = handle.hw_params_set_rate_near (hw_params, ref capture_rate, 0)) < 0) {
            var msg = "cannot set sample rate (%s)".printf (Alsa.strerror (err));
            throw new RecordError.SET_SAMPLE_RATE_FAIL (msg);
        }

        if ((err = handle.hw_params (hw_params)) < 0) {
            var msg = "cannot prepare audio interface for use (%s)".printf (Alsa.strerror (err));
            throw new RecordError.PCM_PREPARE_FAIL (msg);
        }

        // TODO: Implement properly later
    }

    [CCode (cheader_filename="alsa/asoundlib.h", cname="snd_card_next")]
    public extern int snd_card_next (int *rcard);

    [CCode (cheader_filename="alsa/asoundlib.h", cname="snd_ctl_pcm_next_device")]
    public extern int snd_ctl_pcm_next_device (Card card, int *device);

    [CCode (cheader_filename="alsa/asoundlib.h", cname="snd_ctl_pcm_info")]
    public extern int snd_ctl_pcm_info (Card card, PcmInfo info);

    public void fft (ref Complex[] buff) {
        var length = buff.length;
        assert (length != 0 && (length & (length - 1)) == 0);

        for (var i = 1, j = 0; i < length; i++) {
            var bit = length >> 1;
            for (; j >= bit; bit >>= 1) { j -= bit; }
            j += bit;
            if (i < j) {
                Complex.swap (ref buff[i], ref buff[j]);
            }
        }

        for (var k = 2; k <= length; k <<= 1) {
            double angle = 2.0 * Math.PI / -k;
            Complex w_n = Complex (Math.cos (angle), Math.sin (angle));
            for (var i = 0; i < length; i += k) {
                Complex w = { 1.0, 0.0 };
                for (var j = 0; j < k / 2; j++) {
                    Complex t = buff[i + j + k / 2].multiply (w);
                    buff[i + j + k / 2] = buff[i + j].subtract (t);
                    buff[i + j] = buff[i + j].add (t);
                    w = w.multiply (w_n);
                }
            }
        }
    }
}