using Alsa;

namespace Strings.Audio {
     public class AlsaDevice : Object, Device {
        public string name { get; set; }
        public uint8 channels { get; set; }
        public uint buffer_frames { get; set; }

        public int sample_rate;

        protected PcmDevice device;
        protected PcmHardwareParams hw_params;
        protected PcmFormat format;

        public AlsaDevice () {
            name = "default";
            sample_rate = 44100;
            channels = 2;
            buffer_frames = 1 << 16;
            format = PcmFormat.S16_LE;
        }

        public void init () throws DeviceError {
            int err;
            if ((err = PcmDevice.open (out device, name, PcmStream.CAPTURE)) < 0) {
                var msg = "ALSA Error (%d) - Cannot open audio device %s (%s).".printf (
                    err, name, Alsa.strerror (err));
                throw new DeviceError.INIT_FAIL (msg);
            }

            if ((err = PcmHardwareParams.malloc (out hw_params)) < 0) {
                var msg = "ALSA Error (%d) - Cannot allocate hardware parameter structure (%s)".printf (
                    err, Alsa.strerror (err));
                throw new DeviceError.INIT_FAIL (msg);
            }

            if ((err = device.hw_params_any (hw_params)) < 0) {
                var msg = "ALSA Error (%d) - Cannot prepare audio interface for use (%s)".printf (
                    err, Alsa.strerror (err));
                throw new DeviceError.INIT_FAIL (msg);
            }

            if ((err = device.hw_params_set_access (hw_params, PcmAccess.RW_INTERLEAVED)) < 0) {
                var msg = "ALSA Error (%d) - Cannot set access type (%s)".printf (
                    err, Alsa.strerror (err));
                throw new DeviceError.INIT_FAIL (msg);
            }

            if ((err = device.hw_params_set_format (hw_params, format)) < 0) {
                var msg = "ALSA Error (%d) - Cannot set sample format (%s)".printf (
                    err, Alsa.strerror (err));
                throw new DeviceError.INIT_FAIL (msg);
            }

            if ((err = device.hw_params_set_rate_near (hw_params, ref sample_rate, 0)) < 0) {
                var msg = "ALSA Error (%d) - Cannot set sample rate (%s)".printf (
                    err, Alsa.strerror (err));
                throw new DeviceError.INIT_FAIL (msg);
            }

            if ((err = device.hw_params_set_channels (hw_params, channels)) < 0) {
                var msg = "ALSA Error (%d) - Cannot set channel count (%s)".printf (
                    err, Alsa.strerror (err));
                throw new DeviceError.INIT_FAIL (msg);
            }

            if ((err = device.hw_params_set_period_size (hw_params, buffer_frames * 2, 0)) < 0) {
                var msg = "ALSA Error (%d) - Cannot set channel count (%s)".printf (
                    err, Alsa.strerror (err));
                throw new DeviceError.INIT_FAIL (msg);
            }

            if ((err = device.hw_params (hw_params)) < 0) {
                var msg = "ALSA Error (%d) - Cannot set parameters (%s)".printf (
                    err, Alsa.strerror (err));
                throw new DeviceError.INIT_FAIL (msg);
            }
        }

        public void play (Sample[] buffer, uint sample_rate = 44100) {
            stdout.printf("Not implemented yet!");
        }

        public void record (Sample[] buffer) throws DeviceError {
            int err;
            if ((err = device.prepare ()) < 0) {
                var msg = "ALSA Error (%d) - Cannot prepare audio interface for use (%s)".printf (
                    err, Alsa.strerror (err));
                throw new DeviceError.INIT_FAIL (msg);
            }
            var frame_width = buffer_frames * sizeof (Sample) * 2;
            uint8[] frame = new uint8[frame_width];
            var seconds = 3;
            // Basic sound recording. Ignores buffer for now. Writes 3s recording to a file
            var file = Posix.FILE.open ("test.txt", "w");
            for (var i = 0; i < (seconds * sample_rate) / buffer_frames; i++) {
                if ((err = (int) device.readi (frame, buffer_frames)) != buffer_frames) {
                    var msg = "ALSA Error (%d) - Read from audio interface failed (%s)".printf (
                        err, Alsa.strerror (err));
                    throw new DeviceError.RECORD_FAIL (msg);
                }
                var samples = (Sample *) frame;
                for (var j = 0; j < buffer_frames; j++) {
                    file.printf("%d ", samples[j]);
                }
            }
        }

        public void close () {
            device.close ();
        }

        // Adapted from https://raw.githubusercontent.com/robelsharma/IdeaAudio/v1.0/IdeaLib/AudioAlsa.cpp
        public static string[] get_device_names () {
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
        protected static extern int snd_card_next (int *rcard);

        [CCode (cheader_filename="alsa/asoundlib.h", cname="snd_ctl_pcm_next_device")]
        protected static extern int snd_ctl_pcm_next_device (Card card, int *device);

        [CCode (cheader_filename="alsa/asoundlib.h", cname="snd_ctl_pcm_info")]
        protected static extern int snd_ctl_pcm_info (Card card, PcmInfo info);
    }
}