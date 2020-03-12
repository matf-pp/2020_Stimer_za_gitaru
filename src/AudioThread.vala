namespace Strings.Audio {
    public class AudioThread {
        protected Device device;
        protected bool running;
        protected Thread<bool> thread;

        public signal void tone_recognized (double frequency);

        public AudioThread.from_device (Device device) {
            this.device = device;
            thread = new Thread<bool> ("audio-thread", start);
        }

        protected bool start () {
            running = true;
            var buffer = new Sample[floor_power_two (3 * device.sample_rate)];
            try {
                device.init ();
                while (running) {
                    device.record (buffer);
                    recognize_tone (buffer);
                }
            } catch (DeviceError devErr) {
                stderr.printf ("%s\n", devErr.message);
            } finally {
                running = false;
                device.close ();
            }
            return true;
        }

        // TODO: Optimize this
        private int floor_power_two (int n) {
            if (n != 0 && (n & (n - 1)) == 0) { return n; }
            return (int) Math.pow (2, Math.floor (Math.log (n) / Math.log (2)));
        }

        protected void recognize_tone (Sample[] buffer) {
            var @signal = new Complex[buffer.length];
            for (var i = 0; i < @signal.length; i++) {
                @signal[i].real = buffer[i];
            }
            fft (@signal);
            var max_idx = Complex.argmax (@signal[1 : @signal.length / 2 + 1]);
            var freq = (double) max_idx / @signal.length * device.sample_rate;
            tone_recognized (freq);
        }

        public void stop () {
            info ("Stopping audio thread!");
            running = false;
        }
    }
}
