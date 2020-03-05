using Alsa;

namespace Strings.Audio.Alsa {

     public class Device : Object, Audio.Device {
        public int frame_size { get; set; }
        public int sample_rate { get; set; }
        public int channels { get; set; }
        public string name { get; set; }

        protected PcmDevice device;
        protected PcmHardwareParams hw_params;
        protected PcmFormat format;

        public Device () {
            name = "default";
            sample_rate = 44100;
            channels = 2;
            frame_size = 1 << 12;
            format = PcmFormat.S16_LE;
        }

        public void init () throws DeviceError {
            int err;
            if ((err = PcmDevice.open (out device, name, PcmStream.CAPTURE)) < 0) {
                var msg = "ALSA Error (%d) - Cannot open audio device %s (%s).".printf (
                    err, name, global::Alsa.strerror (err));
                throw new DeviceError.INIT_FAIL (msg);
            }

            if ((err = PcmHardwareParams.malloc (out hw_params)) < 0) {
                var msg = "ALSA Error (%d) - Cannot allocate hardware parameter structure (%s)"
                    .printf (err, global::Alsa.strerror (err));
                throw new DeviceError.INIT_FAIL (msg);
            }

            if ((err = device.hw_params_any (hw_params)) < 0) {
                var msg = "ALSA Error (%d) - Cannot prepare audio interface for use (%s)".printf (
                    err, global::Alsa.strerror (err));
                throw new DeviceError.INIT_FAIL (msg);
            }

            if ((err = device.hw_params_set_access (hw_params, PcmAccess.RW_INTERLEAVED)) < 0) {
                var msg = "ALSA Error (%d) - Cannot set access type (%s)".printf (
                    err, global::Alsa.strerror (err));
                throw new DeviceError.INIT_FAIL (msg);
            }

            if ((err = device.hw_params_set_format (hw_params, format)) < 0) {
                var msg = "ALSA Error (%d) - Cannot set sample format (%s)".printf (
                    err, global::Alsa.strerror (err));
                throw new DeviceError.INIT_FAIL (msg);
            }

            //HACK: This works for some evil reason but it's not how it should work.
            int rate = sample_rate / 2;
            if ((err = device.hw_params_set_rate_near (hw_params, ref rate, 0)) < 0) {
                var msg = "ALSA Error (%d) - Cannot set sample rate (%s)".printf (
                    err, global::Alsa.strerror (err));
                throw new DeviceError.INIT_FAIL (msg);
            }

            if ((err = device.hw_params_set_channels (hw_params, channels)) < 0) {
                var msg = "ALSA Error (%d) - Cannot set channel count (%s)".printf (
                    err, global::Alsa.strerror (err));
                throw new DeviceError.INIT_FAIL (msg);
            }

            if ((err = device.hw_params (hw_params)) < 0) {
                var msg = "ALSA Error (%d) - Cannot set parameters (%s)".printf (
                    err, global::Alsa.strerror (err));
                throw new DeviceError.INIT_FAIL (msg);
            }
        }

        public void play (Sample[] buffer) throws DeviceError {
            stdout.printf("Not implemented yet!");
        }

        public void record (Sample[] buffer) throws DeviceError {
            stdout.printf ("Recording from ALSA device %s.\n", name);
            stdout.printf ("Sample type: Signed 16-bit little endian\n");
            stdout.printf ("Sample rate: %d\n", sample_rate);
            stdout.printf ("Channels: %d\n", channels);
            int err;
            if ((err = device.prepare ()) < 0) {
                var msg = "ALSA Error (%d) - Cannot prepare audio interface for use (%s)".printf (
                    err, global::Alsa.strerror (err));
                throw new DeviceError.INIT_FAIL (msg);
            }
            var frame_width = channels * frame_size;
            var frames_whole = buffer.length / frame_width;
            var frames_end = frames_whole * frame_width;
            unowned uint8[] frame;
            for (var i = 0; i < frames_whole; i++) {
                frame = (uint8[]) buffer[(i * frame_width) : (i + 1) * frame_width];
                if ((err = (int) device.readi (frame, frame_size)) != frame_size) {
                    var msg = "ALSA Error (%d) - Read from audio interface failed (%s)".printf (
                        err, global::Alsa.strerror (err));
                    throw new DeviceError.RECORD_FAIL (msg);
                }
            }
            if (frames_end == buffer.length) { return; }
            frame = (uint8[]) buffer[frames_end : buffer.length];
            var rest_size = frame.length / (channels * sizeof (Sample));
            if ((err = (int) device.readi (frame, rest_size)) != rest_size) {
                var msg = "ALSA Error (%d) - Read from audio interface failed (%s)".printf (
                    err, global::Alsa.strerror (err));
                throw new DeviceError.RECORD_FAIL (msg);
            }
        }

        public void close () {
            device.close ();
        }
    }

    /* Adapted from
    * https://raw.githubusercontent.com/robelsharma/IdeaAudio/v1.0/IdeaLib/AudioAlsa.cpp */
    public string[] get_device_names () {
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

    [CCode (cheader_filename="alsa/asoundlib.h", cname="snd_card_next")]
    private extern int snd_card_next (int *rcard);

    [CCode (cheader_filename="alsa/asoundlib.h", cname="snd_ctl_pcm_next_device")]
    private extern int snd_ctl_pcm_next_device (Card card, int *device);

    [CCode (cheader_filename="alsa/asoundlib.h", cname="snd_ctl_pcm_info")]
    private extern int snd_ctl_pcm_info (Card card, PcmInfo info);
}